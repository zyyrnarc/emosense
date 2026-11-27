import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'ping_dot.dart';

class MoodShowcaseCard extends StatefulWidget {
  const MoodShowcaseCard({super.key});

  @override
  State<MoodShowcaseCard> createState() => _MoodShowcaseCardState();
}

class _MoodShowcaseCardState extends State<MoodShowcaseCard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.md,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -40,
            child: _GlowBlob(
                size: 144, color: AppColors.secondaryFixed.withOpacity(0.25)),
          ),
          Positioned(
            bottom: -32,
            left: -32,
            child: _GlowBlob(
                size: 128, color: AppColors.primaryFixed.withOpacity(0.30)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const _StatusRow(),
                const SizedBox(height: 16),
                Column(
                  children: [
                    Row(
                      children: [
                        for (var i = 0; i < _moods.length; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          Expanded(
                            child: _MoodPill(
                              mood: _moods[i],
                              selected: i == _selectedIndex,
                              onTap: () => setState(() => _selectedIndex = i),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    _FeedbackBubble(status: _moods[_selectedIndex].status),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const _moods = <MoodItem>[
  MoodItem('\u{1F60A}', 'Bahagia', '99.2%', 'Status: Bahagia & Berenergi'),
  MoodItem('\u{1F60C}', 'Tenang', '96.8%', 'Status: Damai & Rileks'),
  MoodItem('\u{1F603}', 'Antusias', '97.5%', 'Status: Penuh Semangat & Fokus'),
];

class MoodItem {
  const MoodItem(this.emoji, this.label, this.percent, this.status);

  final String emoji;
  final String label;
  final String percent;
  final String status;
}

class _GlowBlob extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowBlob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const PingDot(),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    AppStrings.scannerActive,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.labelSm(),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bolt, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(AppStrings.accuracyBadge,
                  style: AppText.labelSm(AppColors.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}

class _MoodPill extends StatelessWidget {
  final MoodItem mood;
  final bool selected;
  final VoidCallback onTap;

  const _MoodPill({
    required this.mood,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.secondaryFixed.withOpacity(0.4)
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(mood.emoji, style: const TextStyle(fontSize: 24, height: 1.33)),
            const SizedBox(height: 4),
            Text(
              mood.label,
              style: AppText.labelSm(selected
                  ? AppColors.onSecondaryFixedVariant
                  : AppColors.onSurface),
            ),
            const SizedBox(height: 2),
            Text(
              mood.percent,
              style: AppText.labelSm(
                      selected ? AppColors.secondary : AppColors.outline)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackBubble extends StatelessWidget {
  final String status;
  const _FeedbackBubble({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.psychology_alt,
                size: 18, color: AppColors.primaryContainer),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(status,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.labelSm()),
                Text(AppStrings.processedLocal,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.bodySm(AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.check_circle, size: 18, color: AppColors.secondary),
        ],
      ),
    );
  }
}
