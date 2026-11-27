import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/routers/app_routers.dart';
import '../../../data/stores/auth_store.dart';
import '../../../core/app_settings.dart';
import '../../../data/service/emotion_service.dart';
import 'history_user.dart';
import 'profile_user.dart';
import 'settings_user.dart';

// ───────────────────────── Warna & gaya ─────────────────────────
class _C {
  static const surface = Color(0xFFFAF8FF);
  static const onSurface = Color(0xFF131B2E);
  static const onSurfaceVariant = Color(0xFF434655);
  static const primary = Color(0xFF004AC6);
  static const primaryContainer = Color(0xFF2563EB);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryFixed = Color(0xFFDBE1FF);
  static const secondary = Color(0xFF006C49);
  static const secondaryContainer = Color(0xFF6CF8BB);
  static const onSecondaryFixedVariant = Color(0xFF005236);
  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);
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
      color: Colors.black.withOpacity(0.10),
      blurRadius: 6,
      spreadRadius: -1,
      offset: const Offset(0, 4)),
  BoxShadow(
      color: Colors.black.withOpacity(0.10),
      blurRadius: 4,
      spreadRadius: -2,
      offset: const Offset(0, 2)),
];
final List<BoxShadow> _shadowLg = [
  BoxShadow(
      color: Colors.black.withOpacity(0.10),
      blurRadius: 15,
      spreadRadius: -3,
      offset: const Offset(0, 10)),
  BoxShadow(
      color: Colors.black.withOpacity(0.10),
      blurRadius: 6,
      spreadRadius: -4,
      offset: const Offset(0, 4)),
];

// ───────────────────────── Halaman Home ─────────────────────────
class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key, required this.user});

  final UserAccount user;

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    HistoryStore.instance.load();
    AppSettings.instance.load();
  }

  Future<void> _logout() async {
    await AuthStore.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.welcome, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.surface,
      body: Column(
        children: [
          const _TopBar(),
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: [
                _ScanTab(active: _tab == 0),
                const HistoryTab(),
                ProfileTab(user: widget.user, onLogout: _logout),
                const SettingsPage(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        index: _tab,
        onTap: (i) => setState(() => _tab = i),
      ),
    );
  }
}

// ───────────────────────── Header ─────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 1)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _C.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: _C.primary.withOpacity(0.25),
                              blurRadius: 12,
                              spreadRadius: -2,
                              offset: const Offset(0, 4)),
                        ],
                      ),
                      child: const Icon(Icons.psychology,
                          size: 20, color: _C.onPrimary),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sensio AI',
                            style: _t(20, 24, FontWeight.w700, _C.onSurface,
                                ls: -0.5)),
                        Row(
                          children: [
                            const _Ping(size: 8, color: _C.secondary),
                            const SizedBox(width: 6),
                            Text('AI Online',
                                style:
                                    _t(11, 14, FontWeight.w600, _C.secondary)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                      color: _C.primary, shape: BoxShape.circle),
                  child:
                      const Icon(Icons.person, size: 18, color: _C.onPrimary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Navigasi bawah ─────────────────────────
class _BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.index, required this.onTap});

  Widget _item(int i, IconData icon, String label) {
    final active = index == i;
    final color = active ? _C.primaryContainer : _C.onSurfaceVariant;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(i),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(height: 2),
              Text(label,
                  style: _t(12, 16, active ? FontWeight.w700 : FontWeight.w600,
                      color)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF0F172A).withOpacity(0.05),
              blurRadius: 20,
              spreadRadius: -2,
              offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _item(0, Icons.photo_camera, 'Pindai'),
                _item(1, Icons.bar_chart, 'Riwayat'),
                _item(2, Icons.account_circle, 'Profil'),
                _item(3, Icons.settings, 'Pengaturan'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Tab Pindai ─────────────────────────
class _ScanTab extends StatefulWidget {
  final bool active; // true saat tab Pindai sedang dibuka
  const _ScanTab({required this.active});

  @override
  State<_ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends State<_ScanTab> with WidgetsBindingObserver {
  // kamera
  CameraController? _cam;
  List<CameraDescription> _cameras = [];
  int _camIndex = 0;
  bool _initializing = true;
  String? _camError;

  // deteksi
  Timer? _liveTimer;
  bool _busy = false; // sedang memanggil API (live / manual)
  bool _loading = false; // tampilkan spinner (hanya untuk aksi manual)
  bool _live = true; // Live Deteksi AI aktif
  bool _liveError = false; // server tidak terjangkau
  bool _noFace = false; // wajah tidak terdeteksi pada frame terakhir
  EmotionResult? _result;
  String? _historyId; // id riwayat untuk hasil saat ini
  File? _frozen; // foto dari galeri yang sedang ditampilkan

  // UI
  bool _flashOn = false;
  bool _showGuide = true;
  bool _shutterDown = false;
  double _camTurns = 0;
  bool? _vote;
  final GlobalKey _cardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
    _live = AppSettings.instance.realtime;
    AppSettings.instance.addListener(_onSettings);
    _restartLiveTimer();
  }

  @override
  void dispose() {
    AppSettings.instance.removeListener(_onSettings);
    _liveTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _cam?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      final c = _cam;
      if (c == null) return;
      setState(() => _cam = null);
      c.dispose();
    } else if (state == AppLifecycleState.resumed && _cam == null) {
      _initCamera(_camIndex);
    }
  }

  void _restartLiveTimer() {
    _liveTimer?.cancel();
    _liveTimer = Timer.periodic(
        AppSettings.instance.liveInterval, (_) => _liveTick());
  }

  void _onSettings() {
    if (!mounted) return;
    setState(() => _live = AppSettings.instance.realtime);
    _restartLiveTimer();
  }

  // ── Kamera ──
  Future<void> _initCamera([int? index]) async {
    setState(() {
      _initializing = true;
      _camError = null;
    });

    final old = _cam;
    if (old != null) {
      setState(() => _cam = null);
      await old.dispose();
    }

    try {
      if (_cameras.isEmpty) _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw CameraException('NoCamera', 'Kamera tidak ditemukan');
      }

      if (index == null) {
        final front = _cameras
            .indexWhere((c) => c.lensDirection == CameraLensDirection.front);
        _camIndex = front >= 0 ? front : 0;
      } else {
        _camIndex = index;
      }

      final controller = CameraController(
        _cameras[_camIndex],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.jpeg
            : ImageFormatGroup.bgra8888,
      );
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _cam = controller;
        _initializing = false;
      });
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _camError = (e.code == 'CameraAccessDenied' ||
                e.code == 'CameraAccessDeniedWithoutPrompt' ||
                e.code == 'CameraAccessRestricted')
            ? 'Izin kamera ditolak. Aktifkan di Pengaturan perangkat.'
            : 'Kamera tidak bisa dibuka (${e.code}).';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _camError = 'Kamera belum tersedia. Periksa izin kamera perangkat lalu coba lagi.';
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) {
      _soon('Perangkat hanya memiliki satu kamera');
      return;
    }
    setState(() => _camTurns += 0.5);
    await _initCamera((_camIndex + 1) % _cameras.length);
  }

  void _soon(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Live Deteksi AI: ambil frame tiap 3 detik lalu kirim ke API ──
  Future<void> _liveTick() async {
    final c = _cam;
    if (!_live || _busy || !widget.active || _frozen != null) return;
    if (_result?.corrected == true) return; // hormati koreksi manual
    if (c == null || !c.value.isInitialized || c.value.isTakingPicture) return;

    _busy = true;
    File? f;
    try {
      final x = await c.takePicture();
      f = File(x.path);
      final r = await EmotionApi.predict(f);
      if (!mounted) return;
      final foundNow = r != null && (_noFace || _result == null);
      setState(() {
        _liveError = false;
        if (r == null) {
          _noFace = true;
        } else {
          _noFace = false;
          if (_result?.key != r.key) _vote = null;
          _result = r;
          _historyId = null; // hasil live tidak masuk riwayat
        }
      });
      if (foundNow && AppSettings.instance.haptic) {
        HapticFeedback.selectionClick();
      }
    } catch (_) {
      if (mounted) setState(() => _liveError = true);
    } finally {
      _busy = false;
      try {
        await f?.delete();
      } catch (_) {}
    }
  }

  // ── Analisis manual (rana / galeri) → disimpan ke riwayat ──
  Future<void> _analyze(File f) async {
    setState(() {
      _busy = true;
      _loading = true;
    });
    try {
      final r = await EmotionApi.predict(f);
      if (!mounted) return;
      if (r == null) {
        setState(() => _noFace = true);
        _soon('Wajah tidak terdeteksi, coba lagi');
        return;
      }
      final item = await HistoryStore.instance.add(r, f);
      if (!mounted) return;
      setState(() {
        _result = r;
        _noFace = false;
        _liveError = false;
        _historyId = item.id;
        _vote = null;
      });
    } catch (_) {
      _soon('Gagal terhubung ke server');
    } finally {
      _busy = false;
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pressShutter() async {
    final c = _cam;
    if (c == null || !c.value.isInitialized) {
      _soon('Kamera belum siap');
      return;
    }
    if (_busy || c.value.isTakingPicture) {
      _soon('Sedang menganalisis…');
      return;
    }
    setState(() {
      _shutterDown = true;
      _frozen = null;
    });
    if (AppSettings.instance.haptic) HapticFeedback.lightImpact();
    try {
      try {
        await c.setFlashMode(_flashOn ? FlashMode.always : FlashMode.off);
      } catch (_) {} // kamera depan umumnya tanpa flash
      final x = await c.takePicture();
      try {
        await c.setFlashMode(FlashMode.off);
      } catch (_) {}
      await _analyze(File(x.path));
    } on CameraException catch (e) {
      _soon('Gagal mengambil foto (${e.code})');
    } finally {
      await Future.delayed(const Duration(milliseconds: 150));
      if (mounted) setState(() => _shutterDown = false);
    }
  }

  Future<void> _pickFromGallery() async {
    if (_busy) {
      _soon('Sedang menganalisis…');
      return;
    }
    try {
      final x = await ImagePicker()
          .pickImage(source: ImageSource.gallery, imageQuality: 90);
      if (x == null) return;
      final f = File(x.path);
      setState(() => _frozen = f);
      await _analyze(f);
    } catch (_) {
      _soon('Tidak bisa membuka galeri');
    }
  }

  // ── Umpan balik, koreksi, bagikan ──
  void _sendVote(bool ok) {
    final r = _result;
    if (r == null) return;
    setState(() => _vote = ok);
    EmotionApi.sendFeedback(predicted: r.key, correct: ok);
  }

  Future<void> _manualCorrection() async {
    final r = _result;
    if (r == null) {
      _soon('Belum ada hasil untuk dikoreksi');
      return;
    }
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _C.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ekspresi yang benar?',
                  style: _t(16, 22, FontWeight.w700, _C.onSurface)),
              const SizedBox(height: 4),
              Text('Pilih ekspresi yang sesuai dengan wajahmu.',
                  style: _t(12, 16, FontWeight.w400, _C.onSurfaceVariant)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in allEmotions)
                    InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => Navigator.pop(context, m.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: m.key == r.key
                              ? _C.primaryFixed
                              : _C.containerLow,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(m.emoji, style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 6),
                            Text(m.label,
                                style: _t(12, 16, FontWeight.w600,
                                    _C.onSurface)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (picked == null || !mounted) return;

    setState(() {
      _result = EmotionResult(
        key: picked,
        confidence: 100,
        personName: r.personName,
        corrected: true,
      );
      _vote = false;
    });
    final id = _historyId;
    if (id != null) HistoryStore.instance.relabel(id, picked);
    EmotionApi.sendFeedback(
        predicted: r.key, correct: false, corrected: picked);
    _soon('Koreksi tersimpan, terima kasih!');
  }

  Future<void> _shareResult() async {
    final r = _result;
    if (r == null) {
      _soon('Belum ada hasil untuk dibagikan');
      return;
    }
    try {
      final m = emotionMeta(r.key);
      final f = await ShareHelper.captureBoundary(_cardKey);
      await ShareHelper.shareFile(
          f,
          'Suasana hatiku hari ini: ${m.emoji} ${m.title}'
          '${r.corrected ? '' : ' (${r.confidence}%)'} — Sensio AI');
    } catch (_) {
      _soon('Gagal membagikan hasil');
    }
  }

  Future<void> _shareSticker() async {
    final r = _result;
    if (r == null) {
      _soon('Belum ada hasil untuk dijadikan stiker');
      return;
    }
    try {
      final m = emotionMeta(r.key);
      final f = await ShareHelper.emojiSticker(m.emoji);
      await ShareHelper.shareFile(f, 'Stiker ${m.title} dari Sensio AI');
    } catch (_) {
      _soon('Gagal membuat stiker');
    }
  }

  // ───────────── UI ─────────────
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _viewfinder(),
          const SizedBox(height: 24),
          _resultCard(),
          const SizedBox(height: 24),
          _actions(),
        ],
      ),
    );
  }

  Widget _cameraLayer() {
    final frozen = _frozen;
    if (frozen != null) {
      return Image.file(frozen, fit: BoxFit.cover);
    }
    final c = _cam;
    if (c != null && c.value.isInitialized) {
      final size = c.value.previewSize!;
      return ClipRect(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: size.height, // previewSize dalam landscape
            height: size.width,
            child: CameraPreview(c),
          ),
        ),
      );
    }
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_C.containerHighest, _C.primaryFixed],
        ),
      ),
      child: Center(
        child: _initializing
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.videocam_off,
                        size: 48, color: _C.onSurfaceVariant),
                    const SizedBox(height: 8),
                    Text(_camError ?? 'Kamera tidak tersedia',
                        textAlign: TextAlign.center,
                        style:
                            _t(12, 16, FontWeight.w500, _C.onSurfaceVariant)),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => _initCamera(),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _viewfinder() {
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: _C.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          boxShadow: _shadowMd,
        ),
        child: Stack(
          children: [
            Positioned.fill(child: _cameraLayer()),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      _C.onSurface.withOpacity(0.4),
                      Colors.transparent,
                      _C.onSurface.withOpacity(0.2),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _viewfinderTop(),
                  Expanded(
                    child: Center(
                      child: _showGuide
                          ? FittedBox(
                              fit: BoxFit.scaleDown,
                              child: SizedBox(
                                width: 208,
                                height: 256,
                                child: _faceGuide(),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                  _nameplate(),
                  const SizedBox(height: 8),
                  _viewfinderBottom(),
                ],
              ),
            ),
            if (_loading)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black26,
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _viewfinderTop() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _C.surface.withOpacity(0.9),
            borderRadius: BorderRadius.circular(999),
            boxShadow: _shadowSm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _Ping(size: 8, color: _C.secondary),
              const SizedBox(width: 6),
              Text('Sensor Aktif',
                  style: _t(10, 14, FontWeight.w600, _C.secondary, ls: 0.3)),
            ],
          ),
        ),
        Expanded(child: Center(child: _liveLabel())),
        Row(
          children: [
            _RoundButton(
              size: 32,
              icon: _flashOn ? Icons.flash_on : Icons.flash_off,
              iconSize: 17,
              color: _C.onSurface,
              background: _C.surface.withOpacity(0.85),
              onTap: () => setState(() => _flashOn = !_flashOn),
            ),
            const SizedBox(width: 4),
            _RoundButton(
              size: 32,
              icon: Icons.face,
              iconSize: 17,
              color: _showGuide ? _C.primary : _C.onSurface,
              background: _C.surface.withOpacity(0.85),
              onTap: () => setState(() => _showGuide = !_showGuide),
            ),
          ],
        ),
      ],
    );
  }

  Widget _liveLabel() {
    if (_frozen != null) {
      return GestureDetector(
        onTap: () => setState(() => _frozen = null),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _C.surface.withOpacity(0.9),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.close, size: 14, color: _C.primary),
              const SizedBox(width: 4),
              Text('Foto galeri',
                  style: _t(10, 14, FontWeight.w700, _C.primary)),
            ],
          ),
        ),
      );
    }

    final text = !_live ? 'JEDA' : (_liveError ? 'OFFLINE' : 'LIVE');
    final color =
        (!_live || _liveError) ? Colors.grey.shade600 : const Color(0xFFE53935);
    return GestureDetector(
      onTap: () => setState(() => _live = !_live),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Live Deteksi AI',
              style: _t(12, 16, FontWeight.w700, Colors.white).copyWith(
                  shadows: const [Shadow(blurRadius: 4, color: Colors.black54)])),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(4)),
            child: Text(text,
                style: _t(9, 12, FontWeight.w800, Colors.white, ls: 0.5)),
          ),
        ],
      ),
    );
  }

  Widget _faceGuide() {
    final r = _noFace ? null : _result;
    final m = r == null ? null : emotionMeta(r.key);
    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [_Corner(0), _Corner(1)],
            ),
            if (!AppSettings.instance.emojiOverlay)
              const SizedBox.shrink()
            else
              _Bounce(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: _C.surface.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: _shadowLg,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(m?.emoji ?? '🔍',
                        style: const TextStyle(fontSize: 20, height: 1)),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m?.bubble ?? 'Mencari wajah…',
                            style: _t(12, 16, FontWeight.w700, _C.primary)),
                        Text(
                            r == null
                                ? 'Arahkan wajah ke kamera'
                                : '${r.corrected ? 100 : r.confidence}% Akurasi',
                            style: _t(11, 14, FontWeight.w500,
                                _C.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [_Corner(2), _Corner(3)],
            ),
          ],
        ),
      ),
    );
  }

  Widget _nameplate() {
    final name = _noFace ? null : _result?.personName;
    if (name == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: _C.surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(12),
        boxShadow: _shadowSm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(name.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _t(14, 18, FontWeight.w800, _C.onSurface, ls: 0.5)),
          Text('Wajah Dikenali',
              style: _t(10, 12, FontWeight.w600, _C.secondary)),
        ],
      ),
    );
  }

  Widget _viewfinderBottom() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _C.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        boxShadow: _shadowSm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _RoundButton(
            size: 48,
            icon: Icons.photo_library,
            iconSize: 24,
            color: _C.primary,
            background: _C.surfaceContainer,
            onTap: _pickFromGallery,
          ),
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                _Ping(
                    size: 64,
                    color: _C.primaryContainer.withOpacity(0.2),
                    core: false),
                GestureDetector(
                  onTap: _pressShutter,
                  child: AnimatedScale(
                    scale: _shutterDown ? 0.9 : 1,
                    duration: const Duration(milliseconds: 150),
                    child: Container(
                      width: 64,
                      height: 64,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _C.white,
                        shape: BoxShape.circle,
                        boxShadow: _shadowLg,
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                            color: _C.primaryContainer,
                            shape: BoxShape.circle),
                        child: const Icon(Icons.photo_camera,
                            size: 28, color: _C.onPrimary),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _switchCamera,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                  color: _C.surfaceContainer, shape: BoxShape.circle),
              child: AnimatedRotation(
                turns: _camTurns,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                child: const Icon(Icons.cameraswitch,
                    size: 24, color: _C.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Kartu hasil ──
  Widget _resultCard() {
    final r = _result;
    if (r == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: _shadowSm,
        ),
        child: Column(
          children: [
            const Icon(Icons.face_retouching_natural,
                size: 40, color: _C.primary),
            const SizedBox(height: 8),
            Text('Belum ada hasil',
                style: _t(14, 20, FontWeight.w700, _C.onSurface)),
            const SizedBox(height: 2),
            Text('Arahkan wajah ke kamera atau ambil foto untuk memulai.',
                textAlign: TextAlign.center,
                style: _t(12, 16, FontWeight.w400, _C.onSurfaceVariant)),
          ],
        ),
      );
    }

    final m = emotionMeta(r.key);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: _shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bagian ini yang ditangkap menjadi gambar saat "Simpan & Bagikan"
          RepaintBoundary(
            key: _cardKey,
            child: Container(
              color: _C.white,
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: m.color,
                                shape: BoxShape.circle,
                                boxShadow: _shadowSm,
                              ),
                              child: Text(m.emoji,
                                  style: const TextStyle(
                                      fontSize: 30, height: 1.1)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('HASIL PALING DOMINAN',
                                      style: _t(10, 14, FontWeight.w700,
                                          _C.secondary,
                                          ls: 0.5)),
                                  Text(m.title,
                                      style: _t(20, 26, FontWeight.w700,
                                          _C.onSurface)),
                                  Text(m.desc,
                                      style: _t(12, 16, FontWeight.w400,
                                          _C.onSurfaceVariant)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(r.corrected ? 'Dikoreksi' : '${r.confidence}%',
                              style:
                                  _t(18, 26, FontWeight.w700, _C.primary)),
                          Text(
                              r.corrected
                                  ? 'oleh kamu'
                                  : 'Tingkat\nKeyakinan',
                              textAlign: TextAlign.right,
                              style: _t(10, 12, FontWeight.w500,
                                  _C.onSurfaceVariant)),
                        ],
                      ),
                    ],
                  ),
                  if (r.others.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text('Kemungkinan Lainnya',
                        style: _t(11, 14, FontWeight.w600,
                            _C.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    for (var i = 0; i < r.others.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      _otherRow(r.others[i]),
                    ],
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _feedbackZone(),
        ],
      ),
    );
  }

  Widget _otherRow(OtherEmotion o) {
    final m = emotionMeta(o.key);
    return Row(
      children: [
        SizedBox(
          width: 88,
          child: Row(
            children: [
              Text(m.emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(m.label,
                    overflow: TextOverflow.ellipsis,
                    style: _t(12, 16, FontWeight.w500, _C.onSurface)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: _C.surfaceContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            clipBehavior: Clip.antiAlias,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: (o.percent / 100).clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: m.color,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 40,
          child: Text('${o.percent}%',
              textAlign: TextAlign.right,
              style: _t(11, 14, FontWeight.w600, _C.onSurfaceVariant)),
        ),
      ],
    );
  }

  Widget _feedbackZone() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.containerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text('Apakah analisis ini akurat?',
                    style: _t(12, 16, FontWeight.w600, _C.onSurface)),
              ),
              GestureDetector(
                onTap: _manualCorrection,
                child: Text('Koreksi Manual',
                    style: _t(11, 14, FontWeight.w700, _C.primary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _voteButton(
                  icon: Icons.thumb_up_outlined,
                  iconColor: _C.secondary,
                  label: 'Sesuai Banget',
                  textColor: _C.onSecondaryFixedVariant,
                  selectedBg: _C.secondaryContainer,
                  selected: _vote == true,
                  onTap: () => _sendVote(true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _voteButton(
                  icon: Icons.thumb_down_outlined,
                  iconColor: _C.error,
                  label: 'Kurang Pas',
                  textColor: _C.onSurface,
                  selectedBg: _C.errorContainer,
                  selected: _vote == false,
                  onTap: () => _sendVote(false),
                ),
              ),
            ],
          ),
          if (_vote != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: Text(
                _vote!
                    ? 'Hore! Terima kasih konfirmasinya ✨'
                    : 'Catatan tersimpan! Kamu juga bisa pakai Koreksi Manual.',
                textAlign: TextAlign.center,
                style: _t(12, 16, FontWeight.w500,
                    _vote! ? _C.secondary : _C.onSurfaceVariant),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _voteButton({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Color textColor,
    required Color selectedBg,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? selectedBg : _C.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: _shadowSm,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 6),
            Flexible(
              child: Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: _t(12, 16, FontWeight.w600, textColor)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tombol aksi ──
  Widget _actions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12), boxShadow: _shadowMd),
            child: Material(
              color: _C.primaryContainer,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _shareResult,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.send, size: 20, color: _C.onPrimary),
                      const SizedBox(width: 8),
                      Text('Simpan & Bagikan Hasil',
                          style: _t(16, 24, FontWeight.w600, _C.onPrimary)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: Material(
            color: _C.containerHigh,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _shareSticker,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_reaction_outlined,
                        size: 20, color: _C.primary),
                    const SizedBox(width: 8),
                    Text('Simpan Sebagai Stiker Emoji',
                        style: _t(14, 20, FontWeight.w700, _C.primary)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── Widget kecil ─────────────────────────
class _RoundButton extends StatelessWidget {
  final double size, iconSize;
  final IconData icon;
  final Color color, background;
  final VoidCallback onTap;

  const _RoundButton({
    required this.size,
    required this.icon,
    required this.iconSize,
    required this.color,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          boxShadow: _shadowSm,
        ),
        child: Icon(icon, size: iconSize, color: color),
      ),
    );
  }
}

/// Titik berdenyut (animate-ping).
class _Ping extends StatefulWidget {
  final double size;
  final Color color;
  final bool core;
  const _Ping({required this.size, required this.color, this.core = true});

  @override
  State<_Ping> createState() => _PingState();
}

class _PingState extends State<_Ping> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 1))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dot = BoxDecoration(color: widget.color, shape: BoxShape.circle);
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedBuilder(
            animation: _c,
            builder: (_, __) => Opacity(
              opacity: (1 - _c.value).clamp(0.0, 1.0),
              child: Transform.scale(
                scale: 1 + _c.value,
                child: Container(decoration: dot),
              ),
            ),
          ),
          if (widget.core) Container(decoration: dot),
        ],
      ),
    );
  }
}

/// Gerak naik-turun pelan (animate-bounce).
class _Bounce extends StatefulWidget {
  final Widget child;
  const _Bounce({required this.child});

  @override
  State<_Bounce> createState() => _BounceState();
}

class _BounceState extends State<_Bounce> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, -8 * Curves.easeInOut.transform(_c.value)),
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// Sudut bingkai wajah. 0 = kiri atas, 1 = kanan atas, 2 = kiri bawah, 3 = kanan bawah.
class _Corner extends StatelessWidget {
  final int corner;
  const _Corner(this.corner);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(painter: _CornerPainter(corner)),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final int corner;
  _CornerPainter(this.corner);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    switch (corner) {
      case 1:
        canvas.translate(size.width, 0);
        canvas.scale(-1, 1);
        break;
      case 2:
        canvas.translate(0, size.height);
        canvas.scale(1, -1);
        break;
      case 3:
        canvas.translate(size.width, size.height);
        canvas.scale(-1, -1);
        break;
    }
    final paint = Paint()
      ..color = _C.primaryContainer
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(1.5, size.height)
      ..lineTo(1.5, 12)
      ..quadraticBezierTo(1.5, 1.5, 12, 1.5)
      ..lineTo(size.width, 1.5);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CornerPainter old) => old.corner != corner;
}
