#!/usr/bin/env python3
"""
فحص الثيم الليلي والألوان الثابتة المتعارضة.
يشمل الآن:
- وجود dark theme
- ألوان ثابتة hardcoded في شاشات العرض
- ألوان ثابتة داخل AppTextStyles (مثل AppColors.textPrimary / textSecondary)
- مراجع AppColors ثابتة في الشاشات
"""

import os
import re

ROOT = os.path.dirname(os.path.abspath(__file__))
if os.path.basename(ROOT) == "scripts":
    ROOT = os.path.dirname(ROOT)

MOBILE_DIR = os.path.join(ROOT, "apps", "mobile")
LIB_DIR = os.path.join(MOBILE_DIR, "lib")

# مجلدات مستثناة (ملف الثيم نفسه ومجلد اللغة)
EXCLUDE_DIRS = [
    os.path.join(LIB_DIR, "core", "theme"),
    os.path.join(LIB_DIR, "l10n"),
]

COLOR_PATTERNS = [
    re.compile(r"Colors\.white"),
    re.compile(r"Colors\.black"),
    re.compile(r"Color\(0x[0-9A-Fa-f]{8}\)"),
]

STATIC_APP_COLORS = [
    re.compile(r"AppColors\.textPrimary"),
    re.compile(r"AppColors\.textSecondary"),
]

def check_dark_theme_exists():
    theme_file = os.path.join(MOBILE_DIR, "lib", "core", "theme", "app_theme.dart")
    if not os.path.exists(theme_file):
        print("❌ ملف app_theme.dart غير موجود")
        return False

    with open(theme_file, "r", encoding="utf-8") as f:
        content = f.read()
        if "static ThemeData get dark" in content:
            print("✅ الوضع الداكن معرّف في app_theme.dart")
            return True
        else:
            print("❌ لا يوجد dark theme في app_theme.dart")
            return False

def check_apptextstyles_colors():
    """فحص ملف app_theme.dart عن ألوان ثابتة داخل AppTextStyles."""
    theme_file = os.path.join(MOBILE_DIR, "lib", "core", "theme", "app_theme.dart")
    if not os.path.exists(theme_file):
        print("❌ ملف app_theme.dart غير موجود")
        return False

    with open(theme_file, "r", encoding="utf-8") as f:
        content = f.read()

    issues = []
    if "AppColors.textPrimary" in content:
        issues.append("AppColors.textPrimary")
    if "AppColors.textSecondary" in content:
        issues.append("AppColors.textSecondary")

    if issues:
        print(f"⚠️ أنماط نصية ثابتة داخل AppTextStyles تستخدم ألوان غير متغيرة: {', '.join(issues)}")
        return False
    else:
        print("✅ أنماط النصوص تستخدم ألوان الثيم الديناميكية")
        return True

def scan_dart_files():
    """فحص الشاشات عن ألوان ثابتة hardcoded."""
    issues = []
    for root, dirs, files in os.walk(LIB_DIR):
        # استبعاد المجلدات المستثناة
        dirs[:] = [d for d in dirs if os.path.join(root, d) not in EXCLUDE_DIRS]

        for file in files:
            if not file.endswith(".dart"):
                continue
            path = os.path.join(root, file)
            with open(path, "r", encoding="utf-8") as f:
                content = f.read()

            for pattern in COLOR_PATTERNS:
                matches = pattern.findall(content)
                if matches:
                    issues.append(f"⚠️ لون ثابت hardcoded في {path}: {pattern.pattern}")
                    break

            for pattern in STATIC_APP_COLORS:
                matches = pattern.findall(content)
                if matches:
                    issues.append(f"💡 لون ثابت من AppColors قد لا يتغير في الوضع الداكن: {path} ({pattern.pattern})")
                    break

    return issues

def main():
    print("=" * 60)
    print("فحص الثيم الليلي والألوان الثابتة")
    print("=" * 60)

    dark_exists = check_dark_theme_exists()
    apptextstyles_ok = check_apptextstyles_colors()
    issues = scan_dart_files()

    if issues:
        print("\n⚠️ المشاكل المحتملة:")
        for issue in issues:
            print(issue)
    else:
        print("\n✅ لا توجد ألوان ثابتة متعارضة واضحة")

    print("\n" + "=" * 60)
    print("ملخص")
    print("=" * 60)
    if dark_exists and apptextstyles_ok and not issues:
        print("🎉 الثيم الليلي سليم ولا توجد ألوان ثابتة متعارضة")
    else:
        print("⚠️ يرجى مراجعة الملاحظات أعلاه")
    print("=" * 60)

if __name__ == "__main__":
    main()