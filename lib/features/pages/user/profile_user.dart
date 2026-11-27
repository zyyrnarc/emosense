import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/stores/auth_store.dart';
import '../../../core/app_settings.dart';
import '../../../data/service/emotion_service.dart';
import '../../../data/service/pdf_service.dart';
import 'settings_user.dart';

const String kAppVersion = '1.0.0';

const _months = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

// ───────────────────────── Warna & gaya ─────────────────────────
class _C {
  static const surface = Color(0xFFFAF8FF);
  static const onSurface = Color(0xFF131B2E);
  static const onSurfaceVariant = Color(0xFF434655);
  static const outline = Color(0xFF737686);
  static const outlineVariant = Color(0xFFC3C6D7);
  static const primary = Color(0xFF004AC6);
  static const primaryContainer = Color(0xFF2563EB);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryFixed = Color(0xFFDBE1FF);
  static const onPrimaryFixed = Color(0xFF00174B);
  static const secondary = Color(0xFF006C49);
  static const secondaryContainer = Color(0xFF6CF8BB);
  static const secondaryFixed = Color(0xFF6FFBBE);
  static const onSecondary = Color(0xFFFFFFFF);
  static const onSecondaryContainer = Color(0xFF00714D);
  static const tertiary = Color(0xFF784B00);
  static const tertiaryContainer = Color(0xFF996100);
  static const tertiaryFixed = Color(0xFFFFDDB8);
  static const tertiaryFixedDim = Color(0xFFFFB95F);
  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);
  static const white = Color(0xFFFFFFFF);
  static const surfaceContainer = Color(0xFFEAEDFF);
  static const containerLow = Color(0xFFF2F3FF);
  static const containerHigh = Color(0xFFE2E7FF);
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

// ───────────────────────── Bagikan stiker ─────────────────────────
Future<bool> _shareEmojiSticker(EmotionMeta m) async {
  try {
    final f = await ShareHelper.emojiSticker(m.emoji);
    await ShareHelper.shareFile(f, 'Stiker ${m.title} dari Sensio AI');
    return true;
  } catch (_) {
    return false;
  }
}

// ───────────────────────── Tab Profil ─────────────────────────
class ProfileTab extends StatefulWidget {
  final UserAccount user;
  final VoidCallback onLogout;
  const ProfileTab({super.key, required this.user, required this.onLogout});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _showQr = false;

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 2400),
      ));
  }

  String get _name {
    final n = AppSettings.instance.displayName;
    return (n != null && n.isNotEmpty) ? n : widget.user.name;
  }

  String get _initial {
    final n = _name.trim();
    return n.isEmpty ? '?' : n[0].toUpperCase();
  }

  /// ID akun tampilan, diturunkan dari email (bukan ID dari server).
  String get _accountId {
    var h = 7;
    for (final c in widget.user.email.toLowerCase().codeUnits) {
      h = (h * 31 + c) % 100000;
    }
    return 'SNS-${h.toString().padLeft(5, '0')}-ID';
  }

  // ── Aksi ──
  Future<void> _editName() async {
    final c = TextEditingController(text: _name);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profil'),
        content: TextField(
          controller: c,
          autofocus: true,
          maxLength: 40,
          decoration: const InputDecoration(labelText: 'Nama tampilan'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Simpan')),
        ],
      ),
    );
    if (ok == true) {
      await AppSettings.instance.setDisplayName(c.text);
      _toast('Profil diperbarui');
    }
  }

  Future<void> _shareProfile() async {
    try {
      await Share.share(
          'Aku pakai Sensio AI untuk melacak suasana hatiku 😊\nID: $_accountId');
    } catch (_) {
      _toast('Gagal membagikan profil');
    }
  }

  void _openSettings() {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const SettingsPage()));
  }

  void _openCollection() {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const _StickerCollectionPage()));
  }

  Future<void> _shareSticker(EmotionMeta m) async {
    final ok = await _shareEmojiSticker(m);
    if (!ok) _toast('Gagal membuat stiker');
  }

  Future<void> _exportCsv() async {
    final items = HistoryStore.instance.items;
    if (items.isEmpty) {
      _toast('Belum ada data untuk diekspor');
      return;
    }
    try {
      String q(String s) => '"${s.replaceAll('"', '""')}"';
      final b = StringBuffer('waktu,ekspresi,keyakinan_persen,nama\n');
      for (final e in items) {
        b.writeln('${e.time.toIso8601String()},'
            '${q(emotionMeta(e.key).label)},${e.confidence},${q(e.name ?? '')}');
      }
      final dir = await getTemporaryDirectory();
      final f = File(
          '${dir.path}/sensio_jurnal_mood_${DateTime.now().millisecondsSinceEpoch}.csv');
      await f.writeAsString(b.toString());
      await Share.shareXFiles([XFile(f.path, mimeType: 'text/csv')],
          text: 'Jurnal Mood - Sensio AI');
    } catch (_) {
      _toast('Gagal membuat CSV');
    }
  }

  Future<void> _exportPdf() async {
    final items = HistoryStore.instance.items;
    if (items.isEmpty) {
      _toast('Belum ada data untuk diekspor');
      return;
    }
    try {
      await PdfService.shareMoodDiary(items: items, periodLabel: 'Semua Waktu');
    } catch (_) {
      _toast('Gagal membuat PDF');
    }
  }

  void _exportSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _C.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ekspor Data Jurnal Mood',
                  style: _t(16, 22, FontWeight.w700, _C.onSurface)),
              const SizedBox(height: 4),
              Text('Pilih format file yang ingin dibagikan.',
                  style: _t(12, 16, FontWeight.w400, _C.onSurfaceVariant)),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.table_chart, color: _C.secondary),
                title: const Text('CSV (spreadsheet)'),
                subtitle: const Text('Semua riwayat, bisa dibuka di Excel'),
                onTap: () {
                  Navigator.pop(ctx);
                  _exportCsv();
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.picture_as_pdf, color: _C.primary),
                title: const Text('PDF (laporan visual)'),
                subtitle: const Text('Ringkasan komposisi dan daftar riwayat'),
                onTap: () {
                  Navigator.pop(ctx);
                  _exportPdf();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text('Kamu bisa masuk lagi kapan saja.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Keluar')),
        ],
      ),
    );
    if (ok == true) widget.onLogout();
  }

  // ───────────── UI ─────────────
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable:
          Listenable.merge([AppSettings.instance, HistoryStore.instance]),
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _profileCard(),
              const SizedBox(height: 24),
              _statsSection(),
              const SizedBox(height: 24),
              _avatarSection(),
              const SizedBox(height: 24),
              _menuSection(),
              const SizedBox(height: 24),
              _privacyBanner(),
              const SizedBox(height: 24),
              _logoutSection(),
            ],
          ),
        );
      },
    );
  }

  // ── Kartu profil ──
  Widget _profileCard() {
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _avatar(),
                    const SizedBox(width: 16),
                    Expanded(child: _identity()),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _showQr = !_showQr),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _showQr ? _C.primary : _C.containerLow,
                    shape: BoxShape.circle,
                    boxShadow: _shadowSm,
                  ),
                  child: Icon(Icons.qr_code_2,
                      size: 20, color: _showQr ? _C.onPrimary : _C.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: _C.containerLow,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: _editName,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.edit, size: 18, color: _C.primary),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text('Edit Profil',
                                overflow: TextOverflow.ellipsis,
                                style:
                                    _t(12, 16, FontWeight.w600, _C.primary)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: _C.containerLow,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: _shareProfile,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Icon(Icons.share,
                        size: 18, color: _C.onSurfaceVariant),
                  ),
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _showQr ? _qrPanel() : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _avatar() {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_C.primary, _C.primaryContainer],
              ),
              boxShadow: _shadowSm,
            ),
            child: Text(_initial,
                style: _t(26, 32, FontWeight.w700, _C.onPrimary)),
          ),
          Positioned(
            right: -10,
            bottom: -6,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: _C.white,
                borderRadius: BorderRadius.circular(999),
                boxShadow: _shadowSm,
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _C.secondary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          color: _C.secondaryFixed, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text('AI Active',
                        style: _t(10, 12, FontWeight.w600, _C.onSecondary)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _identity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _t(20, 28, FontWeight.w700, _C.onSurface)),
        Text(widget.user.email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _t(12, 16, FontWeight.w400, _C.onSurfaceVariant)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: _C.primaryFixed,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.stars, size: 14, color: _C.onPrimaryFixed),
              const SizedBox(width: 4),
              Flexible(
                child: Text('Sensio Personal',
                    overflow: TextOverflow.ellipsis,
                    style: _t(11, 14, FontWeight.w600, _C.onPrimaryFixed)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _qrPanel() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.containerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _C.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: _shadowSm,
            ),
            child: QrImageView(
              data: 'SENSIO:$_accountId',
              size: 128,
              backgroundColor: _C.white,
            ),
          ),
          const SizedBox(height: 8),
          Text('ID: $_accountId',
              style: _t(11, 14, FontWeight.w600, _C.onSurface)),
          const SizedBox(height: 2),
          Text('Bagikan ID akun Sensio AI-mu lewat kode QR',
              textAlign: TextAlign.center,
              style: _t(12, 16, FontWeight.w400, _C.onSurfaceVariant)),
        ],
      ),
    );
  }

  // ── Statistik mood bulanan (dari riwayat asli) ──
  Widget _statsSection() {
    final now = DateTime.now();
    final month = HistoryStore.instance.items
        .where((e) => e.time.year == now.year && e.time.month == now.month)
        .toList();

    final activeDays = month.map((e) => e.time.day).toSet().length;
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    final counts = <String, int>{};
    for (final e in month) {
      final k = normalizeEmotion(e.key);
      counts[k] = (counts[k] ?? 0) + 1;
    }
    String? topKey;
    counts.forEach((k, v) {
      if (topKey == null || v > counts[topKey]!) topKey = k;
    });
    final topMeta = topKey == null ? null : emotionMeta(topKey!);
    final topPct =
        topKey == null ? 0 : (counts[topKey]! / month.length * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Statistik Mood Bulanan',
                style: _t(14, 20, FontWeight.w600, _C.onSurface)),
            Text('${_months[now.month - 1]} ${now.year}',
                style: _t(11, 14, FontWeight.w600, _C.primary)),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _statCard(
                iconBg: _C.containerLow,
                icon: const Icon(Icons.calendar_today,
                    size: 18, color: _C.primary),
                value: '$activeDays Hari',
                label: 'Aktif Konsisten',
                progress: activeDays / daysInMonth,
                barColor: _C.primary,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _statCard(
                iconBg: _C.secondaryFixed,
                icon: Text(topMeta?.emoji ?? '🙂',
                    style: const TextStyle(fontSize: 16)),
                value: topMeta?.label ?? '-',
                label: topMeta == null ? 'Belum ada data' : '$topPct% Dominan',
                labelColor: topMeta == null ? null : _C.secondary,
                progress: topPct / 100,
                barColor: _C.secondary,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _statCard(
                iconBg: _C.tertiaryFixed,
                icon:
                    const Icon(Icons.videocam, size: 18, color: _C.tertiary),
                value: '${month.length}',
                label: 'Sesi Selesai',
                // target 100 sesi per bulan sebagai patokan bar
                progress: (month.length / 100).clamp(0.0, 1.0).toDouble(),
                barColor: _C.tertiaryFixedDim,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statCard({
    required Color iconBg,
    required Widget icon,
    required String value,
    required String label,
    required double progress,
    required Color barColor,
    Color? labelColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: _shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(8)),
            child: icon,
          ),
          const SizedBox(height: 8),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _t(12, 16, FontWeight.w700, _C.onSurface)),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _t(11, 14, labelColor == null ? FontWeight.w400 : FontWeight.w600,
                  labelColor ?? _C.onSurfaceVariant)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0).toDouble(),
              minHeight: 4,
              backgroundColor: _C.containerHigh,
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
        ],
      ),
    );
  }

  // ── Avatar emosi terkini (dari riwayat asli) ──
  Widget _avatarSection() {
    final seen = <String>{};
    final recent = <EmotionMeta>[];
    for (final e in HistoryStore.instance.items) {
      final k = normalizeEmotion(e.key);
      if (seen.add(k)) recent.add(emotionMeta(k));
      if (recent.length >= 5) break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.face_retouching_natural,
                    size: 18, color: _C.primary),
                const SizedBox(width: 6),
                Text('Avatar Emosi Terkini',
                    style: _t(14, 20, FontWeight.w600, _C.onSurface)),
              ],
            ),
            GestureDetector(
              onTap: _openCollection,
              child: Text('Kelola Semua',
                  style: _t(11, 14, FontWeight.w600, _C.primary)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 92,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final m in recent) ...[
                _avatarTile(m),
                const SizedBox(width: 8),
              ],
              _addTile(),
            ],
          ),
        ),
        if (recent.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('Belum ada avatar. Pindai wajahmu dulu di tab Pindai.',
                style: _t(12, 16, FontWeight.w400, _C.onSurfaceVariant)),
          ),
      ],
    );
  }

  Widget _avatarTile(EmotionMeta m) {
    return GestureDetector(
      onTap: () => _shareSticker(m),
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: _shadowSm,
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: m.color.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(m.emoji, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(height: 4),
            Text(m.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _t(10, 14, FontWeight.w500, _C.onSurface)),
          ],
        ),
      ),
    );
  }

  Widget _addTile() {
    return GestureDetector(
      onTap: _openCollection,
      child: Container(
        width: 80,
        decoration: BoxDecoration(
          color: _C.containerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _C.outlineVariant),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_reaction_outlined,
                size: 24, color: _C.primary),
            const SizedBox(height: 4),
            Text('Tambah', style: _t(10, 14, FontWeight.w600, _C.primary)),
          ],
        ),
      ),
    );
  }

  // ── Menu pengaturan & fitur ──
  Widget _menuSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pengaturan & Fitur',
            style: _t(14, 20, FontWeight.w600, _C.onSurface)),
        const SizedBox(height: 4),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: _C.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: _shadowSm,
          ),
          child: Column(
            children: [
              _menuItem(
                icon: Icons.tune,
                color: _C.primary,
                title: 'Pengaturan Sensor & Kamera AI',
                desc: 'Sensitivitas, FPS, tema, dan notifikasi',
                onTap: _openSettings,
              ),
              _divider(),
              _menuItem(
                icon: Icons.ios_share,
                color: _C.secondary,
                title: 'Ekspor Data Jurnal Mood',
                desc: 'Unduh ringkasan format CSV & laporan PDF',
                badge: 'CSV/PDF',
                onTap: _exportSheet,
              ),
              _divider(),
              _menuItem(
                icon: Icons.emoji_emotions,
                color: _C.tertiary,
                title: 'Koleksi Avatar Emoji Saya',
                desc: 'Galeri stiker emoji dari ekspresimu',
                onTap: _openCollection,
              ),
              _divider(),
              _menuItem(
                icon: Icons.lock_reset,
                color: _C.primary,
                title: 'Pusat Keamanan & Sandi',
                desc: 'Ubah sandi dan keamanan akun',
                // TODO: sambungkan ke endpoint ubah sandi di backend
                onTap: () => _toast('Pusat keamanan belum tersedia'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _divider() => Container(height: 1, color: _C.containerLow);

  Widget _menuItem({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
    required VoidCallback onTap,
    String? badge,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _C.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: _t(12, 16, FontWeight.w600, _C.onSurface)),
                  Text(desc,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          _t(12, 16, FontWeight.w400, _C.onSurfaceVariant)),
                ],
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _C.containerHigh,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(badge,
                    style: _t(10, 14, FontWeight.w600, _C.onSurfaceVariant)),
              ),
            ],
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 20, color: _C.outlineVariant),
          ],
        ),
      ),
    );
  }

  // ── Banner privasi (teks disesuaikan dengan cara kerja aplikasi) ──
  Widget _privacyBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.secondaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        boxShadow: _shadowSm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(top: 2),
            decoration: const BoxDecoration(
                color: _C.secondary, shape: BoxShape.circle),
            child:
                const Icon(Icons.verified_user, size: 20, color: _C.onSecondary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Riwayat Tersimpan di Perangkatmu',
                    style: _t(12, 16, FontWeight.w700, _C.onSecondaryContainer)),
                const SizedBox(height: 2),
                Text(
                    'Foto dan hasil pindaian disimpan hanya di ponselmu. Saat dianalisis, foto dikirim ke server Sensio AI untuk dikenali ekspresinya.',
                    style: _t(12, 18, FontWeight.w400, _C.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Keluar ──
  Widget _logoutSection() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: Material(
            color: _C.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _confirmLogout,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _shadowSm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout, size: 20, color: _C.error),
                    const SizedBox(width: 8),
                    Text('Keluar dari Akun',
                        style: _t(14, 20, FontWeight.w600, _C.error)),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text('Sensio AI v$kAppVersion',
            style: _t(11, 14, FontWeight.w600, _C.outline)),
      ],
    );
  }
}

// ───────────────────────── Koleksi avatar emoji ─────────────────────────
class _StickerCollectionPage extends StatelessWidget {
  const _StickerCollectionPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.surface,
      appBar: AppBar(
        backgroundColor: _C.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _C.onSurface),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text('Koleksi Avatar Emoji',
            style: _t(17, 24, FontWeight.w700, _C.onSurface)),
      ),
      body: ListenableBuilder(
        listenable: HistoryStore.instance,
        builder: (context, _) {
          final counts = <String, int>{};
          for (final e in HistoryStore.instance.items) {
            final k = normalizeEmotion(e.key);
            counts[k] = (counts[k] ?? 0) + 1;
          }
          final all = allEmotions;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                      'Ketuk stiker untuk membagikannya sebagai gambar PNG.',
                      style: _t(12, 16, FontWeight.w400, _C.onSurfaceVariant)),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: all.length,
                  itemBuilder: (context, i) {
                    final m = all[i];
                    final n = counts[m.key] ?? 0;
                    return GestureDetector(
                      onTap: () async {
                        final ok = await _shareEmojiSticker(m);
                        if (!ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Gagal membuat stiker')));
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: _C.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _shadowSm,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: m.color.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(m.emoji,
                                  style: const TextStyle(fontSize: 36)),
                            ),
                            const SizedBox(height: 8),
                            Text(m.label,
                                style: _t(12, 16, FontWeight.w700,
                                    _C.onSurface)),
                            Text(n == 0 ? 'Belum ada' : '${n}x terdeteksi',
                                style: _t(10, 14, FontWeight.w500,
                                    _C.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}