import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../data/local/local_storage.dart';
import '../../../domain/display/remote/display_protocol.dart';
import '../../../domain/display/remote/display_session.dart';

/// 遥控端：连接七寸显示端
class DisplayConnectPage extends ConsumerStatefulWidget {
  const DisplayConnectPage({super.key});

  @override
  ConsumerState<DisplayConnectPage> createState() => _DisplayConnectPageState();
}

class _DisplayConnectPageState extends ConsumerState<DisplayConnectPage> {
  late final TextEditingController _hostController;
  late final TextEditingController _codeController;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final storage = ref.read(localStorageProvider);
    final session = ref.read(displaySessionProvider);
    final defaultHost = kIsWeb ? '127.0.0.1' : '';
    _hostController = TextEditingController(
      text: session.host.isNotEmpty
          ? session.host
          : (storage.displayRemoteHost ?? defaultHost),
    );
    _codeController = TextEditingController(
      text: storage.displayRemoteCode ?? '',
    );
    // 不自动重连：错误 IP 会导致一直转圈
  }

  @override
  void dispose() {
    _hostController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (_busy) return;
    setState(() => _busy = true);
    var ok = false;
    try {
      ok = await ref.read(displaySessionProvider.notifier).connect(
            host: _hostController.text,
            code: _codeController.text,
          );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;
    final err = ref.read(displaySessionProvider).errorMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? '已连接显示器'
              : (err?.isNotEmpty == true ? err! : '连接失败，请检查 IP 与配对码'),
        ),
      ),
    );
  }

  Future<void> _disconnect() async {
    await ref.read(displaySessionProvider.notifier).disconnect(keepHost: true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已断开显示器')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(displaySessionProvider);
    final connected = session.isConnected;

    return Scaffold(
      appBar: AppBar(title: const Text('连接显示器')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: connected
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  connected ? Icons.cast_connected : Icons.cast,
                  color: connected ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    connected
                        ? '已连接 ${session.host}:$kDisplayRemotePort'
                        : '未连接',
                    style: AppTextStyles.body,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('显示端 IP', style: AppTextStyles.title),
          const SizedBox(height: 8),
          TextField(
            controller: _hostController,
            enabled: !connected && !_busy,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              hintText: kIsWeb ? '本机 Chrome 连 MuMu 填 127.0.0.1' : '例如 192.168.43.12',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Text('配对码', style: AppTextStyles.title),
          const SizedBox(height: 8),
          TextField(
            controller: _codeController,
            enabled: !connected && !_busy,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              hintText: '六位数字（看显示端屏幕）',
              border: OutlineInputBorder(),
            ),
          ),
          if (session.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              session.errorMessage!,
              style: AppTextStyles.caption.copyWith(color: Colors.redAccent),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _busy ? null : (connected ? _disconnect : _connect),
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(connected ? '断开连接' : '连接'),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            kIsWeb
                ? 'Chrome + MuMu 临时测试：\n'
                    '1. MuMu 打开「作为显示端」，记下配对码\n'
                    '2. 电脑执行：adb -s 127.0.0.1:16384 forward tcp:17890 tcp:17890\n'
                    '3. 本页 IP 填 127.0.0.1，配对码照抄\n'
                    '4. 点连接（最多约 12 秒，超时会提示失败）'
                : '1. 显示端打开「我的 → 作为显示端」\n'
                    '2. 与显示端同一 Wi‑Fi / 热点\n'
                    '3. 填写显示端 IP 与配对码后连接\n'
                    '4. 连接成功后，点表情只显示在显示端',
            style: AppTextStyles.bodySecondary,
          ),
        ],
      ),
    );
  }
}
