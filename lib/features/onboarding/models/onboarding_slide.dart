import 'package:flutter/material.dart';

class OnboardingSlide {
  final IconData icon;
  final String title;
  final String description;
  final List<Color> gradient;

  const OnboardingSlide({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
  });
}

final List<OnboardingSlide> onboardingSlides = [
  const OnboardingSlide(
    icon: Icons.account_balance_wallet,
    title: 'مرحبًا بك في دفتر الديون',
    description:
        'أدر ديونك بسهولة واحترافية، وتابع كل معاملة بدقة من أي مكان.',
    gradient: [Color(0xFF1E3A5F), Color(0xFF4A6B94)],
  ),
  const OnboardingSlide(
    icon: Icons.people,
    title: 'الأشخاص',
    description:
        'أضف الأشخاص الذين تتعامل معهم، واعرض إجمالي المستحقات لكل شخص في لمحة.',
    gradient: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
  ),
  const OnboardingSlide(
    icon: Icons.receipt_long,
    title: 'الديون والدفعات',
    description:
        'أنشئ ديونًا، سجّل دفعات، وأضف تسويات. الرصيد يُحسب تلقائيًا من دفتر الأستاذ.',
    gradient: [Color(0xFF1976D2), Color(0xFF42A5F5)],
  ),
  const OnboardingSlide(
    icon: Icons.calendar_month,
    title: 'التقسيط',
    description:
        'قسّم الدين على أقساط متساوية، وتابع كل قسط مع تنبيهات ذكية.',
    gradient: [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
  ),
  const OnboardingSlide(
    icon: Icons.bar_chart,
    title: 'التقارير والرؤى',
    description:
        'تقارير PDF و CSV بدعم عربي كامل، ورؤى ذكية عن المخاطر والتنبؤات.',
    gradient: [Color(0xFFEF6C00), Color(0xFFFFA726)],
  ),
  const OnboardingSlide(
    icon: Icons.notifications_active,
    title: 'الإشعارات الذكية',
    description:
        'تذكيرات تلقائية قبل الاستحقاق، وإشعارات عند استلام دفعات جديدة.',
    gradient: [Color(0xFF00838F), Color(0xFF26C6DA)],
  ),
  const OnboardingSlide(
    icon: Icons.cloud_sync,
    title: 'المزامنة والأمان',
    description:
        'مزامنة سحابية آمنة بين الأجهزة، PIN للحماية، ونسخ احتياطي تلقائي.',
    gradient: [Color(0xFF37474F), Color(0xFF78909C)],
  ),
];