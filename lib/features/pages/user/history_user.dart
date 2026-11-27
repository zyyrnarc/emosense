import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../../data/service/emotion_service.dart';
import '../../../data/service/pdf_service.dart';

// ───────────────────────── Warna & gaya ─────────────────────────
class _C {
  static const surface = Color(0xFFFAF8FF);
  static const onSurface = Color(0xFF131B2E);
  static const onSurfaceVariant = Color(0xFF434655);
  static const outline = Color(0xFF737686);
  static const primary = Color(0xFF004AC6);
  static const primaryContainer = Color(0xFF2563EB);
  static const onPrimary = Color(0xFFFFFFFF);
  static const onPrimaryContainer = Color(0xFFEEEFFF);
  static const primaryFixed = Color(0xFFDBE1FF);
  static const secondary = Color(0xFF006C49);
  static const secondaryContainer = Color(0xFF6CF8BB);
  static const onSecondary = Color(0xFFFFFFFF);
  static const onSecondaryContainer = Color(0xFF00714D);
  static const onSecondaryFixed = Color(0xFF002113);
  static const onSecondaryFixedVariant = Color(0xFF005236);
  static const tertiary = Color(0xFF784B00);
  static const tertiaryContainer = Color(0xFF996100);
  static const tertiaryFixed = Color(0xFFFFDDB8);
  static const onTertiary = Color(0xFFFFFFFF);
  static const onTertiaryFixed = Color(0xFF2A1700);
  static const error = Color(0xFFBA1A1A);
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
final List<BoxShadow> _shadowCard = [
  BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.05),
      blurRadius: 20,
      spreadRadius: -2,
      offset: const Offset(0, 4)),
];
final List<BoxShadow> _shadowItem = [
  BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.04),
      blurRadius: 12,
      spreadRadius: -2,
      offset: const Offset(0, 2)),
];

// ───────────────────────── Kategori tampilan ─────────────────────────
/// 4 kategori seperti di desain: Bahagia, Tenang (netral), Kaget, Lainnya.
class _Cat {
  final String label;
  final IconData icon;
  final Color color, countColor, badgeBg, badgeFg, chipBg, chipFg;
  const _Cat(this.label, this.icon, this.color, this.countColor, this.badgeBg,
      this.badgeFg, this.chipBg, this.chipFg);
}

const _cats = [
  _Cat('Bahagia', Icons.sentiment_very_satisfied, _C.secondary, _C.secondary,
      _C.secondary, _C.onSecondary, _C.secondaryContainer,
      _C.onSecondaryContainer),
  _Cat('Tenang', Icons.self_improvement, _C.primaryContainer, _C.primary,
      _C.primary, _C.onPrimary, _C.primaryFixed, _C.primary),
  _Cat('Kaget', Icons.sentiment_neutral, _C.tertiaryContainer, _C.tertiary,
      _C.tertiary, _C.onTertiary, _C.tertiaryFixed, _C.onTertiaryFixed),
  _Cat('Lainnya', Icons.sentiment_dissatisfied, _C.outline,
      _C.onSurfaceVariant, _C.outline, _C.white, _C.containerHigh,
      _C.onSurfaceVariant),
];

int _catOf(String key) {
  switch (normalizeEmotion(key)) {
    case 'happy':
      return 0;
    case 'neutral':
      return 1;
    case 'surprise':
      return 2;
    default:
      return 3;
  }
}

String _pad(int n) => n.toString().padLeft(2, '0');

String _zone(DateTime t) {
  switch (t.timeZoneOffset.inHours) {
    case 7:
      return ' WIB';
    case 8:
      return ' WITA';
    case 9:
      return ' WIT';
    default:
      return '';
  }
}

/// "Hari Ini, 10:42 WIB" / "Kemarin, 19:20 WIB" / "12/11/2026, 08:15 WIB"
String _fmtWhen(DateTime t) {
  final n = DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  final day = DateTime(t.year, t.month, t.day);
  final diff = today.difference(day).inDays;
  final d = diff == 0
      ? 'Hari Ini'
      : diff == 1
          ? 'Kemarin'
          : '${_pad(t.day)}/${_pad(t.month)}/${t.year}';
  return '$d, ${_pad(t.hour)}:${_pad(t.minute)}${_zone(t)}';
}

// ───────────────────────── Tab Riwayat ─────────────────────────
class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  static const _ranges = ['Hari Ini', 'Minggu Ini', 'Bulan Ini'];
  static const _periodWord = ['Hari ini', 'Minggu ini', 'Bulan ini'];
  static const _prevWord = ['kemarin', 'pekan lalu', 'bulan lalu'];

  int _range = 1;
  String? _emoFilter; // null = semua emosi
  final _search = TextEditingController();
  final GlobalKey _summaryKey = GlobalKey();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 2400),
      ));
  }

  // ── Data & periode ──
  DateTime get _start {
    final n = DateTime.now();
    final d = DateTime(n.year, n.month, n.day);
    switch (_range) {
      case 0:
        return d;
      case 1:
        return d.subtract(const Duration(days: 6)); // 7 hari terakhir
      default:
        return DateTime(n.year, n.month, 1);
    }
  }

  DateTime get _prevStart {
    final s = _start;
    switch (_range) {
      case 0:
        return s.subtract(const Duration(days: 1));
      case 1:
        return s.subtract(const Duration(days: 7));
      default:
        return DateTime(s.year, s.month - 1, 1);
    }
  }

  List<HistoryItem> get _all => HistoryStore.instance.items;

  List<HistoryItem> get _inRange =>
      _all.where((e) => !e.time.isBefore(_start)).toList();

  List<HistoryItem> get _prevRange => _all
      .where((e) => !e.time.isBefore(_prevStart) && e.time.isBefore(_start))
      .toList();

  List<int> _counts(List<HistoryItem> l) {
    final c = List<int>.filled(_cats.length, 0);
    for (final e in l) {
      c[_catOf(e.key)]++;
    }
    return c;
  }

  List<HistoryItem> get _visible {
    final q = _search.text.trim().toLowerCase();
    return _inRange.where((e) {
      if (_emoFilter != null && normalizeEmotion(e.key) != _emoFilter) {
        return false;
      }
      if (q.isEmpty) return true;
      final m = emotionMeta(e.key);
      return m.title.toLowerCase().contains(q) ||
          m.label.toLowerCase().contains(q) ||
          (e.name ?? '').toLowerCase().contains(q);
    }).toList();
  }

  // ── Aksi ──
  Future<void> _share(HistoryItem e) async {
    final m = emotionMeta(e.key);
    final text = 'Suasana hatiku: ${m.emoji} ${m.title} (${e.confidence}%) '
        '— ${_fmtWhen(e.time)} — Sensio AI';
    try {
      final p = e.imagePath;
      if (p != null && File(p).existsSync()) {
        await Share.shareXFiles([XFile(p)], text: text);
      } else {
        await Share.share(text);
      }
    } catch (_) {
      _toast('Gagal membagikan riwayat');
    }
  }

  Future<void> _delete(HistoryItem e) async {
    await HistoryStore.instance.remove(e.id);
    if (mounted) _toast('Catatan riwayat dihapus.');
  }

  Future<void> _pickEmotionFilter() async {
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
              Text('Filter ekspresi',
                  style: _t(16, 22, FontWeight.w700, _C.onSurface)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _filterChip('Semua', '', _emoFilter == null, 'all'),
                  for (final m in allEmotions)
                    _filterChip(m.label, m.emoji, _emoFilter == m.key, m.key),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _emoFilter = picked == 'all' ? null : picked);
  }

  Widget _filterChip(String label, String emoji, bool selected, String value) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => Navigator.pop(context, value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _C.primaryFixed : _C.containerLow,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji.isNotEmpty) ...[
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
            ],
            Text(label, style: _t(12, 16, FontWeight.w600, _C.onSurface)),
          ],
        ),
      ),
    );
  }

  Future<void> _exportImage() async {
    if (_inRange.isEmpty) {
      _toast('Belum ada data untuk diekspor');
      return;
    }
    _toast('Menyiapkan gambar kartu suasana hati...');
    try {
      final f = await ShareHelper.captureBoundary(_summaryKey);
      await ShareHelper.shareFile(
          f, 'Mood Diary ${_periodWord[_range].toLowerCase()} — Sensio AI');
    } catch (_) {
      _toast('Gagal membuat gambar');
    }
  }

  Future<void> _exportPdf() async {
    final items = _inRange;
    if (items.isEmpty) {
      _toast('Belum ada data untuk diekspor');
      return;
    }
    try {
      await PdfService.shareMoodDiary(
        items: items,
        periodLabel: _ranges[_range],
      );
    } catch (_) {
      _toast('Gagal membuat PDF');
    }
  }

  // ───────────── UI ─────────────
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: HistoryStore.instance,
      builder: (context, _) {
        final counts = _counts(_inRange);
        final prevCounts = _counts(_prevRange);
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(),
              const SizedBox(height: 24),
              _rangeFilter(),
              const SizedBox(height: 24),
              // Bagian ini yang diekspor sebagai gambar
              RepaintBoundary(
                key: _summaryKey,
                child: Container(
                  color: _C.surface,
                  padding: const EdgeInsets.all(2),
                  child: Column(
                    children: [
                      _banner(counts, prevCounts),
                      const SizedBox(height: 24),
                      _compositionCard(counts),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _historyHeader(),
              const SizedBox(height: 8),
              _historyList(),
              const SizedBox(height: 24),
              _exportCard(),
            ],
          ),
        );
      },
    );
  }

  // ── Judul ──
  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _C.secondaryContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.celebration,
                  size: 16, color: _C.onSecondaryContainer),
              const SizedBox(width: 6),
              Text('Jurnal Suasana Hati',
                  style: _t(11, 14, FontWeight.w600, _C.onSecondaryContainer)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text('Riwayat & Analisis Diri',
            style: _t(22, 30, FontWeight.w700, _C.onSurface)),
        const SizedBox(height: 4),
        Text('Lacak energi positif dan perkembangan emosimu secara berkala.',
            style: _t(12, 16, FontWeight.w400, _C.onSurfaceVariant)),
      ],
    );
  }

  // ── Filter rentang waktu ──
  Widget _rangeFilter() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _C.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (var i = 0; i < _ranges.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _range = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _range == i ? _C.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: _range == i ? _shadowSm : null,
                  ),
                  child: Text(
                    _ranges[i],
                    style: _t(
                      12,
                      16,
                      _range == i ? FontWeight.w700 : FontWeight.w600,
                      _range == i ? _C.primary : _C.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Banner pencapaian (dihitung dari data) ──
  Widget _banner(List<int> counts, List<int> prevCounts) {
    final total = counts.fold<int>(0, (a, b) => a + b);
    final happy = counts[0];
    final prevHappy = prevCounts[0];
    final word = _periodWord[_range];

    final headline = total == 0
        ? 'Belum ada pemindaian ${word.toLowerCase()}'
        : (happy / total >= 0.4
            ? '$word kamu banyak tersenyum! ✨'
            : '$word suasana hatimu tercatat 💙');

    final base = _t(12, 16, FontWeight.w400, _C.onSecondaryFixedVariant);
    final bold = _t(12, 16, FontWeight.w700, _C.secondary);

    final List<InlineSpan> body;
    if (total == 0) {
      body = [
        const TextSpan(
            text: 'Mulai pindai wajahmu di tab Pindai untuk melihat analisis.')
      ];
    } else if (happy == 0) {
      body = [
        const TextSpan(
            text:
                'Belum ada ekspresi bahagia terdeteksi. Coba tersenyum di depan kamera!')
      ];
    } else {
      String delta = '';
      if (prevHappy > 0) {
        final d = ((happy - prevHappy) / prevHappy * 100).round();
        delta = ' (${d >= 0 ? '+' : ''}$d% dibanding ${_prevWord[_range]})';
      }
      body = [
        const TextSpan(text: 'Ekspresi bahagia terdeteksi '),
        TextSpan(text: '$happy kali', style: bold),
        TextSpan(text: delta),
        const TextSpan(text: '. Terus pancarkan energi positifmu!'),
      ];
    }

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_C.secondaryContainer, _C.containerHighest, _C.primaryFixed],
        ),
        boxShadow: [
          BoxShadow(
              color: _C.secondary.withOpacity(0.12),
              blurRadius: 24,
              spreadRadius: -4,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -16,
            bottom: -24,
            child: IgnorePointer(
              child: Icon(Icons.sentiment_very_satisfied,
                  size: 130, color: _C.secondary.withOpacity(0.2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _C.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: _shadowSm,
                  ),
                  child: const Icon(Icons.auto_awesome,
                      size: 28, color: _C.secondary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PENCAPAIAN KEBAIKAN',
                            style: _t(11, 14, FontWeight.w700,
                                _C.onSecondaryContainer,
                                ls: 0.55)),
                        const SizedBox(height: 4),
                        Text(headline,
                            style: _t(20, 24, FontWeight.w700,
                                _C.onSecondaryFixed)),
                        const SizedBox(height: 4),
                        Text.rich(TextSpan(style: base, children: body)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Komposisi suasana hati (donut dari data) ──
  Widget _compositionCard(List<int> counts) {
    final total = counts.fold<int>(0, (a, b) => a + b);
    final fractions = [
      for (final c in counts) total == 0 ? 0.0 : c / total,
    ];
    var top = 0;
    for (var i = 1; i < counts.length; i++) {
      if (counts[i] > counts[top]) top = i;
    }
    final topCat = _cats[top];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: _shadowCard,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                          color: _C.primary, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text('Komposisi Suasana Hati',
                          overflow: TextOverflow.ellipsis,
                          style: _t(14, 20, FontWeight.w700, _C.onSurface)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _C.surfaceContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('Total $total Scan',
                    style: _t(11, 14, FontWeight.w600, _C.onSurfaceVariant)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 144,
            height: 144,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(144, 144),
                  painter: _DonutPainter(
                      fractions, [for (final c in _cats) c.color]),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(total == 0 ? Icons.mood : topCat.icon,
                        size: 20,
                        color: total == 0 ? _C.outline : topCat.badgeBg),
                    const SizedBox(height: 2),
                    Text(
                        total == 0
                            ? '0%'
                            : '${(fractions[top] * 100).round()}%',
                        style: _t(20, 20, FontWeight.w700, _C.onSurface)),
                    Text(total == 0 ? 'Belum ada data' : topCat.label,
                        style:
                            _t(11, 14, FontWeight.w500, _C.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _legendItem(0, counts[0], fractions[0])),
              const SizedBox(width: 10),
              Expanded(child: _legendItem(1, counts[1], fractions[1])),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _legendItem(2, counts[2], fractions[2])),
              const SizedBox(width: 10),
              Expanded(child: _legendItem(3, counts[3], fractions[3])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(int i, int count, double fraction) {
    final c = _cats[i];
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _C.containerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration:
                    BoxDecoration(color: c.color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(c.label,
                    overflow: TextOverflow.ellipsis,
                    style: _t(11, 14, FontWeight.w600, _C.onSurface)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('${(fraction * 100).round()}%',
                  style: _t(14, 20, FontWeight.w700, _C.onSurface)),
              Text('${count}x',
                  style: _t(11, 14, FontWeight.w500, c.countColor)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Header riwayat + pencarian + filter ──
  Widget _historyHeader() {
    final filtered = _emoFilter != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Riwayat Pemindaian',
                style: _t(20, 28, FontWeight.w700, _C.onSurface)),
            Text('Tersimpan di Perangkat',
                style: _t(11, 14, FontWeight.w600, _C.primary)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: _C.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _shadowSm,
                ),
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  style: _t(12, 16, FontWeight.w400, _C.onSurface),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'Cari emosi, nama...',
                    hintStyle: _t(12, 16, FontWeight.w400, _C.outline),
                    prefixIcon:
                        const Icon(Icons.search, size: 18, color: _C.outline),
                    prefixIconConstraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _pickEmotionFilter,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: filtered ? _C.primaryFixed : _C.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _shadowSm,
                ),
                child: Icon(Icons.filter_list,
                    size: 20,
                    color: filtered ? _C.primary : _C.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Daftar riwayat ──
  Widget _historyList() {
    final items = _visible;
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text('Belum ada riwayat',
              style: _t(12, 16, FontWeight.w500, _C.onSurfaceVariant)),
        ),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _historyItem(items[i]),
        ],
      ],
    );
  }

  Widget _historyItem(HistoryItem e) {
    final m = emotionMeta(e.key);
    final cat = _cats[_catOf(e.key)];
    final when = e.name == null
        ? _fmtWhen(e.time)
        : '${_fmtWhen(e.time)} • ${e.name}';
    return Container(
      key: ValueKey(e.id),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: _shadowItem,
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                _thumb(e, m, cat),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(m.title,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    _t(14, 20, FontWeight.w700, _C.onSurface)),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: cat.chipBg,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text('${e.confidence.round()}%',
                                style:
                                    _t(11, 14, FontWeight.w600, cat.chipFg)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.schedule,
                              size: 14, color: _C.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(when,
                                overflow: TextOverflow.ellipsis,
                                style: _t(12, 16, FontWeight.w400,
                                    _C.onSurfaceVariant)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          _smallIconButton(Icons.share, () => _share(e)),
          const SizedBox(width: 4),
          _smallIconButton(Icons.delete, () => _delete(e)),
        ],
      ),
    );
  }

  Widget _thumb(HistoryItem e, EmotionMeta m, _Cat cat) {
    final p = e.imagePath;
    final hasImage = p != null && File(p).existsSync();
    final fallback = Container(
      color: m.color,
      alignment: Alignment.center,
      child: Text(m.emoji, style: const TextStyle(fontSize: 24)),
    );
    return SizedBox(
      width: 48,
      height: 48,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            hasImage
                ? Image.file(File(p),
                    fit: BoxFit.cover,
                    cacheWidth: 120,
                    errorBuilder: (_, __, ___) => fallback)
                : fallback,
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: cat.badgeBg,
                  borderRadius:
                      const BorderRadius.only(topLeft: Radius.circular(4)),
                ),
                child: Icon(cat.icon, size: 10, color: cat.badgeFg),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
            color: _C.surfaceContainer, shape: BoxShape.circle),
        child: Icon(icon, size: 18, color: _C.onSurfaceVariant),
      ),
    );
  }

  // ── Kartu ekspor Mood Diary ──
  Widget _exportCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.containerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                    color: _C.primaryContainer, shape: BoxShape.circle),
                child: const Icon(Icons.book_online,
                    size: 22, color: _C.onPrimaryContainer),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Simpan Mood Diary',
                        style: _t(14, 20, FontWeight.w700, _C.onSurface)),
                    Text('Abadikan rekap kebahagiaanmu untuk jurnal refleksi.',
                        style:
                            _t(12, 16, FontWeight.w400, _C.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _exportButton(
                  icon: Icons.image,
                  label: 'Ekspor Gambar',
                  background: _C.white,
                  foreground: _C.primary,
                  onTap: _exportImage,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _exportButton(
                  icon: Icons.picture_as_pdf,
                  label: 'Unduh PDF',
                  background: _C.primaryContainer,
                  foreground: _C.onPrimary,
                  onTap: _exportPdf,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _exportButton({
    required IconData icon,
    required String label,
    required Color background,
    required Color foreground,
    required VoidCallback onTap,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: _shadowSm,
      ),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: foreground),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(label,
                      overflow: TextOverflow.ellipsis,
                      style: _t(12, 16, FontWeight.w700, foreground)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Donut chart ─────────────────────────
class _DonutPainter extends CustomPainter {
  final List<double> fractions;
  final List<Color> colors;
  _DonutPainter(this.fractions, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    // Skala sama dengan SVG viewBox 100x100: radius 38, tebal 12.
    final scale = size.width / 100;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = 38 * scale;
    final stroke = 12 * scale;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = _C.surfaceContainer
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    var start = -math.pi / 2;
    for (var i = 0; i < fractions.length; i++) {
      if (fractions[i] <= 0) continue;
      final sweep = 2 * math.pi * fractions[i];
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..color = colors[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.butt,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => true;
}