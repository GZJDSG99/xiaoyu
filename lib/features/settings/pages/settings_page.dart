import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../data/repositories/expression_repository.dart';
import '../../pet/providers/current_pet_provider.dart';
import '../../pet/widgets/pet_avatar.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pet = ref.watch(currentPetProvider);
    final favorites = ref.watch(expressionRepositoryProvider).getFavorites();
    final recent = ref.watch(expressionRepositoryProvider).getRecent();

    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        children: [
          ListTile(
            leading: PetAvatar(pet: pet, size: 40, borderRadius: 10),
            title: Text(pet?.name ?? '未选择宠物', style: AppTextStyles.title),
            subtitle: Text(
              pet?.personality ?? '去选择你的小语伙伴',
              style: AppTextStyles.bodySecondary,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/pet-select'),
          ),
          const Divider(color: AppColors.border),
          ListTile(
            leading: const Icon(Icons.favorite_outline),
            title: const Text('收藏'),
            subtitle: Text('${favorites.length} 条', style: AppTextStyles.caption),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('最近使用'),
            subtitle: Text('${recent.length} 条', style: AppTextStyles.caption),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.wallpaper_outlined),
            title: const Text('切换背景'),
            subtitle: const Text('首页氛围背景', style: AppTextStyles.caption),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/backgrounds'),
          ),
          ListTile(
            leading: const Icon(Icons.cast),
            title: const Text('连接显示器'),
            subtitle: const Text('手机遥控七寸显示端', style: AppTextStyles.caption),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/display-connect'),
          ),
          ListTile(
            leading: const Icon(Icons.tv_outlined),
            title: const Text('作为显示端'),
            subtitle: const Text('本机作为七寸显示器', style: AppTextStyles.caption),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/display-host'),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('设置'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('关于'),
            subtitle: const Text('小语 App V1.0 框架'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: '小语',
                applicationVersion: '1.0.0',
                applicationLegalese: 'CarTalk · 车载情绪显示器',
              );
            },
          ),
        ],
      ),
    );
  }
}
