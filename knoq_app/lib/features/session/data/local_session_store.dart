import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:knoq_app/features/ble/domain/shot_data.dart';

class LocalSessionStore {
  static const _boxName = 'active_session';
  Box? _box;

  /// Opens the Hive box. Safe to call multiple times.
  Future<void> init() async {
    _box ??= await Hive.openBox(_boxName);
  }

  Box get _safeBox {
    if (_box == null || !_box!.isOpen) {
      // Fallback: try to get already-opened box
      _box = Hive.box(_boxName);
    }
    return _box!;
  }

  Future<void> startSession(Map<String, dynamic> metadata) async {
    final box = _safeBox;
    await box.clear();
    await box.put('is_active', true);
    await box.put('metadata', json.encode(metadata));
    await box.put('shots', <String>[]);
  }

  Future<void> addShot(ShotData shot) async {
    final box = _safeBox;
    // Write-Ahead rule (<1ms writes via Hive list append)
    final rawShots = List<String>.from(
      box.get('shots', defaultValue: <String>[]) as List
    );
    final shotJson = json.encode({
      'hit': shot.hit,
      'zone': shot.zone,
      'power': shot.power,
      'swing': shot.swing,
      'sweetPct': shot.sweetPct,
      'avgPower': shot.avgPower,
      'totalHits': shot.totalHits,
    });
    rawShots.add(shotJson);
    await box.put('shots', rawShots);
  }

  Future<void> endSession() async {
    await _safeBox.put('is_active', false);
  }

  bool hasActiveSession() {
    try {
      return _safeBox.get('is_active', defaultValue: false) as bool;
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic>? recoverSession() {
    if (!hasActiveSession()) return null;
    
    final box = _safeBox;
    final metadataString = box.get('metadata') as String?;
    final shotsRaw = box.get('shots', defaultValue: <String>[]) as List;

    if (metadataString == null) return null;

    final metadata = json.decode(metadataString) as Map<String, dynamic>;
    final shots = <ShotData>[];
    
    for (final s in shotsRaw) {
      try {
        shots.add(ShotData.fromJson(json.decode(s as String)));
      } catch (_) {
        // Skip corrupted entries gracefully
      }
    }

    return {
       'metadata': metadata,
       'shots': shots,
    };
  }

  Future<void> clearSession() async {
    await _safeBox.clear();
  }
}
