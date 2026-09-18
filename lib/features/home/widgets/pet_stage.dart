import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../data/models/pet.dart';
import '../../../data/models/pet_enums.dart';
import '../../pet/widgets/pet_avatar.dart';

class PetStage extends StatelessWidget {
  const PetStage({
    super.key,
    required this.pet,
    this.message,
    this.compact = true,
    this.action,
    this.showName = true,
  });

  final Pet? pet;
  final String? message;
  final bool compact;
  final PetAction? action;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedHeight = constraints.maxHeight.isFinite &&
            constraints.maxHeight < double.infinity;
        final padV = compact
            ? 20.0
            : (hasBoundedHeight && constraints.maxHeight < 220 ? 8.0 : 12.0);

        final content = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: hasBoundedHeight ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: PetAvatar(
                  pet: pet,
                  action: action,
                  borderRadius: 20,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            if (showName) ...[
              const SizedBox(height: 6),
              Text(
                pet?.name ?? '选择宠物',
                style: AppTextStyles.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (message != null) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '“$message”',
                  style: AppTextStyles.bodySecondary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        );

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: padV, horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.surfaceSecondary.withValues(alpha: 0.8),
                AppColors.surface,
              ],
            ),
          ),
          child: hasBoundedHeight
              ? content
              : SizedBox(
                  height: compact ? 220 : 280,
                  child: content,
                ),
        );
      },
    );
  }
}
