import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../models/scan_item.dart';
import '../viewmodels/scanner_viewmodel.dart';
import '../widgets/ad_banner.dart';

class ScannerView extends StatefulWidget {
  const ScannerView({super.key});

  @override
  State<ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<ScannerView> with SingleTickerProviderStateMixin {
  late final ScannerViewModel vm;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    vm = ScannerViewModel();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    vm.addListener(_onVm);
  }

  void _onVm() {
    // when a new lastScan appears, show result sheet
    if (vm.lastScan != null) {
      HapticFeedback.lightImpact();
      _showResultSheet(vm.lastScan!);
    }
    setState(() {});
  }

  @override
  void dispose() {
    vm.removeListener(_onVm);
    vm.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _showResultSheet(ScanItem item) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (ctx) {
        final parsed = Linkify(
          onOpen: (link) async {
            final url = link.url;
            if (await canLaunchUrlString(url)) {
              await launchUrlString(url);
            }
          },
          text: item.content,
        );

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 6,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(3)),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Result', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                SelectableText(item.content, style: const TextStyle(fontSize: 16), maxLines: 10),
                const SizedBox(height: 12),
                parsed,
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: item.content));
                          if (mounted) Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (_looksLikeOpenable(item.content))
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () async {
                            final url = item.content.trim();
                            if (await canLaunchUrlString(url)) await launchUrlString(url);
                            if (mounted) Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Open'),
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          await vm.resumeScanning();
                          if (mounted) Navigator.of(context).pop();
                        },
                        child: const Text('Scan Again'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );

    // Ensure scanning resumes when sheet closed
    if (mounted) await vm.resumeScanning();
  }

  Future<bool> _canOpen(String s) async {
    final trimmed = s.trim();
    return await canLaunchUrlString(trimmed);
  }

  bool _looksLikeOpenable(String s) {
    final t = s.trim().toLowerCase();
    return t.startsWith('http://') || t.startsWith('https://') || t.startsWith('www.') || t.startsWith('mailto:') || t.startsWith('tel:');
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF9F9F9),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('History', style: Theme.of(context).textTheme.titleLarge),
                    TextButton(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (dctx) => AlertDialog(
                            title: const Text('Clear history?'),
                            content: const Text('This will delete all saved scans.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(dctx).pop(false), child: const Text('Cancel')),
                              TextButton(onPressed: () => Navigator.of(dctx).pop(true), child: const Text('Clear')),
                            ],
                          ),
                        );
                        if (confirm == true) await vm.clearAll();
                      },
                      child: const Text('Clear All'),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: vm.history.isEmpty
                      ? const Center(child: Text('No scans yet'))
                      : ListView.separated(
                          itemCount: vm.history.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (ctx, i) {
                            final it = vm.history[i];
                            return Dismissible(
                              key: ValueKey(it.id),
                              direction: DismissDirection.endToStart,
                              background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.symmetric(horizontal: 20), child: const Icon(Icons.delete, color: Colors.white)),
                              onDismissed: (_) => vm.deleteScan(it.id),
                              child: ListTile(
                                tileColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                                leading: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                                  child: const Icon(Icons.qr_code, color: Color(0xFF007AFF)),
                                ),
                                title: Text(
                                  it.content.length > 60 ? '${it.content.substring(0, 60)}…' : it.content,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(DateFormat.yMMMd().add_jm().format(it.timestamp)),
                                onTap: () async {
                                  Navigator.of(context).pop();
                                  await _showResultSheet(it);
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('QR Scanner'),
        actions: [
          IconButton(
            tooltip: 'History',
            onPressed: _showHistory,
            icon: const Icon(Icons.history_rounded),
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: LayoutBuilder(builder: (context, constraints) {
                  final size = (constraints.maxWidth < constraints.maxHeight ? constraints.maxWidth : constraints.maxHeight) * 0.8;
                  return SizedBox(
                    width: size,
                    height: size,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: MobileScanner(
                            controller: vm.cameraController,
                            fit: BoxFit.cover,
                            onDetect: (capture) async {
                              final barcodes = capture.barcodes;
                              if (barcodes.isNotEmpty) {
                                await vm.processDetection(barcodes.first);
                              }
                            },
                          ),
                        ),
                        // translucent overlay with square frame
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.black.withOpacity(0.12)),
                            ),
                          ),
                        ),
                        // frame border
                        Center(
                          child: ScaleTransition(
                            scale: Tween(begin: 1.0, end: 1.02).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)),
                            child: Container(
                              width: size * 0.86,
                              height: size * 0.86,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.9), width: 2),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6, spreadRadius: 1)],
                              ),
                            ),
                          ),
                        ),
                        // corner accents
                        Center(
                          child: SizedBox(
                            width: size * 0.86,
                            height: size * 0.86,
                            child: CustomPaint(painter: _CornerPainter(color: const Color(0xFF007AFF))),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    iconSize: 36,
                    tooltip: 'Toggle flashlight',
                    onPressed: () async {
                      await vm.cameraController.toggleTorch();
                      setState(() {});
                    },
                    icon: Icon(vm.cameraController.torchState.value == TorchState.on ? Icons.flashlight_on : Icons.flashlight_off),
                  ),
                ],
              ),
            ),
            // Banner ad at bottom
            const SafeArea(child: Center(child: AdBannerWidget())),
          ],
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  _CornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    const cornerLen = 22.0;
    // top-left
    canvas.drawLine(const Offset(8, 8), Offset(8 + cornerLen, 8), paint);
    canvas.drawLine(const Offset(8, 8), Offset(8, 8 + cornerLen), paint);
    // top-right
    canvas.drawLine(Offset(size.width - 8, 8), Offset(size.width - 8 - cornerLen, 8), paint);
    canvas.drawLine(Offset(size.width - 8, 8), Offset(size.width - 8, 8 + cornerLen), paint);
    // bottom-left
    canvas.drawLine(Offset(8, size.height - 8), Offset(8 + cornerLen, size.height - 8), paint);
    canvas.drawLine(Offset(8, size.height - 8), Offset(8, size.height - 8 - cornerLen), paint);
    // bottom-right
    canvas.drawLine(Offset(size.width - 8, size.height - 8), Offset(size.width - 8 - cornerLen, size.height - 8), paint);
    canvas.drawLine(Offset(size.width - 8, size.height - 8), Offset(size.width - 8, size.height - 8 - cornerLen), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
