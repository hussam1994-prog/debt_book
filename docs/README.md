# 📚 فهرس التوثيق — Debt Book

مرحباً بك في التوثيق الشامل لمشروع **دفتر الديون**.

---

## 📖 الأدلة الرئيسية

| الدليل | الوصف |
|--------|--------|
| [architecture.md](architecture.md) | معمارية المشروع والطبقات |
| [testing.md](testing.md) | دليل الاختبارات |
| [deployment.md](deployment.md) | النشر على Google Play |
| [contributing.md](contributing.md) | دليل المساهمة |

---

## 🏛️ القرارات المعمارية (ADR)

كل قرار معماري مهم موثّق كـ ADR:

| # | العنوان | الحالة |
|---|---------|--------|
| [001](adr/001-append-only-ledger.md) | دفتر الأستاذ Append-Only | ✅ معتمد |
| [002](adr/002-outbox-pattern.md) | Outbox Pattern للمزامنة | ✅ معتمد |
| [003](adr/003-fk-enforcement.md) | تفعيل Foreign Keys | ✅ معتمد |
| [004](adr/004-drift-version.md) | ترقية Drift إلى 2.35 | ✅ معتمد |
| [005](adr/005-riverpod-providers.md) | توحيد Providers | ✅ معتمد |
| [006](adr/006-logging-service.md) | LoggingService موحّد | ✅ معتمد |

---

## 📂 بنية المشروع
debt_book/
├── apps/mobile/ ← تطبيق Flutter
├── packages/domain/ ← منطق الأعمال
├── docs/ ← هذا المجلد
│ ├── README.md ← أنت هنا
│ ├── architecture.md
│ ├── testing.md
│ ├── deployment.md
│ ├── contributing.md
│ └── adr/ ← القرارات المعمارية
└── scripts/ ← أدوات


---

## 🎯 البدء السريع

- **مطوّر جديد؟** → ابدأ بـ [architecture.md](architecture.md)
- **تريد المساهمة؟** → اقرأ [contributing.md](contributing.md)
- **جاهز للنشر؟** → اتبع [deployment.md](deployment.md)
- **تفهم القرارات؟** → راجع [adr/](adr/)

---

## 🔗 روابط مفيدة

- [Flutter](https://flutter.dev)
- [Drift](https://drift.simonbinder.eu)
- [Supabase](https://supabase.com)
- [Riverpod](https://riverpod.dev)
- [GoRouter](https://pub.dev/packages/go_router)

---

## 📞 الدعم

- 🐛 [Issues](../../issues)
- 💬 [Discussions](../../discussions)