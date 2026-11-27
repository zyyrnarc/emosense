import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Alamat backend.
/// - Emulator Android : 10.0.2.2 = localhost komputer
/// - HP asli          : IP LAN komputer (mis. http://192.168.1.10:8000) atau domain https
///
/// Untuk http:// (non-HTTPS) di Android 9+, tambahkan di
/// android/app/src/main/AndroidManifest.xml pada tag <application>:
///   android:usesCleartextTraffic="true"
/// dan pastikan ada <uses-permission android:name="android.permission.INTERNET"/>
/// di luar tag <application>.
const String kBaseUrl = 'http://192.168.0.101:8000';

// ───────────────────────── Data emosi ─────────────────────────
class EmotionMeta {
  final String key, emoji, title, desc, bubble, label;
  final Color color;
  const EmotionMeta(this.key, this.emoji, this.title, this.desc, this.bubble,
      this.label, this.color);
}

const Map<String, EmotionMeta> _metas = {
  'happy': EmotionMeta('happy', '😊', 'Bahagia / Senang',
      'Ekspresi riang dan bersemangat', 'Senyum Terdeteksi!', 'Senang',
      Color(0xFF6CF8BB)),
  'neutral': EmotionMeta('neutral', '😐', 'Netral',
      'Ekspresi tenang dan datar', 'Wajah Netral Terdeteksi', 'Netral',
      Color(0xFFB4C5FF)),
  'surprise': EmotionMeta('surprise', '😲', 'Terkejut',
      'Ekspresi kaget atau tak menduga', 'Ekspresi Terkejut!', 'Terkejut',
      Color(0xFFFFB95F)),
  'sad': EmotionMeta('sad', '😢', 'Sedih', 'Ekspresi murung atau kecewa',
      'Wajah Sedih Terdeteksi', 'Sedih', Color(0xFF8FA8E8)),
  'angry': EmotionMeta('angry', '😠', 'Marah', 'Ekspresi kesal atau tegang',
      'Wajah Marah Terdeteksi', 'Marah', Color(0xFFFF8A80)),
  'fear': EmotionMeta('fear', '😨', 'Takut', 'Ekspresi cemas atau khawatir',
      'Wajah Takut Terdeteksi', 'Takut', Color(0xFFC4B5FD)),
  'disgust': EmotionMeta('disgust', '🤢', 'Jijik',
      'Ekspresi tidak suka', 'Wajah Jijik Terdeteksi', 'Jijik',
      Color(0xFFA3D977)),
};

const Map<String, String> _alias = {
  'happiness': 'happy', 'senang': 'happy', 'bahagia': 'happy',
  'netral': 'neutral',
  'surprised': 'surprise', 'terkejut': 'surprise',
  'sadness': 'sad', 'sedih': 'sad',
  'anger': 'angry', 'marah': 'angry',
  'fearful': 'fear', 'takut': 'fear',
  'disgusted': 'disgust', 'jijik': 'disgust',
};

String normalizeEmotion(String raw) {
  final k = raw.trim().toLowerCase();
  if (_metas.containsKey(k)) return k;
  return _alias[k] ?? 'neutral';
}

EmotionMeta emotionMeta(String raw) => _metas[normalizeEmotion(raw)]!;
List<EmotionMeta> get allEmotions => _metas.values.toList();

class OtherEmotion {
  final String key;
  final double percent;
  const OtherEmotion(this.key, this.percent);
}

double? _toDouble(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

class EmotionResult {
  final String key;
  final double confidence; // 0–100
  final List<OtherEmotion> others;
  final String? personName; // hasil pengenalan wajah (opsional)
  final bool corrected; // sudah dikoreksi manual oleh pengguna

  const EmotionResult({
    required this.key,
    required this.confidence,
    this.others = const [],
    this.personName,
    this.corrected = false,
  });

  /// Format JSON yang diharapkan dari POST /api/predict:
  /// {
  ///   "emotion": "happy",
  ///   "confidence": 96.8,                       // boleh 0–1 atau 0–100
  ///   "probabilities": {"happy":96.8,"neutral":2.1,"surprise":1.1},
  ///   "name": "Sinta Rahayu"                    // opsional
  /// }
  factory EmotionResult.fromJson(Map<String, dynamic> j) {
    final probs = <String, double>{};
    final raw = j['probabilities'] ?? j['scores'];
    if (raw is Map) {
      raw.forEach((k, v) {
        final d = _toDouble(v);
        if (d == null) return;
        final nk = normalizeEmotion('$k');
        // Jika beberapa alias menuju kunci yang sama, ambil yang terbesar.
        probs[nk] = math.max(probs[nk] ?? 0.0, d);
      });
    }

    String? top = (j['emotion'] ?? j['label'])?.toString();
    if (top == null && probs.isNotEmpty) {
      top = probs.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    }
    final key = normalizeEmotion(top ?? 'neutral');

    var conf = _toDouble(j['confidence']) ?? probs[key] ?? 0.0;

    // Deteksi skala (0–1 atau 0–100) dari semua nilai yang ada.
    final maxVal = [conf, ...probs.values].reduce(math.max);
    final scale = maxVal <= 1.0 ? 100.0 : 1.0;
    double r1(double v) => double.parse((v * scale).toStringAsFixed(1));
    conf = r1(conf);

    final others = probs.entries
        .where((e) => e.key != key)
        .map((e) => OtherEmotion(e.key, r1(e.value)))
        .toList()
      ..sort((a, b) => b.percent.compareTo(a.percent));

    final name = (j['name'] ?? j['person'])?.toString().trim();

    return EmotionResult(
      key: key,
      confidence: conf,
      others: others.take(2).toList(),
      personName: (name == null || name.isEmpty) ? null : name,
    );
  }
}

// ───────────────────────── API ─────────────────────────
class EmotionApi {
  static const _timeout = Duration(seconds: 20);

  /// Mengembalikan null jika wajah tidak terdeteksi.
  /// Nama field file = "file" (ubah jika backend memakai nama lain, mis. "image").
  /// Melempar TimeoutException / SocketException / HttpException / FormatException
  /// untuk kesalahan jaringan atau server — tangani di pemanggil.
  static Future<EmotionResult?> predict(File image) async {
    final res = await () async {
      final req =
          http.MultipartRequest('POST', Uri.parse('$kBaseUrl/api/predict'))
            ..files.add(await http.MultipartFile.fromPath('file', image.path));
      final streamed = await req.send();
      return http.Response.fromStream(streamed);
    }()
        .timeout(_timeout); // timeout mencakup seluruh request + respons

    if (res.statusCode == 400 || res.statusCode == 404) return null;
    if (res.statusCode != 200) {
      throw HttpException('Server ${res.statusCode}');
    }
    final j = jsonDecode(utf8.decode(res.bodyBytes));
    if (j is! Map<String, dynamic>) {
      throw const FormatException('Respons tidak valid');
    }
    if (j['face_detected'] == false) return null;
    return EmotionResult.fromJson(j);
  }

  /// Kirim umpan balik (best effort, gagal diabaikan).
  static Future<void> sendFeedback({
    required String predicted,
    required bool correct,
    String? corrected,
  }) async {
    try {
      await http
          .post(
            Uri.parse('$kBaseUrl/api/feedback'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'predicted': predicted,
              'correct': correct,
              if (corrected != null) 'corrected': corrected,
            }),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
  }
}

// ───────────────────────── Riwayat ─────────────────────────
class HistoryItem {
  final String id;
  String key;
  final double confidence;
  final String? name;
  final DateTime time;
  final String? imagePath;

  HistoryItem({
    required this.id,
    required this.key,
    required this.confidence,
    required this.time,
    this.name,
    this.imagePath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'key': key,
        'confidence': confidence,
        'name': name,
        'time': time.millisecondsSinceEpoch,
        'imagePath': imagePath,
      };

  factory HistoryItem.fromJson(Map<String, dynamic> j) {
    // Jika file gambar sudah tidak ada, tetap muat entrinya tanpa gambar.
    var path = j['imagePath'] as String?;
    if (path != null && !File(path).existsSync()) path = null;

    return HistoryItem(
      id: j['id'] as String,
      key: normalizeEmotion(j['key'] as String),
      confidence: (j['confidence'] as num).toDouble(),
      name: j['name'] as String?,
      time: DateTime.fromMillisecondsSinceEpoch(j['time'] as int),
      imagePath: path,
    );
  }
}

class HistoryStore extends ChangeNotifier {
  HistoryStore._();
  static final HistoryStore instance = HistoryStore._();

  static const _prefKey = 'scan_history_v1';
  static const _maxItems = 50;
  final List<HistoryItem> items = [];

  // Antrean agar penyimpanan beruntun tidak saling menimpa.
  Future<void> _saveQueue = Future.value();

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final s = p.getString(_prefKey);
      if (s == null) return;

      final loaded = <HistoryItem>[];
      for (final e in (jsonDecode(s) as List)) {
        try {
          loaded.add(HistoryItem.fromJson(e as Map<String, dynamic>));
        } catch (_) {
          // lewati entri yang rusak, jangan gagalkan seluruh riwayat
        }
      }
      items
        ..clear()
        ..addAll(loaded);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _save() {
    _saveQueue = _saveQueue.then((_) async {
      try {
        final p = await SharedPreferences.getInstance();
        await p.setString(
            _prefKey, jsonEncode(items.map((e) => e.toJson()).toList()));
      } catch (_) {}
    });
    return _saveQueue;
  }

  Future<void> _deleteFile(String? path) async {
    if (path == null) return;
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  Future<HistoryItem> add(EmotionResult r, File image) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    String? saved;
    try {
      final dir = await getApplicationDocumentsDirectory();
      saved = '${dir.path}/scan_$id.jpg';
      await image.copy(saved);
    } catch (_) {
      saved = null;
    }
    final item = HistoryItem(
      id: id,
      key: r.key,
      confidence: r.confidence,
      name: r.personName,
      time: DateTime.now(),
      imagePath: saved,
    );
    items.insert(0, item);
    if (items.length > _maxItems) {
      await _deleteFile(items.removeLast().imagePath);
    }
    notifyListeners();
    await _save();
    return item;
  }

  Future<void> relabel(String id, String key) async {
    final i = items.indexWhere((e) => e.id == id);
    if (i < 0) return;
    items[i].key = normalizeEmotion(key);
    notifyListeners();
    await _save();
  }

  Future<void> remove(String id) async {
    final i = items.indexWhere((e) => e.id == id);
    if (i < 0) return;
    await _deleteFile(items.removeAt(i).imagePath);
    notifyListeners();
    await _save();
  }

  Future<void> clear() async {
    final paths = items.map((e) => e.imagePath).toList();
    items.clear();
    notifyListeners();
    for (final p in paths) {
      await _deleteFile(p);
    }
    await _save();
  }
}

// ───────────────────────── Bagikan & stiker ─────────────────────────
class ShareHelper {
  /// Tangkap widget (dibungkus RepaintBoundary) menjadi PNG.
  static Future<File> captureBoundary(GlobalKey key,
      {double pixelRatio = 3}) async {
    final b = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (b == null) throw StateError('Tampilan belum siap');
    final img = await b.toImage(pixelRatio: pixelRatio);
    return _writePng(img, 'hasil');
  }

  /// Buat stiker emoji PNG transparan 512×512.
  static Future<File> emojiSticker(String emoji) async {
    const s = 512.0;
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec);
    final tp = TextPainter(
      text: TextSpan(text: emoji, style: const TextStyle(fontSize: 380)),
      textDirection: TextDirection.ltr,
    )..layout();

    // Skalakan agar emoji tidak terpotong jika glyph lebih besar dari kanvas.
    final fit = math.min(1.0, math.min(s / tp.width, s / tp.height));
    canvas.translate(s / 2, s / 2);
    canvas.scale(fit);
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    tp.dispose();

    final img = await rec.endRecording().toImage(s.toInt(), s.toInt());
    return _writePng(img, 'stiker');
  }

  static Future<File> _writePng(ui.Image img, String prefix) async {
    try {
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('Gagal membuat gambar');
      final dir = await getTemporaryDirectory();
      final f = File(
          '${dir.path}/${prefix}_${DateTime.now().millisecondsSinceEpoch}.png');
      return await f.writeAsBytes(data.buffer.asUint8List(), flush: true);
    } finally {
      img.dispose();
    }
  }

  static Future<void> shareFile(File f, String text) async {
    await Share.shareXFiles([XFile(f.path)], text: text);
  }
}