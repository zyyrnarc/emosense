import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/app_settings.dart';

// ───────────────────────── Warna & gaya ─────────────────────────
class _C {
  static const surface = Color(0xFFFAF8FF);
  static const onSurface = Color(0xFF131B2E);
  static const onSurfaceVariant = Color(0xFF434655);
  static const outline = Color(0xFF737686);
  static const primary = Color(0xFF004AC6);
  static const primaryContainer = Color(0xFF2563EB);
  static const onPrimary = Color(0xFFFFFFFF);
  static const secondary = Color(0xFF006C49);
  static const secondaryContainer = Color(0xFF6CF8BB);
  static const onSecondaryContainer = Color(0xFF00714D);
  static const tertiary = Color(0xFF784B00);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);
  static const white = Color(0xFFFFFFFF);
  static const surfaceContainer = Color(0xFFEAEDFF);
  static const containerLow = Color(0xFFF2F3FF);
  static const containerHigh = Color(0xFFE2E7FF);
  static const containerHighest = Color(0xFFDAE2FD);
}

TextStyle _t(double size, double line, FontWeight w, Color c,
        {double ls = 0}) =>
    GoogleFonts.plusJakartaSans(
      fontSize: size,
      height: line / size,
      fontWeight: w,
      color: c,
      letterSpacing: ls,
    );

final List<BoxShadow> _shadowSm = [
  BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 2,
      offset: const Offset(0, 1)),
];
final List<BoxShadow> _shadowMd = [
  BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 8,
      spreadRadius: -1,
      offset: const Offset(0, 3)),
];

String _fmtBytes(int b) {
  if (b < 1024) return '$b B';
  if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
  return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
}

// ───────────────────────── Halaman Pengaturan ─────────────────────────
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Salinan sementara; baru berlaku saat "Simpan Perubahan" ditekan.
  late ThemeMode _theme;
  late bool _amoled, _realtime, _emoji, _reminder, _haptic;
  late double _sens;
  late int _fps, _hour, _minute;

  bool _saving = false;
  bool _saved = false;
  bool _clearing = false;
  String _cacheSize = 'menghitung...';

  @override
  void initState() {
    super.initState();
    final s = AppSettings.instance;
    _theme = s.themeMode;
    _amoled = s.amoled;
    _realtime = s.realtime;
    _emoji = s.emojiOverlay;
    _reminder = s.reminder;
    _haptic = s.haptic;
    _sens = s.sensitivity;
    _fps = s.fps;
    _hour = s.reminderHour;
    _minute = s.reminderMinute;
    _loadCache();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 2600),
      ));
  }

  // ── Cache ──
  Future<void> _loadCache() async {
    var total = 0;
    try {
      final d = await getTemporaryDirectory();
      if (await d.exists()) {
        await for (final e in d.list(recursive: true, followLinks: false)) {
          if (e is File) {
            try {
              total += await e.length();
            } catch (_) {}
          }
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _cacheSize = _fmtBytes(total));
  }

  Future<void> _clearCache() async {
    setState(() => _clearing = true);
    try {
      final d = await getTemporaryDirectory();
      if (await d.exists()) {
        await for (final e in d.list(followLinks: false)) {
          try {
            await e.delete(recursive: true);
          } catch (_) {}
        }
      }
    } catch (_) {}
    await _loadCache();
    if (!mounted) return;
    setState(() => _clearing = false);
    _toast('Cache lokal berhasil dikosongkan');
  }

  // ── Simpan ──
  Future<void> _save() async {
    setState(() => _saving = true);
    await AppSettings.instance.apply(
      themeMode: _theme,
      amoled: _amoled,
      realtime: _realtime,
      sensitivity: _sens,
      fps: _fps,
      emojiOverlay: _emoji,
      reminder: _reminder,
      reminderHour: _hour,
      reminderMinute: _minute,
      haptic: _haptic,
    );
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      _saving = false;
      _saved = true;
    });
    _toast('Semua preferensi AI berhasil disimpan!');
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _saved = false);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hour, minute: _minute),
    );
    if (t == null) return;
    setState(() {
      _hour = t.hour;
      _minute = t.minute;
    });
  }

  String get _timeLabel =>
      '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}';

  // ───────────── UI ─────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.surface,
      appBar: AppBar(
        backgroundColor: _C.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 64,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _C.onSurface),
          tooltip: 'Kembali',
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('SENSIO AI',
                style: _t(11, 14, FontWeight.w600, _C.primary, ls: 0.8)),
            Text('Pengaturan Sensor & Privasi',
                style: _t(17, 24, FontWeight.w700, _C.onSurface)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                  color: _C.primary, shape: BoxShape.circle),
              child: const Icon(Icons.person, size: 18, color: _C.onPrimary),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _intro(),
            const SizedBox(height: 8),
            _infoCard(),
            const SizedBox(height: 24),
            _themeGroup(),
            const SizedBox(height: 24),
            _detectionGroup(),
            const SizedBox(height: 24),
            _privacyGroup(),
            const SizedBox(height: 24),
            _notifGroup(),
            const SizedBox(height: 24),
            _saveButton(),
          ],
        ),
      ),
    );
  }

  Widget _intro() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('KONFIGURASI PENGGUNA',
                  style: _t(11, 14, FontWeight.w700, _C.primary, ls: 0.8)),
              Text('Pengaturan & Preferensi',
                  style: _t(22, 30, FontWeight.w700, _C.onSurface)),
            ],
          ),
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: _C.surfaceContainer,
              shape: BoxShape.circle,
              boxShadow: _shadowSm),
          child: const Icon(Icons.tune, size: 22, color: _C.primary),
        ),
      ],
    );
  }

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.primaryContainer.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: _C.primaryContainer,
                borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.smart_toy, size: 20, color: _C.onPrimary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pengenalan 7 Ekspresi Aktif',
                    style: _t(12, 16, FontWeight.w700, _C.primary)),
                const SizedBox(height: 2),
                Text(
                    'Sensio AI mengenali bahagia, netral, terkejut, sedih, marah, takut, dan jijik dari wajah di kamera.',
                    style: _t(12, 16, FontWeight.w400, _C.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Grup 1: Tampilan & tema ──
  Widget _themeGroup() {
    const modes = [ThemeMode.light, ThemeMode.dark, ThemeMode.system];
    return _group(
      icon: Icons.palette,
      color: _C.primary,
      title: 'Tampilan & Tema Aplikasi',
      rows: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tema Antarmuka',
                    style: _t(14, 20, FontWeight.w600, _C.onSurface)),
                if (_theme == ThemeMode.system)
                  _pill('Otomatis Aktif', _C.containerHighest, _C.primary),
              ],
            ),
            const SizedBox(height: 4),
            Text(
                'Pilih skema warna antarmuka untuk kenyamanan mata Anda saat mendeteksi ekspresi.',
                style: _t(12, 16, FontWeight.w400, _C.onSurfaceVariant)),
            const SizedBox(height: 12),
            _segmented(
              const [
                _Seg('Terang', 'Light Mode', Icons.light_mode),
                _Seg('Gelap', 'Dark Mode', Icons.dark_mode),
                _Seg('Sistem', 'Otomatis', Icons.settings_brightness),
              ],
              modes.indexOf(_theme),
              (i) => setState(() => _theme = modes[i]),
            ),
          ],
        ),
        _toggleRow(
          title: 'Kontras Tinggi & Mode Gelap Murni',
          desc:
              'Mengoptimalkan warna hitam pekat untuk layar OLED guna menghemat daya pemindaian kamera.',
          value: _amoled,
          onChanged: (v) => setState(() => _amoled = v),
        ),
      ],
    );
  }

  // ── Grup 2: Deteksi & kamera ──
  Widget _detectionGroup() {
    return _group(
      icon: Icons.videocam,
      color: _C.primary,
      title: 'Konfigurasi Deteksi & Kamera AI',
      rows: [
        _toggleRow(
          title: 'Deteksi Real-Time Otomatis',
          desc:
              'Kamera memindai dan mengenali ekspresi wajah secara instan saat layar pemindai terbuka.',
          value: _realtime,
          onChanged: (v) => setState(() => _realtime = v),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text('Sensitivitas Analisis Ekspresi',
                      style: _t(14, 20, FontWeight.w600, _C.onSurface)),
                ),
                const SizedBox(width: 8),
                _pill(
                  '${_sens.round()}% (${AppSettings.sensitivityLabel(_sens)})',
                  _sens >= 70
                      ? _C.secondaryContainer
                      : (_sens >= 40 ? _C.containerHigh : _C.containerHighest),
                  _sens >= 70 ? _C.onSecondaryContainer : _C.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
                'Menentukan seberapa sering Sensio AI menganalisis ulang wajah di kamera.',
                style: _t(12, 16, FontWeight.w400, _C.onSurfaceVariant)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.speed, size: 16, color: _C.outline),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 6,
                      activeTrackColor: _C.primary,
                      inactiveTrackColor: _C.containerHigh,
                      thumbColor: _C.primary,
                      overlayColor: _C.primary.withOpacity(0.12),
                    ),
                    child: Slider(
                      min: 10,
                      max: 100,
                      value: _sens,
                      onChanged: (v) => setState(() => _sens = v),
                    ),
                  ),
                ),
                const Icon(Icons.bolt, size: 18, color: _C.primary),
              ],
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Target Frame Rate (FPS)',
                    style: _t(14, 20, FontWeight.w600, _C.onSurface)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome, size: 14, color: _C.primary),
                    const SizedBox(width: 4),
                    Text('60 Direkomendasikan',
                        style: _t(11, 14, FontWeight.w600, _C.primary)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
                'FPS lebih tinggi membuat pelacakan emosi lebih sering diperbarui, tetapi lebih boros baterai dan data.',
                style: _t(12, 16, FontWeight.w400, _C.onSurfaceVariant)),
            const SizedBox(height: 8),
            _segmented(
              const [
                _Seg('30 FPS', 'Hemat Baterai'),
                _Seg('60 FPS', 'Super Halus'),
              ],
              _fps >= 60 ? 1 : 0,
              (i) => setState(() => _fps = i == 1 ? 60 : 30),
            ),
          ],
        ),
        _toggleRow(
          title: 'Konversi Otomatis ke Emoji Wajah',
          desc:
              'Tampilkan avatar ekspresi interaktif (😊, 😮, 🤔) secara real-time di atas kamera.',
          value: _emoji,
          onChanged: (v) => setState(() => _emoji = v),
        ),
      ],
    );
  }

  // ── Grup 3: Privasi ──
  Widget _privacyGroup() {
    return _group(
      icon: Icons.security,
      color: _C.secondary,
      title: 'Privasi & Data Wajah',
      rows: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text('Riwayat Disimpan di Perangkat',
                            style: _t(14, 20, FontWeight.w600, _C.onSurface)),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.verified_user,
                          size: 16, color: _C.secondary),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                      'Foto dan hasil pindaian tersimpan hanya di ponsel Anda. Saat dianalisis, foto dikirim ke server Sensio AI untuk dikenali ekspresinya.',
                      style: _t(12, 16, FontWeight.w400, _C.onSurfaceVariant)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            const _Toggle(value: true, onColor: _C.secondary, locked: true),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cache Foto Sementara',
                      style: _t(14, 20, FontWeight.w600, _C.onSurface)),
                  const SizedBox(height: 2),
                  Text(
                      'Hapus file sementara hasil jepretan dan ekspor ($_cacheSize tersimpan). Riwayat Anda tidak ikut terhapus.',
                      style: _t(12, 16, FontWeight.w400, _C.onSurfaceVariant)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Material(
              color: _C.errorContainer,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: _clearing ? null : _clearCache,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _clearing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _C.onErrorContainer))
                          : const Icon(Icons.delete_sweep,
                              size: 16, color: _C.onErrorContainer),
                      const SizedBox(width: 6),
                      Text(_clearing ? 'Menghapus...' : 'Hapus Cache',
                          style:
                              _t(12, 16, FontWeight.w600, _C.onErrorContainer)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Grup 4: Notifikasi ──
  Widget _notifGroup() {
    return _group(
      icon: Icons.notifications_active,
      color: _C.tertiary,
      title: 'Notifikasi & Pengingat Harian',
      rows: [
        _toggleRow(
          title: 'Pengingat Cek Mood Harian',
          badge: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: _pickTime,
            child: _pill(_timeLabel, _C.containerHighest, _C.primary),
          ),
          desc:
              'Dorongan positif di malam hari untuk mencatat evaluasi perasaan dan kebugaran mental.',
          value: _reminder,
          onChanged: (v) => setState(() => _reminder = v),
        ),
        _toggleRow(
          title: 'Suara Deteksi & Getaran Haptik',
          desc:
              'Umpan balik getar lembut ketika wajah berhasil teridentifikasi di kamera.',
          value: _haptic,
          onChanged: (v) => setState(() => _haptic = v),
        ),
      ],
    );
  }

  Widget _saveButton() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                    color: _C.primaryContainer.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Material(
              color: _C.primaryContainer,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: (_saving || _saved) ? null : _save,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: _C.onPrimary))
                          : Icon(_saved ? Icons.check_circle : Icons.save,
                              size: 20, color: _C.onPrimary),
                      const SizedBox(width: 8),
                      Text(
                          _saving
                              ? 'Menerapkan...'
                              : (_saved ? 'Tersimpan!' : 'Simpan Perubahan'),
                          style: _t(14, 20, FontWeight.w600, _C.onPrimary)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text('Setelan diterapkan ke pemindai kamera setelah disimpan.',
            textAlign: TextAlign.center,
            style: _t(12, 16, FontWeight.w400, _C.onSurfaceVariant)),
      ],
    );
  }

  // ───────────── Komponen ─────────────
  Widget _pill(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: _t(11, 16, FontWeight.w700, fg)),
    );
  }

  Widget _group({
    required IconData icon,
    required Color color,
    required String title,
    required List<Widget> rows,
  }) {
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      if (i > 0) {
        children
          ..add(const SizedBox(height: 16))
          ..add(Container(height: 1, color: _C.containerHigh))
          ..add(const SizedBox(height: 16));
      }
      children.add(rows[i]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(title.toUpperCase(),
                    style:
                        _t(13, 20, FontWeight.w700, _C.onSurface, ls: 0.4)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _C.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: _shadowMd,
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: children),
        ),
      ],
    );
  }

  Widget _toggleRow({
    required String title,
    required String desc,
    required bool value,
    required ValueChanged<bool> onChanged,
    Widget? badge,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(title, style: _t(14, 20, FontWeight.w600, _C.onSurface)),
                  if (badge != null) badge,
                ],
              ),
              const SizedBox(height: 2),
              Text(desc,
                  style: _t(12, 16, FontWeight.w400, _C.onSurfaceVariant)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        _Toggle(value: value, onChanged: onChanged),
      ],
    );
  }

  Widget _segmented(
      List<_Seg> options, int selected, ValueChanged<int> onSelect) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: _C.containerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelect(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  decoration: BoxDecoration(
                    color: selected == i ? _C.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: selected == i ? _shadowSm : null,
                  ),
                  child: Column(
                    children: [
                      if (options[i].icon != null) ...[
                        Icon(options[i].icon,
                            size: 20,
                            color: selected == i
                                ? _C.primary
                                : _C.onSurfaceVariant),
                        const SizedBox(height: 4),
                      ],
                      Text(options[i].label,
                          style: _t(
                              12,
                              16,
                              selected == i ? FontWeight.w700 : FontWeight.w600,
                              selected == i ? _C.primary : _C.onSurfaceVariant)),
                      Text(options[i].sub,
                          style: _t(
                              10,
                              14,
                              FontWeight.w600,
                              selected == i
                                  ? _C.secondary
                                  : _C.onSurfaceVariant.withOpacity(0.8))),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Seg {
  final String label, sub;
  final IconData? icon;
  const _Seg(this.label, this.sub, [this.icon]);
}

/// Tombol on/off sesuai desain (48×28).
class _Toggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color onColor;
  final bool locked;
  const _Toggle({
    required this.value,
    this.onChanged,
    this.onColor = _C.primaryContainer,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      child: GestureDetector(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 48,
          height: 28,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: value ? onColor : _C.containerHighest,
            borderRadius: BorderRadius.circular(999),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: _C.white,
                shape: BoxShape.circle,
                boxShadow: _shadowSm,
              ),
              child: locked
                  ? Icon(Icons.lock, size: 12, color: onColor)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}