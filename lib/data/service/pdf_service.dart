import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import 'emotion_service.dart';

/// Membuat PDF "Mood Diary" dari daftar riwayat scan.
/// Catatan: PDF memakai font bawaan (Helvetica), jadi hindari emoji / simbol
/// khusus di teks. Gunakan huruf latin biasa saja.
class PdfService {
  static const _labels = ['Bahagia', 'Tenang', 'Kaget', 'Lainnya'];

  static final _colors = [
    PdfColor.fromHex('#006C49'), // Bahagia
    PdfColor.fromHex('#2563EB'), // Tenang
    PdfColor.fromHex('#996100'), // Kaget
    PdfColor.fromHex('#737686'), // Lainnya
  ];

  static int _cat(String key) {
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

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String _fmt(DateTime t) =>
      '${_two(t.day)}/${_two(t.month)}/${t.year}  ${_two(t.hour)}:${_two(t.minute)}';

  /// Buat file PDF di folder sementara, lalu kembalikan file-nya.
  static Future<File> buildMoodDiary({
    required List<HistoryItem> items,
    required String periodLabel,
  }) async {
    final total = items.length;
    final counts = List<int>.filled(_labels.length, 0);
    for (final e in items) {
      counts[_cat(e.key)]++;
    }
    final now = DateTime.now();

    final doc = pw.Document(title: 'Mood Diary - Sensio AI', author: 'Sensio AI');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (ctx) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Halaman ${ctx.pageNumber} dari ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (ctx) => [
          // ── Header ──
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#2563EB'),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Mood Diary',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Sensio AI  |  Periode: $periodLabel  |  Dibuat: ${_fmt(now)}',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.white),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // ── Ringkasan ──
          pw.Text(
            'Ringkasan',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text('Total pemindaian: $total'),
          pw.Text(
            total == 0
                ? 'Belum ada ekspresi terdeteksi.'
                : 'Ekspresi bahagia terdeteksi ${counts[0]} kali '
                    '(${(counts[0] / total * 100).round()}% dari total).',
          ),
          pw.SizedBox(height: 16),

          // ── Komposisi (batang persentase) ──
          pw.Text(
            'Komposisi Suasana Hati',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          for (var i = 0; i < _labels.length; i++) _bar(i, counts[i], total),
          pw.SizedBox(height: 20),

          // ── Tabel riwayat ──
          pw.Text(
            'Riwayat Pemindaian',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Waktu', 'Ekspresi', 'Keyakinan', 'Nama'],
            headerStyle: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration:
                pw.BoxDecoration(color: PdfColor.fromHex('#004AC6')),
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellPadding:
                const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            oddRowDecoration:
                pw.BoxDecoration(color: PdfColor.fromHex('#F2F3FF')),
            data: [
              for (final e in items.take(200))
                [
                  _fmt(e.time),
                  emotionMeta(e.key).label,
                  '${e.confidence}%',
                  e.name ?? '-',
                ],
            ],
          ),
          if (items.length > 200)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 6),
              child: pw.Text(
                '... dan ${items.length - 200} catatan lainnya.',
                style: const pw.TextStyle(
                    fontSize: 9, color: PdfColors.grey600),
              ),
            ),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/mood_diary_${DateTime.now().millisecondsSinceEpoch}.pdf');
    return file.writeAsBytes(await doc.save());
  }

  /// Buat PDF lalu buka share sheet (simpan / kirim ke WhatsApp, Drive, dll).
  static Future<void> shareMoodDiary({
    required List<HistoryItem> items,
    required String periodLabel,
  }) async {
    final file =
        await buildMoodDiary(items: items, periodLabel: periodLabel);
    await Share.shareXFiles([XFile(file.path)], text: 'Mood Diary - Sensio AI');
  }

  // Satu baris batang: label | batang berwarna | jumlah & persen
  static pw.Widget _bar(int i, int count, int total) {
    final pct = total == 0 ? 0 : (count / total * 100).round().clamp(0, 100);
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 64, child: pw.Text(_labels[i])),
          pw.Expanded(
            child: pw.Row(
              children: [
                if (pct > 0)
                  pw.Expanded(
                    flex: pct,
                    child: pw.Container(height: 10, color: _colors[i]),
                  ),
                pw.Expanded(
                  flex: 100 - pct == 0 ? 1 : 100 - pct,
                  child: pw.Container(
                    height: 10,
                    color: pct == 100 ? _colors[i] : PdfColors.grey200,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(
            width: 70,
            child: pw.Text('$count x ($pct%)', textAlign: pw.TextAlign.right),
          ),
        ],
      ),
    );
  }
}