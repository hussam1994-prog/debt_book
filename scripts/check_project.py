#!/usr/bin/env python3
"""
فحص آلي شامل لمشروع Debt Book Flutter
يتحقق من:
1. تطابق مفاتيح ملفات الترجمة (en / ar)
2. وجود الشاشات الأساسية
3. استخدام context.l10n في الشاشات مع فحص تغطية النصوص
4. كشف نصوص إنجليزية hardcoded (Regex عام)
5. ملفات الترجمة المولدة
6. توازن الأقواس في repositories
7. وجود التبعيات المطلوبة في pubspec.yaml
"""

import os
import json
import re

ROOT = os.path.dirname(os.path.abspath(__file__))
if os.path.basename(ROOT) == "scripts":
    ROOT = os.path.dirname(ROOT)

MOBILE_DIR = os.path.join(ROOT, "apps", "mobile")
L10N_DIR = os.path.join(MOBILE_DIR, "lib", "l10n")
PRESENTATION_DIR = os.path.join(MOBILE_DIR, "lib", "features")
REPOS_DIR = os.path.join(MOBILE_DIR, "lib", "data", "repositories")

SCREENS = [
    "people/presentation/people_page.dart",
    "people/presentation/person_detail_page.dart",
    "debts/presentation/add_debt_page.dart",
    "debts/presentation/debt_detail_page.dart",
    "debts/presentation/all_debts_page.dart",
    "payments/presentation/add_payment_page.dart",
    "dashboard/presentation/dashboard_page.dart",
    "reports/presentation/reports_page.dart",
    "settings/presentation/settings_page.dart",
    "backup/presentation/backup_page.dart",
    "insights/presentation/insights_page.dart",
    "splash/presentation/splash_screen.dart",
]

REQUIRED_DEPENDENCIES = [
    "sqlite3_flutter_libs",
    "shared_preferences",
    "flutter_localizations",
    "flutter_local_notifications",
    "url_launcher",
    "file_picker",
    "share_plus",
]

def check_translation_keys():
    en_file = os.path.join(L10N_DIR, "app_en.arb")
    ar_file = os.path.join(L10N_DIR, "app_ar.arb")
    if not os.path.exists(en_file):
        print("❌ ملف app_en.arb غير موجود")
        return False
    if not os.path.exists(ar_file):
        print("❌ ملف app_ar.arb غير موجود")
        return False

    with open(en_file, "r", encoding="utf-8") as f:
        en_data = json.load(f)
    with open(ar_file, "r", encoding="utf-8") as f:
        ar_data = json.load(f)

    en_keys = set(k for k in en_data if not k.startswith("@"))
    ar_keys = set(k for k in ar_data if not k.startswith("@"))

    missing_in_ar = en_keys - ar_keys
    missing_in_en = ar_keys - en_keys

    if missing_in_ar:
        print(f"⚠️ مفاتيح موجودة في en وليست في ar: {', '.join(sorted(missing_in_ar))}")
    if missing_in_en:
        print(f"⚠️ مفاتيح موجودة في ar وليست في en: {', '.join(sorted(missing_in_en))}")

    if not missing_in_ar and not missing_in_en:
        print("✅ ملفات الترجمة متطابقة تمامًا")
        return True
    return False

def check_screens():
    all_exist = True
    for screen in SCREENS:
        path = os.path.join(PRESENTATION_DIR, screen)
        if not os.path.exists(path):
            print(f"❌ شاشة مفقودة: {screen}")
            all_exist = False
        else:
            print(f"✅ {screen}")
    return all_exist

def check_l10n_usage():
    count_used = 0
    count_total = 0
    for screen in SCREENS:
        path = os.path.join(PRESENTATION_DIR, screen)
        if not os.path.exists(path):
            continue
        count_total += 1
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()
            if "context.l10n" in content or "l10n." in content:
                count_used += 1
                print(f"✅ {screen} يستخدم l10n")
            else:
                print(f"⚠️ {screen} لا يستخدم l10n")
    print(f"\nالإجمالي: {count_used}/{count_total} شاشة تستخدم l10n")
    return count_used == count_total

def check_hardcoded_english():
    # نمط يطابق أي نص إنجليزي داخل Text أو labelText أو hintText أو tooltip
    patterns = [
        r"Text\(\s*['\"]([A-Za-z][A-Za-z\s]+)['\"]",
        r"labelText:\s*['\"]([A-Za-z][A-Za-z\s]+)['\"]",
        r"hintText:\s*['\"]([A-Za-z][A-Za-z\s]+)['\"]",
        r"tooltip:\s*['\"]([A-Za-z][A-Za-z\s]+)['\"]",
    ]
    found_any = False
    for screen in SCREENS:
        path = os.path.join(PRESENTATION_DIR, screen)
        if not os.path.exists(path):
            continue
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()
        for pattern in patterns:
            matches = re.findall(pattern, content)
            if matches:
                # استبعاد بعض الكلمات المسموح بها مثل أسماء المتغيرات أو أخطاء المعالجة
                filtered = [m for m in matches if m.strip() not in {"Error", "IQD"}]
                if filtered:
                    print(f"⚠️ نص إنجليزي hardcoded محتمل في {screen}: {filtered[:5]}...")
                    found_any = True
    if not found_any:
        print("✅ لا توجد نصوص إنجليزية hardcoded واضحة")
    return not found_any

def check_generated_localizations():
    gen_path = os.path.join(L10N_DIR, "app_localizations.dart")
    if os.path.exists(gen_path):
        print("✅ ملف app_localizations.dart موجود")
        return True
    else:
        print("❌ ملف الترجمة المولدة غير موجود. شغّل: flutter gen-l10n")
        return False

def check_braces_balance():
    """فحص توازن الأقواس في ملفات repositories."""
    if not os.path.exists(REPOS_DIR):
        print("❌ مجلد repositories غير موجود")
        return False

    all_balanced = True
    for filename in os.listdir(REPOS_DIR):
        if filename.endswith(".dart"):
            path = os.path.join(REPOS_DIR, filename)
            with open(path, "r", encoding="utf-8") as f:
                content = f.read()
            opens = content.count("{")
            closes = content.count("}")
            if opens != closes:
                print(f"❌ عدم توازن أقواس في {filename}: فتح={opens} إغلاق={closes}")
                all_balanced = False
            else:
                print(f"✅ {filename} أقواس متوازنة")
    return all_balanced

def check_pubspec():
    pubspec_path = os.path.join(MOBILE_DIR, "pubspec.yaml")
    if not os.path.exists(pubspec_path):
        print("❌ pubspec.yaml غير موجود")
        return False

    with open(pubspec_path, "r", encoding="utf-8") as f:
        content = f.read()

    missing = [dep for dep in REQUIRED_DEPENDENCIES if dep not in content]
    if missing:
        print(f"⚠️ تبعيات ناقصة في pubspec.yaml: {', '.join(missing)}")
        return False
    else:
        print("✅ جميع التبعيات المطلوبة موجودة")
        return True

def main():
    print("=" * 60)
    print("فحص مشروع Debt Book الشامل")
    print("=" * 60)

    results = []
    results.append(check_translation_keys())
    results.append(check_screens())
    results.append(check_l10n_usage())
    results.append(check_hardcoded_english())
    results.append(check_generated_localizations())
    results.append(check_braces_balance())
    results.append(check_pubspec())

    print("\n" + "=" * 60)
    print("ملخص النتائج")
    print("=" * 60)
    if all(results):
        print("🎉 كل الفحوصات ناجحة! التطبيق جاهز.")
    else:
        print("⚠️ توجد مشاكل، راجع الملاحظات أعلاه.")
    print("=" * 60)

if __name__ == "__main__":
    main()