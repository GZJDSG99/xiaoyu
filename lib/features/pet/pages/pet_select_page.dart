import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../data/local/local_storage.dart';
import '../../../data/models/pet.dart';
import '../../../data/repositories/pet_repository.dart';
import '../../../domain/services/pet_service.dart';
import '../widgets/pet_avatar.dart';

class PetSelectPage extends ConsumerStatefulWidget {
  const PetSelectPage({super.key, this.isFirstLaunch = false});

  final bool isFirstLaunch;

  @override
  ConsumerState<PetSelectPage> createState() => _PetSelectPageState();
}

class _PetSelectPageState extends ConsumerState<PetSelectPage> {
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    final currentId = ref.read(localStorageProvider).currentPetId;
    final current = ref.read(petRepositoryProvider).getById(currentId ?? '');
    _selectedId =
        (current != null && current.available) ? current.id : 'cat';
  }

  Future<void> _confirm() async {
    final id = _selectedId;
    if (id == null) return;
    final pet = ref.read(petRepositoryProvider).getById(id);
    if (pet == null || !pet.available) return;

    await ref.read(petServiceProvider).selectPet(
          id,
          completeFirstLaunch: widget.isFirstLaunch,
        );
    if (!mounted) return;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final pets = ref.watch(petRepositoryProvider).getAll();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isFirstLaunch ? '欢迎来到小语' : '选择陪伴伙伴',
                style: AppTextStyles.headline,
              ),
              const SizedBox(height: 8),
              Text(
                widget.isFirstLaunch
                    ? '选择你的陪伴伙伴，一起上路吧'
                    : '随时可以更换你的小语伙伴',
                style: AppTextStyles.bodySecondary,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: pets.length,
                  itemBuilder: (context, index) {
                    final pet = pets[index];
                    final selected = pet.available && pet.id == _selectedId;
                    return _PetCard(
                      pet: pet,
                      selected: selected,
                      onTap: pet.available
                          ? () => setState(() => _selectedId = pet.id)
                          : null,
                    );
                  },
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _confirm,
                  child: Text(widget.isFirstLaunch ? '开始使用' : '设为我的宠物'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PetCard extends StatelessWidget {
  const _PetCard({
    required this.pet,
    required this.selected,
    required this.onTap,
  });

  final Pet pet;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final locked = !pet.available;

    return Opacity(
      opacity: locked ? 0.55 : 1,
      child: Material(
        color: selected ? AppColors.surfaceSecondary : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 2 : 1,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
            child: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: locked
                          ? Center(
                              child: Text(
                                pet.emoji,
                                style: const TextStyle(fontSize: 40),
                              ),
                            )
                          : PetAvatar(
                              pet: pet,
                              borderRadius: 12,
                              fit: BoxFit.contain,
                              useCard: true,
                            ),
                    ),
                    const SizedBox(height: 6),
                    Text(pet.name, style: AppTextStyles.body),
                    Text(
                      locked ? '待领养' : pet.personality,
                      style: AppTextStyles.caption.copyWith(
                        color: locked
                            ? AppColors.warning
                            : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                if (locked)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '待领养',
                        style: TextStyle(
                          color: Color(0xFF1A2433),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
