import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/services/providers.dart';
import '../../../domain/display/phone_display_device.dart';
import '../../../domain/display/remote/display_host_server.dart';
import '../../../domain/display/remote/display_protocol.dart';
import '../../../domain/display/remote/host_display_content.dart';
import 'fullscreen_display_page.dart';

/// 七寸屏显示端：起服务 + 全屏展示遥控指令
class DisplayHostPage extends ConsumerStatefulWidget {
  const DisplayHostPage({super.key});

  @override
  ConsumerState<DisplayHostPage> createState() => _DisplayHostPageState();
}

class _DisplayHostPageState extends ConsumerState<DisplayHostPage> {
  DisplayHostServer? _server;
  String? _ip;
  String _code = '';
  bool _clientConnected = false;
  String? _error;
  bool _starting = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    await ref.read(screenServiceProvider).enterFullscreen();
    if (kIsWeb) {
      setState(() {
        _starting = false;
        _error = '显示端请在 Android / 七寸屏上运行';
      });
      return;
    }

    try {
      final server = DisplayHostServer(
        onCommand: (msg) {
          ref.read(hostDisplayContentProvider.notifier).applyMessage(msg);
          _syncPhoneDisplay(msg);
        },
        onClientChanged: (connected) {
          if (!mounted) return;
          setState(() => _clientConnected = connected);
        },
      );
      await server.start();
      final ip = await DisplayHostServer.localIPv4();
      if (!mounted) {
        await server.stop();
        return;
      }
      setState(() {
        _server = server;
        _code = server.pairingCode;
        _ip = ip;
        _starting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _starting = false;
        _error = '启动显示端失败：$e';
      });
    }
  }

  Future<void> _syncPhoneDisplay(DisplayRemoteMessage msg) async {
    final device = ref.read(displayDeviceProvider);
    if (device is! PhoneDisplayDevice) return;
    switch (msg.type) {
      case DisplayRemoteMessage.typeExpression:
        await device.clear();
      case DisplayRemoteMessage.typeCustom:
        final content = ref.read(hostDisplayContentProvider);
        final custom = content.custom;
        if (custom != null) await device.showCustom(custom);
      case DisplayRemoteMessage.typeClear:
        await device.clear();
      default:
        break;
    }
  }

  Future<void> _exit() async {
    ref.read(hostDisplayContentProvider.notifier).clear();
    await _server?.stop();
    await ref.read(screenServiceProvider).exitFullscreen();
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/mine');
    }
  }

  @override
  void dispose() {
    _server?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = ref.watch(hostDisplayContentProvider);

    if (content.hasContent) {
      return Stack(
        fit: StackFit.expand,
        children: [
          FullscreenDisplayPage(
            key: ValueKey(
              'host_${content.expressionId}_${content.custom?.id}',
            ),
            expressionId: content.expressionId,
            customText: content.custom?.text,
            embedded: true,
            onTapAway: () {
              ref.read(hostDisplayContentProvider.notifier).clear();
              final device = ref.read(displayDeviceProvider);
              if (device is PhoneDisplayDevice) {
                device.clear();
              }
            },
          ),
          Positioned(
            top: 8,
            right: 8,
            child: SafeArea(
              child: IconButton(
                tooltip: '退出显示端',
                color: Colors.white54,
                onPressed: _exit,
                icon: const Icon(Icons.close),
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _starting
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: TextButton(
                        onPressed: _exit,
                        child: const Text('退出'),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '显示端',
                      style: AppTextStyles.headline.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _clientConnected ? '手机已连接，等待内容…' : '等待手机连接…',
                      style: AppTextStyles.bodySecondary.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (_error != null)
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body.copyWith(color: Colors.redAccent),
                      )
                    else ...[
                      _InfoCard(
                        label: '本机 IP',
                        value: _ip ?? '获取中…',
                        onCopy: _ip == null
                            ? null
                            : () async {
                                await Clipboard.setData(ClipboardData(text: _ip!));
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('已复制 IP')),
                                );
                              },
                      ),
                      const SizedBox(height: 12),
                      _InfoCard(
                        label: '配对码',
                        value: _code,
                        emphasize: true,
                        onCopy: () async {
                          await Clipboard.setData(ClipboardData(text: _code));
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已复制配对码')),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '端口 $kDisplayRemotePort · 请与手机同一 Wi‑Fi / 热点',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white54,
                        ),
                      ),
                    ],
                    const Spacer(),
                  ],
                ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.onCopy,
  });

  final String label;
  final String value;
  final bool emphasize;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: (emphasize
                          ? AppTextStyles.headline
                          : AppTextStyles.title)
                      .copyWith(
                    color: Colors.white,
                    letterSpacing: emphasize ? 4 : 0,
                  ),
                ),
              ],
            ),
          ),
          if (onCopy != null)
            IconButton(
              onPressed: onCopy,
              icon: const Icon(Icons.copy, color: Colors.white70),
            ),
        ],
      ),
    );
  }
}
