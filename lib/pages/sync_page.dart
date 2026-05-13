import 'dart:math';

import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import '../services/sync_service.dart';
import '../widgets/common.dart';

class SyncPage extends StatefulWidget {
  final Future<void> Function()? onSynced;

  const SyncPage({super.key, this.onSynced});

  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  final _keyCtl = TextEditingController();
  bool _busy = false;
  String? _message;
  Color _messageColor = C.textMuted;

  @override
  void initState() {
    super.initState();
    _loadKey();
  }

  @override
  void dispose() {
    _keyCtl.dispose();
    super.dispose();
  }

  Future<void> _loadKey() async {
    final key = await StorageService.loadSyncKey();
    if (!mounted) return;
    _keyCtl.text = key ?? _newSyncKey();
  }

  String _newSyncKey() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(12, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<void> _push() async {
    await _runSync(() => SyncService.push(_syncKey), '已上传到云端');
  }

  Future<void> _pull() async {
    await _runSync(() => SyncService.pull(_syncKey), '已从云端恢复');
    await widget.onSynced?.call();
  }

  Future<void> _runSync(Future<void> Function() action, String success) async {
    if (!SyncService.isConfigured) {
      _show('先在 config.dart 里填写 syncBaseUrl', C.rose);
      return;
    }
    if (_syncKey.length < 6) {
      _show('同步码至少 6 位', C.rose);
      return;
    }

    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      _show(success, C.green);
    } catch (e) {
      if (!mounted) return;
      _show(e.toString().replaceFirst('Exception: ', ''), C.rose);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String get _syncKey => _keyCtl.text.trim();

  void _show(String text, Color color) {
    setState(() {
      _message = text;
      _messageColor = color;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: C.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '云同步',
          style: TextStyle(
            color: C.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '同步码',
                  style: TextStyle(
                    color: C.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Web 和手机填写同一个同步码，就会使用同一份云端数据。',
                  style: TextStyle(
                    color: C.textMuted,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _keyCtl,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                    color: C.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: C.bg,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: C.green),
                      onPressed: _busy
                          ? null
                          : () => _keyCtl.text = _newSyncKey(),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: C.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: C.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: C.green),
                    ),
                  ),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _message!,
                    style: TextStyle(
                      color: _messageColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _SyncAction(
                  label: '上传',
                  icon: Icons.cloud_upload_rounded,
                  color: C.green,
                  busy: _busy,
                  onTap: _push,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SyncAction(
                  label: '下载',
                  icon: Icons.cloud_download_rounded,
                  color: C.purple,
                  busy: _busy,
                  onTap: _pull,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!SyncService.isConfigured)
            const Text(
              '还没配置云端地址：部署 Cloudflare Worker 后，把地址填到 AppConfig.syncBaseUrl。',
              style: TextStyle(color: C.rose, fontSize: 12, height: 1.5),
            ),
        ],
      ),
    );
  }
}

class _SyncAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool busy;
  final VoidCallback onTap;

  const _SyncAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
