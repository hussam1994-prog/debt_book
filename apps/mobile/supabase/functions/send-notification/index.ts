// supabase/functions/send-notification/index.ts
import { serve } from 'https://deno.land/std@0.208.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { SignJWT, importPKCS8 } from 'https://deno.land/x/jose@v5.2.2/index.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const serviceAccount = JSON.parse(
  Deno.env.get('FIREBASE_SERVICE_ACCOUNT') ?? '{}'
)

let cachedToken: { token: string; expiresAt: number } | null = null

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
  cachedToken = {
    token: data.access_token,
    expiresAt: Date.now() + data.expires_in * 1000,
  }
  return data.access_token
}

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
    console.error(`FCM failed: ${err}`)
    return false
  }
  return true
}

async function buildNotification(
  supabase: any,
  table: string,
  record: any
): Promise<{ title: string; body: string; data: Record<string, string> } | null> {
  switch (table) {
    case 'payments': {
      const { data: debt } = await supabase
        .from('debts').select('person_id').eq('id', record.debt_id).single()
      let personName = 'شخص'
      if (debt?.person_id) {
        const { data: person } = await supabase
          .from('persons').select('name').eq('id', debt.person_id).single()
        if (person?.name) personName = person.name
      }
      return {
        title: '💰 تم استلام دفعة',
        body: `${personName} دفع ${record.amount} دينار`,
        data: {
          type: 'payment_received',
          route: `/debt/${record.debt_id}`,
          debt_id: String(record.debt_id),
          person_name: personName,
          amount: String(record.amount),
        },
      }
    }

    case 'debts': {
      if (record.is_deleted === true) return null
      const { data: person } = await supabase
        .from('persons').select('name').eq('id', record.person_id).single()
      const personName = person?.name ?? 'شخص'
      return {
        title: '📋 دين جديد',
        body: `${personName}: ${record.amount} دينار`,
        data: {
          type: 'debt_created',
          route: `/debt/${record.id}`,
          debt_id: String(record.id),
          person_name: personName,
          amount: String(record.amount),
        },
      }
    }

    case 'persons': {
      if (record.is_deleted === true) {
        return {
          title: '🗑️ تم حذف شخص',
          body: record.name ?? 'شخص',
          data: {
            type: 'person_deleted',
            route: '/',
            person_name: record.name ?? '',
          },
        }
      }
      return {
        title: '👤 شخص جديد',
        body: record.name ?? 'شخص',
        data: {
          type: 'person_created',
          route: `/person/${record.id}`,
          person_name: record.name ?? '',
        },
      }
    }

    case 'ledger_entries': {
      if (record.entry_type === 'adjustment') {
        const sign = record.amount > 0 ? 'زيادة' : 'تخفيض'
        return {
          title: '⚖️ تسوية',
          body: `${sign} بقيمة ${Math.abs(record.amount)} دينار`,
          data: {
            type: 'adjustment',
            route: `/debt/${record.debt_id}`,
            debt_id: String(record.debt_id),
            amount: String(record.amount),
          },
        }
      }
      if (record.entry_type === 'reversal') {
        return {
          title: '↩️ تم عكس دفعة',
          body: `بقيمة ${record.amount} دينار`,
          data: {
            type: 'reversal',
            route: `/debt/${record.debt_id}`,
            debt_id: String(record.debt_id),
            amount: String(record.amount),
          },
        }
      }
      return null
    }

    default:
      return null
  }
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const payload = await req.json()
    console.log('📬 Payload:', JSON.stringify(payload))

    const record = payload.record
    const table = payload.table

    if (!record || !table) {
      return new Response(JSON.stringify({ error: 'Missing record or table' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const userId = record.user_id
    if (!userId) {
      return new Response(JSON.stringify({ error: 'No user_id' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const notification = await buildNotification(supabase, table, record)
    if (!notification) {
      console.log('⏭️ Skipping notification')
      return new Response(JSON.stringify({ skipped: true }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const { data: tokens, error: tokensError } = await supabase
      .from('device_tokens')
      .select('token')
      .eq('user_id', userId)

    if (tokensError) throw tokensError
    if (!tokens || tokens.length === 0) {
      return new Response(JSON.stringify({ sent: 0 }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // ✅ استبعد الجهاز المُرسل
    const senderDeviceId = record.sender_device_id
    let sent = 0

    for (const { token } of tokens) {
      // ⏭️ تجاوز الجهاز المُرسل (إذا كان معروفًا)
      if (senderDeviceId && record.device_id === senderDeviceId) {
        console.log(`⏭️ Skipping sender device`)
        continue
      }

      const ok = await sendFCM(token, notification.title, notification.body, notification.data)
      if (ok) sent++
    }

    console.log(`✅ Sent ${sent}/${tokens.length}`)
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