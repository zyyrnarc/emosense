import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

const String _logoSvg = '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="haloGrad" x1="8" y1="8" x2="40" y2="40" gradientUnits="userSpaceOnUse">
      <stop offset="0" stop-color="#004ac6"/>
      <stop offset="1" stop-color="#4edea3"/>
    </linearGradient>
    <linearGradient id="brandStroke" x1="6" y1="6" x2="42" y2="42" gradientUnits="userSpaceOnUse">
      <stop offset="0" stop-color="#2563eb"/>
      <stop offset="1" stop-color="#006c49"/>
    </linearGradient>
  </defs>
  <circle cx="24" cy="24" r="19" fill="url(#haloGrad)" fill-opacity="0.15"/>
  <circle cx="24" cy="24" r="18" stroke="url(#brandStroke)" stroke-width="2" stroke-dasharray="3 2.5" stroke-opacity="0.6"/>
  <circle cx="17" cy="19" r="2.5" fill="#004ac6"/>
  <circle cx="31" cy="19" r="2.5" fill="#004ac6"/>
  <path d="M16 27C17.8 31.5 30.2 31.5 32 27" stroke="#004ac6" stroke-width="2.5" stroke-linecap="round"/>
  <circle cx="14" cy="24" r="1" fill="#006c49"/>
  <circle cx="34" cy="24" r="1" fill="#006c49"/>
  <circle cx="24" cy="12" r="1" fill="#006c49"/>
  <circle cx="24" cy="35" r="1" fill="#006c49"/>
  <path d="M9 16L9 11C9 9.9 9.9 9 11 9L16 9" stroke="#2563eb" stroke-width="1.8" stroke-linecap="round"/>
  <path d="M39 16L39 11C39 9.9 38.1 9 37 9L32 9" stroke="#2563eb" stroke-width="1.8" stroke-linecap="round"/>
  <path d="M9 32L9 37C9 38.1 9.9 39 11 39L16 39" stroke="#2563eb" stroke-width="1.8" stroke-linecap="round"/>
  <path d="M39 32L39 37C39 38.1 38.1 39 37 39L32 39" stroke="#2563eb" stroke-width="1.8" stroke-linecap="round"/>
</svg>
''';

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.md,
                  gradient: LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: [
                      AppColors.primary.withOpacity(0.2),
                      AppColors.surfaceContainerHigh,
                      AppColors.secondaryFixed.withOpacity(0.3),
                    ],
                  ),
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: SvgPicture.string(_logoSvg, width: 48, height: 48),
                ),
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                    boxShadow: AppShadows.sm,
                  ),
                  child: const Icon(Icons.auto_awesome,
                      size: 14, color: AppColors.onSecondaryContainer),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text.rich(
              TextSpan(
                text: AppStrings.appNameFirst,
                children: const [
                  TextSpan(
                    text: AppStrings.appNameSecond,
                    style: TextStyle(color: AppColors.primaryContainer),
                  ),
                ],
              ),
              style: AppText.headlineXlMobile(),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.secondaryFixed,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                AppStrings.versionBadge,
                style: AppText.labelSm(AppColors.onSecondaryFixed),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Text(
            AppStrings.tagline,
            textAlign: TextAlign.center,
            style: AppText.bodyMd(AppColors.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
