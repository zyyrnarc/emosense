import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routers/app_routers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/benefit_tile.dart';
import '../widgets/brand_header.dart';
import '../widgets/mood_showcase_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _HomePageView();
  }
}

class _HomePageView extends StatelessWidget {
  const _HomePageView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            children: [
              const BrandHeader(),
              const SizedBox(height: 24),
              const MoodShowcaseCard(),
              const SizedBox(height: 24),
              BenefitTile(
                icon: Icons.sensor_occupied,
                iconColor: AppColors.primary,
                gradient: [
                  AppColors.primaryFixed,
                  AppColors.primary.withOpacity(0.15),
                ],
                borderColor: AppColors.primary.withOpacity(0.10),
                title: AppStrings.benefit1Title,
                body: AppStrings.benefit1Body,
              ),
              const SizedBox(height: 10),
              BenefitTile(
                icon: Icons.query_stats,
                iconColor: AppColors.secondary,
                gradient: [
                  AppColors.secondaryFixed,
                  AppColors.secondary.withOpacity(0.15),
                ],
                borderColor: AppColors.secondary.withOpacity(0.10),
                title: AppStrings.benefit2Title,
                body: AppStrings.benefit2Body,
              ),
              const SizedBox(height: 10),
              BenefitTile(
                icon: Icons.enhanced_encryption,
                iconColor: AppColors.primary,
                gradient: [
                  AppColors.surfaceContainerHighest,
                  AppColors.primaryFixed.withOpacity(0.4),
                ],
                borderColor: AppColors.outlineVariant.withOpacity(0.3),
                title: AppStrings.benefit3Title,
                body: AppStrings.benefit3Body,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified_user,
                      size: 16, color: AppColors.secondary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      AppStrings.trustAnchor,
                      style: AppText.labelSm(AppColors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _PrimaryButton(
                label: AppStrings.ctaStart,
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.register),
              ),
              const SizedBox(height: 12),
              _SecondaryButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _PrimaryButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: AppShadows.md,
      ),
      child: Material(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: AppText.labelLg(AppColors.onPrimary)),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward,
                    size: 18, color: AppColors.onPrimary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _SecondaryButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(AppStrings.ctaHaveAccount,
                  style: AppText.labelLg(AppColors.onSurfaceVariant)),
              const SizedBox(width: 4),
              Text(
                AppStrings.ctaLogin,
                style: AppText.labelLg(AppColors.primary).copyWith(
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.primary.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
