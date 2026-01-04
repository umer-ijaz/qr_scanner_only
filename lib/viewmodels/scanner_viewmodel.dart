import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/scan_item.dart';
import '../services/storage_service.dart';

class ScannerViewModel extends ChangeNotifier {
  final StorageService _storage;
  final MobileScannerController cameraController;

  bool _processing = false;
  ScanItem? lastScan;
  List<ScanItem> history = [];

  ScannerViewModel({StorageService? storage})
      : _storage = storage ?? StorageService(),
        cameraController = MobileScannerController(
          facing: CameraFacing.back,
          torchEnabled: false,
          detectionSpeed: DetectionSpeed.noDuplicates,
        ) {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    history = await _storage.loadHistory();
    notifyListeners();
  }

  Future<void> processDetection(Barcode barcode) async {
    if (_processing) return;
    final raw = barcode.rawValue ?? '';
    if (raw.isEmpty) return;
    _processing = true;

    await cameraController.stop();

    final item = ScanItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: raw,
      timestamp: DateTime.now(),
      type: barcode.type.name,
    );

    // Save (storage prevents exact immediate duplicates)
    await _storage.saveScan(item);
    // refresh local history
    history = await _storage.loadHistory();
    lastScan = item;
    notifyListeners();
  }

  Future<void> resumeScanning() async {
    lastScan = null;
    _processing = false;
    await cameraController.start();
    notifyListeners();
  }

  Future<void> deleteScan(String id) async {
    await _storage.deleteScan(id);
    history = await _storage.loadHistory();
    notifyListeners();
  }

  Future<void> clearAll() async {
    await _storage.clearAll();
    history = [];
    notifyListeners();
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}
