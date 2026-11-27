import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const Color _blue = Color(0xFF2563EB);
const String _historyKey = 'web_scan_history_v1';
const String _profileNameKey = 'web_profile_name';
const String _themeKey = 'web_theme';

Future<void> start() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  runApp(EmoSenseWebApp(prefs: prefs));
}

class EmoSenseWebApp extends StatefulWidget {
  const EmoSenseWebApp({super.key, required this.prefs});

  final SharedPreferences prefs;

  @override
  State<EmoSenseWebApp> createState() => _EmoSenseWebAppState();
}

class _EmoSenseWebAppState extends State<EmoSenseWebApp> {
  int _tab = 0;
  late ThemeMode _theme;
  late final TextEditingController _name;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();

    final themeIndex = (widget.prefs.getInt(_themeKey) ?? 0).clamp(0, 2);
    _theme = ThemeMode.values[themeIndex];

    _name = TextEditingController(
      text: widget.prefs.getString(_profileNameKey) ?? 'Pengguna EmoSense',
    );

    _loadHistory();
  }

  void _loadHistory() {
    final savedHistory = widget.prefs.getStringList(_historyKey) ?? [];

    _history = [];
    for (final entry in savedHistory) {
      try {
        final decoded = jsonDecode(entry);
        if (decoded is Map) {
          _history.add(Map<String, dynamic>.from(decoded));
        }
      } catch (_) {
        // Abaikan data riwayat yang rusak agar aplikasi tetap dapat dibuka.
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final name = _name.text.trim();

    if (name.isEmpty) {
      _message('Nama tidak boleh kosong.');
      return;
    }

    await widget.prefs.setString(_profileNameKey, name);

    if (!mounted) return;
    setState(() {});
    _message('Profil berhasil disimpan.');
  }

  Future<void> _saveTheme(ThemeMode value) async {
    setState(() => _theme = value);
    await widget.prefs.setInt(_themeKey, value.index);
  }

  Future<void> _saveResult(String emotion, double confidence) async {
    final entry = <String, dynamic>{
      'emotion': emotion,
      'confidence': confidence,
      'time': DateTime.now().toIso8601String(),
    };

    if (!mounted) return;

    setState(() {
      _history.insert(0, entry);
    });

    await widget.prefs.setStringList(
      _historyKey,
      _history.map((item) => jsonEncode(item)).toList(),
    );
  }

  Future<void> _clearHistory() async {
    setState(() => _history.clear());
    await widget.prefs.remove(_historyKey);
  }

  void _message(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _WebScanPage(onResult: _saveResult),
      _WebHistoryPage(items: _history, onClear: _clearHistory),
      _WebProfilePage(name: _name, onSave: _saveName),
      _WebSettingsPage(theme: _theme, onThemeChanged: _saveTheme),
    ];

    return MaterialApp(
      title: 'EmoSense',
      debugShowCheckedModeBanner: false,
      themeMode: _theme,
      theme: ThemeData(
        colorSchemeSeed: _blue,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: _blue,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('EmoSense'),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Center(
                child: Text(
                  _name.text,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: IndexedStack(
              index: _tab,
              children: pages,
            ),
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (index) {
            setState(() => _tab = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.camera_alt),
              label: 'Pindai',
            ),
            NavigationDestination(
              icon: Icon(Icons.history),
              label: 'Riwayat',
            ),
            NavigationDestination(
              icon: Icon(Icons.person),
              label: 'Profil',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings),
              label: 'Pengaturan',
            ),
          ],
        ),
      ),
    );
  }
}

class _WebScanPage extends StatefulWidget {
  const _WebScanPage({required this.onResult});

  final Future<void> Function(String, double) onResult;

  @override
  State<_WebScanPage> createState() => _WebScanPageState();
}

class _WebScanPageState extends State<_WebScanPage> {
  CameraController? _camera;
  bool _opening = true;
  bool _scanning = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _openCamera();
  }

  @override
  void dispose() {
    _camera?.dispose();
    super.dispose();
  }

  Future<void> _openCamera() async {
    if (!mounted) return;

    setState(() {
      _opening = true;
      _error = null;
    });

    CameraController? newCamera;

    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        throw StateError('Kamera tidak ditemukan.');
      }

      final frontIndex = cameras.indexWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );

      final selectedCamera = cameras[frontIndex >= 0 ? frontIndex : 0];

      newCamera = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await newCamera.initialize();

      if (!mounted) {
        await newCamera.dispose();
        return;
      }

      final oldCamera = _camera;

      setState(() {
        _camera = newCamera;
        _opening = false;
        _error = null;
      });

      if (oldCamera != null && oldCamera != newCamera) {
        await oldCamera.dispose();
      }
    } catch (error) {
      await newCamera?.dispose();

      if (!mounted) return;

      setState(() {
        _camera = null;
        _opening = false;
        _error =
            'Kamera tidak dapat dibuka. Periksa izin kamera browser dan pastikan aplikasi dibuka melalui localhost atau HTTPS.\n\nDetail: $error';
      });
    }
  }

  Uri _apiUri() {
    final host = Uri.base.host.isEmpty ? '127.0.0.1' : Uri.base.host;

    return Uri(
      scheme: Uri.base.scheme == 'https' ? 'https' : 'http',
      host: host,
      port: 8000,
      path: '/api/predict',
    );
  }

  Future<void> _scan() async {
    final camera = _camera;

    if (camera == null || !camera.value.isInitialized || _scanning) {
      return;
    }

    setState(() => _scanning = true);

    try {
      final photo = await camera.takePicture();
      final bytes = await photo.readAsBytes();

      final request = http.MultipartRequest('POST', _apiUri())
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: 'scan.jpg',
          ),
        );

      final streamedResponse = await request
          .send()
          .timeout(const Duration(seconds: 30));

      final responseBody = await streamedResponse.stream.bytesToString();

      dynamic decodedBody;
      try {
        decodedBody = jsonDecode(responseBody);
      } catch (_) {
        throw FormatException(
          'Respons server bukan JSON yang valid. HTTP ${streamedResponse.statusCode}.',
        );
      }

      if (decodedBody is! Map) {
        throw const FormatException('Format respons server tidak sesuai.');
      }

      final body = Map<String, dynamic>.from(decodedBody);

      if (streamedResponse.statusCode != 200) {
        throw Exception(
          body['detail'] ?? body['message'] ?? 'Server mengembalikan HTTP ${streamedResponse.statusCode}.',
        );
      }

      if (body['face_detected'] == false) {
        throw const FormatException(
          'Wajah belum terdeteksi. Coba lagi dengan pencahayaan yang cukup.',
        );
      }

      final emotionValue = body['emotion'] ?? body['label'];
      if (emotionValue == null || emotionValue.toString().trim().isEmpty) {
        throw const FormatException(
          'Server tidak mengirimkan hasil emosi.',
        );
      }

      final emotion = emotionValue.toString();
      final rawConfidence = body['confidence'];
      final confidenceRaw =
          rawConfidence is num ? rawConfidence.toDouble() : 0.0;

      final confidence = confidenceRaw <= 1
          ? confidenceRaw * 100
          : confidenceRaw;

      await widget.onResult(emotion, confidence);

      if (!mounted) return;

      _notify(
        'Hasil: $emotion (${confidence.round()}%).',
      );
    } catch (error) {
      if (!mounted) return;

      _notify('Pemindaian gagal: $error');
    } finally {
      if (mounted) {
        setState(() => _scanning = false);
      }
    }
  }

  void _notify(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(text)),
      );
  }

  @override
  Widget build(BuildContext context) {
    final camera = _camera;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Pemindaian Ekspresi',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          const Text(
            'Izinkan browser menggunakan kamera untuk memulai.',
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: ColoredBox(
                color: Colors.black,
                child: Center(
                  child: _opening
                      ? const CircularProgressIndicator()
                      : _error != null
                          ? Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.no_photography,
                                    color: Colors.white,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _error!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  FilledButton(
                                    onPressed: _openCamera,
                                    child: const Text('Coba lagi'),
                                  ),
                                ],
                              ),
                            )
                          : camera != null && camera.value.isInitialized
                              ? CameraPreview(camera)
                              : const Text(
                                  'Kamera belum tersedia.',
                                  style: TextStyle(color: Colors.white),
                                ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: camera == null ||
                    !camera.value.isInitialized ||
                    _scanning
                ? null
                : _scan,
            icon: _scanning
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.face_retouching_natural),
            label: Text(
              _scanning ? 'Menganalisis...' : 'Ambil & Analisis',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Analisis memerlukan server aktif di port 8000.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _WebHistoryPage extends StatelessWidget {
  const _WebHistoryPage({
    required this.items,
    required this.onClear,
  });

  final List<Map<String, dynamic>> items;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Riwayat Pemindaian',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              TextButton.icon(
                onPressed: items.isEmpty ? null : onClear,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Hapus'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Expanded(
              child: Center(
                child: Text('Belum ada riwayat pemindaian.'),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final time =
                      DateTime.tryParse('${item['time']}')?.toLocal();
                  final rawConfidence = item['confidence'];
                  final confidence = rawConfidence is num
                      ? rawConfidence.toDouble()
                      : 0.0;

                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.mood),
                      ),
                      title: Text('${item['emotion'] ?? 'Tidak diketahui'}'),
                      subtitle: Text(
                        time?.toString() ?? 'Waktu tidak tersedia',
                      ),
                      trailing: Text('${confidence.round()}%'),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _WebProfilePage extends StatelessWidget {
  const _WebProfilePage({
    required this.name,
    required this.onSave,
  });

  final TextEditingController name;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Profil',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 24),
        const CircleAvatar(
          radius: 40,
          child: Icon(Icons.person, size: 42),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: name,
          decoration: const InputDecoration(
            labelText: 'Nama tampilan',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: onSave,
          child: const Text('Simpan Profil'),
        ),
      ],
    );
  }
}

class _WebSettingsPage extends StatelessWidget {
  const _WebSettingsPage({
    required this.theme,
    required this.onThemeChanged,
  });

  final ThemeMode theme;
  final ValueChanged<ThemeMode> onThemeChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Pengaturan',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 20),
        const ListTile(
          leading: Icon(Icons.camera_alt_outlined),
          title: Text('Kamera'),
          subtitle: Text(
            'Browser akan meminta izin saat kamera digunakan.',
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.palette_outlined),
          title: const Text('Tema aplikasi'),
          trailing: DropdownButton<ThemeMode>(
            value: theme,
            items: const [
              DropdownMenuItem(
                value: ThemeMode.light,
                child: Text('Terang'),
              ),
              DropdownMenuItem(
                value: ThemeMode.dark,
                child: Text('Gelap'),
              ),
              DropdownMenuItem(
                value: ThemeMode.system,
                child: Text('Sistem'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                onThemeChanged(value);
              }
            },
          ),
        ),
        const ListTile(
          leading: Icon(Icons.storage_outlined),
          title: Text('Penyimpanan'),
          subtitle: Text(
            'Profil dan riwayat disimpan di browser ini.',
          ),
        ),
      ],
    );
  }
}
