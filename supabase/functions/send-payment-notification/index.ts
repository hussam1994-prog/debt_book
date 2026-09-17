// supabase/functions/send-payment-notification/index.ts
import { serve } from 'https://deno.land/std@0.208.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { SignJWT, importPKCS8 } from 'https://deno.land/x/jose@v5.2.2/index.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// ✅ Firebase Service Account من Supabase Secret
const serviceAccount = JSON.parse(
  Deno.env.get('FIREBASE_SERVICE_ACCOUNT') ?? '{}'
)

let cachedToken: { token: string; expiresAt: number } | null = null

// ✅ الحصول على OAuth2 access token من Google
async function getAccessToken(): Promise<string> {
  if (cachedToken && cachedToken.expiresAt > Date.now() + 60000) {
    return cachedToken.token
  }

  if (!serviceAccount.private_key || !serviceAccount.client_email) {
    throw new Error('FIREBASE_SERVICE_ACCOUNT missing required fields')
  }

  const privateKey = await importPKCS8(serviceAccount.private_key, 'RS256')
  const now = Math.floor(Date.now() / 1000)

  const jwt = await new SignJWT({
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
  })
    .setProtectedHeader({ alg: 'RS256' })
    .setIssuer(serviceAccount.client_email)
    .setAudience('https://oauth2.googleapis.com/token')
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(privateKey)

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  })

  const data = await res.json()
  if (!data.access_token) {
    throw new Error(`Failed to get access token: ${JSON.stringify(data)}`)
  }

  cachedToken = {
    token: data.access_token,
    expiresAt: Date.now() + data.expires_in * 1000,
  }
  return data.access_token
}

// ✅ إرسال إشعار FCM لجهاز واحد
async function sendFCM(
  token: string,
  title: string,
  body: string,
  data: Record<string, string>
): Promise<boolean> {
  const accessToken = await getAccessToken()
  const projectId = serviceAccount.project_id

  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token,
          notification: { title, body },
          data,
          android: {
            priority: 'high',
            notification: {
              channel_id: 'debt_notifications',
              sound: 'default',
            },
          },
        },
      }),
    }
  )

  if (!res.ok) {
    const err = await res.text()
    console.error(`FCM failed for token ${token.substring(0, 10)}...: ${err}`)
    return false
  }
  return true
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const payload = await req.json()
    console.log('📬 Payload:', JSON.stringify(payload))

    const record = payload.record
    if (!record) {
      return new Response(JSON.stringify({ error: 'No record' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const userId = record.user_id
    const amount = record.amount
    const debtId = record.debt_id
    const senderDeviceId = record.sender_device_id

    if (!userId) {
      return new Response(JSON.stringify({ error: 'No user_id' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // ✅ استخدم Service Role للقراءة من device_tokens
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // 1. اقرأ اسم الشخص المرتبط بالدين
    const { data: debt } = await supabase
      .from('debts')
      .select('person_id')
      .eq('id', debtId)
      .single()

    let personName = 'شخص'
    if (debt?.person_id) {
      const { data: person } = await supabase
        .from('persons')
        .select('name')
        .eq('id', debt.person_id)
        .single()
      if (person?.name) personName = person.name
    }

    // 2. اقرأ جميع tokens المستخدم
    const { data: tokens, error: tokensError } = await supabase
      .from('device_tokens')
      .select('token')
      .eq('user_id', userId)

    if (tokensError) {
      console.error('tokens error:', tokensError)
      throw tokensError
    }

    if (!tokens || tokens.length === 0) {
      console.log('⚠️ No device tokens for user')
      return new Response(JSON.stringify({ sent: 0 }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // 3. أرسل FCM لكل جهاز
    const title = '💰 تم استلام دفعة'
    const body = `${personName} دفع ${amount} دينار`
    const fcmData = {
      type: 'payment_received',
      route: `/debt/${debtId}`,
      person_name: personName,
      amount: String(amount),
      debt_id: debtId,
      sender_device_id: senderDeviceId ?? '',
    }

    let sent = 0
    for (const { token } of tokens) {
      const ok = await sendFCM(token, title, body, fcmData)
      if (ok) sent++
    }

    console.log(`✅ Sent ${sent}/${tokens.length} notifications`)

    return new Response(JSON.stringify({ sent, total: tokens.length }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (e) {
    console.error('❌ Error:', e)
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})