import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pengaturan aplikasi yang disimpan permanen di perangkat.
/// Dipakai oleh: halaman Pengaturan (mengubah), tab Pindai (membaca),
/// dan tab Profil (nama tampilan).
class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  // Tampilan
  ThemeMode themeMode = ThemeMode.system;
  bool amoled = false;

  // Deteksi & kamera
  bool realtime = true; // Deteksi real-time otomatis
  double sensitivity = 75; // 10..100
  int fps = 60; // 30 (hemat baterai) / 60 (super halus)
  bool emojiOverlay = true; // tampilkan bubble emoji di atas kamera

  // Notifikasi
  bool reminder = true;
  int reminderHour = 20;
  int reminderMinute = 0;
  bool haptic = true;

  // Profil
  String? displayName;

  bool _loaded = false;

  static String sensitivityLabel(double v) =>
      v >= 70 ? 'Tinggi & Responsif' : (v >= 40 ? 'Sedang' : 'Rendah');

  /// Jarak antar analisis live. Analisis dikirim ke server, jadi frekuensinya
  /// dibatasi: FPS 60 + sensitivitas tinggi = lebih sering, 30 = hemat baterai.
  Duration get liveInterval {
    final base = fps >= 60 ? 2000 : 4000;
    final factor = 1.5 - (sensitivity - 10) / 90 * 0.9; // 1.5 .. 0.6
    final ms = (base * factor).round().clamp(1200, 6000).toInt();
    return Duration(milliseconds: ms);
  }

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final p = await SharedPreferences.getInstance();
      final t = (p.getInt('set_theme') ?? 0).clamp(0, 2).toInt();
      themeMode = ThemeMode.values[t];
      amoled = p.getBool('set_amoled') ?? amoled;
      realtime = p.getBool('set_realtime') ?? realtime;
      sensitivity = p.getDouble('set_sens') ?? sensitivity;
      fps = p.getInt('set_fps') ?? fps;
      emojiOverlay = p.getBool('set_emoji') ?? emojiOverlay;
      reminder = p.getBool('set_reminder') ?? reminder;
      reminderHour = p.getInt('set_rem_h') ?? reminderHour;
      reminderMinute = p.getInt('set_rem_m') ?? reminderMinute;
      haptic = p.getBool('set_haptic') ?? haptic;
      displayName = p.getString('set_name');
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt('set_theme', themeMode.index);
      await p.setBool('set_amoled', amoled);
      await p.setBool('set_realtime', realtime);
      await p.setDouble('set_sens', sensitivity);
      await p.setInt('set_fps', fps);
      await p.setBool('set_emoji', emojiOverlay);
      await p.setBool('set_reminder', reminder);
      await p.setInt('set_rem_h', reminderHour);
      await p.setInt('set_rem_m', reminderMinute);
      await p.setBool('set_haptic', haptic);
      if (displayName == null) {
        await p.remove('set_name');
      } else {
        await p.setString('set_name', displayName!);
      }
    } catch (_) {}
  }

  /// Terapkan beberapa perubahan sekaligus (dipanggil tombol "Simpan Perubahan").
  Future<void> apply({
    ThemeMode? themeMode,
    bool? amoled,
    bool? realtime,
    double? sensitivity,
    int? fps,
    bool? emojiOverlay,
    bool? reminder,
    int? reminderHour,
    int? reminderMinute,
    bool? haptic,
  }) async {
    this.themeMode = themeMode ?? this.themeMode;
    this.amoled = amoled ?? this.amoled;
    this.realtime = realtime ?? this.realtime;
    this.sensitivity = sensitivity ?? this.sensitivity;
    this.fps = fps ?? this.fps;
    this.emojiOverlay = emojiOverlay ?? this.emojiOverlay;
    this.reminder = reminder ?? this.reminder;
    this.reminderHour = reminderHour ?? this.reminderHour;
    this.reminderMinute = reminderMinute ?? this.reminderMinute;
    this.haptic = haptic ?? this.haptic;
    notifyListeners();
    await _save();
  }

  Future<void> setDisplayName(String? name) async {
    final n = name?.trim();
    displayName = (n == null || n.isEmpty) ? null : n;
    notifyListeners();
    await _save();
  }
}