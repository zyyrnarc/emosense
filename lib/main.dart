import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import 'login.dart';
import 'register.dart';

void main() => runApp(const EmoSenseApp());

// ───────────────────────── Warna (dari desain Stitch) ─────────────────────────
class C {
  static const surface = Color(0xFFFAF8FF);
  static const onSurface = Color(0xFF131B2E);
  static const onSurfaceVariant = Color(0xFF434655);
  static const outline = Color(0xFF737686);
  static const outlineVariant = Color(0xFFC3C6D7);
  static const primary = Color(0xFF004AC6);
  static const primaryContainer = Color(0xFF2563EB);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryFixed = Color(0xFFDBE1FF);
  static const secondary = Color(0xFF006C49);
  static const secondaryFixed = Color(0xFF6FFBBE);
  static const secondaryContainer = Color(0xFF6CF8BB);
  static const onSecondaryContainer = Color(0xFF00714D);
  static const onSecondaryFixed = Color(0xFF002113);
  static const onSecondaryFixedVariant = Color(0xFF005236);
  static const white = Color(0xFFFFFFFF);
  static const containerLow = Color(0xFFF2F3FF);
  static const containerHigh = Color(0xFFE2E7FF);
  static const containerHighest = Color(0xFFDAE2FD);
}

// ───────────────────────── Gaya teks & bayangan ─────────────────────────
TextStyle _t(
  double size,
  double line,
  FontWeight w,
  Color color, {
  double ls = 0,
}) => GoogleFonts.plusJakartaSans(
  fontSize: size,
  height: line / size,
  fontWeight: w,
  color: color,
  letterSpacing: ls,
);

TextStyle labelLg([Color c = C.onSurface]) => _t(14, 20, FontWeight.w600, c);
TextStyle labelSm([Color c = C.onSurface]) => _t(11, 14, FontWeight.w600, c);
TextStyle bodyMd([Color c = C.onSurface]) => _t(14, 20, FontWeight.w400, c);
TextStyle bodySm([Color c = C.onSurface]) => _t(12, 16, FontWeight.w400, c);
TextStyle headline([Color c = C.onSurface]) =>
    _t(28, 36, FontWeight.w700, c, ls: -0.7);

final List<BoxShadow> shadowSm = [
  BoxShadow(
    color: Colors.black.withOpacity(0.05),
    blurRadius: 2,
    offset: const Offset(0, 1),
  ),
];
final List<BoxShadow> shadowMd = [
  BoxShadow(
    color: Colors.black.withOpacity(0.10),
    blurRadius: 6,
    spreadRadius: -1,
    offset: const Offset(0, 4),
  ),
  BoxShadow(
    color: Colors.black.withOpacity(0.10),
    blurRadius: 4,
    spreadRadius: -2,
    offset: const Offset(0, 2),
  ),
];

// ───────────────────────── App ─────────────────────────
class EmoSenseApp extends StatelessWidget {
  const EmoSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EmoSense',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: C.surface,
        colorScheme: ColorScheme.fromSeed(seedColor: C.primary),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
      ),
      home: const WelcomePage(),
    );
  }
}

// ───────────────────────── Data mood ─────────────────────────
class Mood {
  final String emoji, label, percent, status;
  const Mood(this.emoji, this.label, this.percent, this.status);
}

const moods = [
  Mood('😊', 'Bahagia', '99.2%', 'Status: Bahagia & Berenergi'),
  Mood('😌', 'Tenang', '96.8%', 'Status: Damai & Rileks'),
  Mood('😃', 'Antusias', '97.5%', 'Status: Penuh Semangat & Fokus'),
];

// ───────────────────────── Halaman Welcome ─────────────────────────
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  int selected = 0;

  void _open(String title) {
    final page = switch (title) {
      'Daftar' => const RegisterPage(),
      'Masuk' => const LoginPage(),
      _ => PlaceholderPage(title: title),
    };
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            children: [
              const BrandHeader(),
              const SizedBox(height: 24),
              _showcaseCard(),
              const SizedBox(height: 24),
              BenefitTile(
                icon: Icons.sensor_occupied,
                iconColor: C.primary,
                gradient: [C.primaryFixed, C.primary.withOpacity(0.15)],
                borderColor: C.primary.withOpacity(0.10),
                title: 'Deteksi Ekspresi Instan',
                body:
                    'Kamera memindai mikro-ekspresi secara real-time tanpa jeda.',
              ),
              const SizedBox(height: 10),
              BenefitTile(
                icon: Icons.query_stats,
                iconColor: C.secondary,
                gradient: [C.secondaryFixed, C.secondary.withOpacity(0.15)],
                borderColor: C.secondary.withOpacity(0.10),
                title: 'Jurnal Mood Otomatis',
                body:
                    'Laporan harian komprehensif untuk memahami tren emosionalmu.',
              ),
              const SizedBox(height: 10),
              BenefitTile(
                icon: Icons.enhanced_encryption,
                iconColor: C.primary,
                gradient: [C.containerHighest, C.primaryFixed.withOpacity(0.4)],
                borderColor: C.outlineVariant.withOpacity(0.3),
                title: 'Privasi Aman & Terenkripsi',
                body:
                    '100% On-Device AI: gambar dan video tidak pernah diunggah ke cloud.',
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified_user, size: 16, color: C.secondary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '100% Aman & Terenkripsi di Perangkat',
                      style: labelSm(C.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: shadowMd,
                ),
                child: Material(
                  color: C.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _open('Daftar'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Mulai Sekarang', style: labelLg(C.onPrimary)),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward,
                            size: 18,
                            color: C.onPrimary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Material(
                color: C.containerLow,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _open('Masuk'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Sudah Memiliki Akun?',
                          style: labelLg(C.onSurfaceVariant),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Masuk',
                          style: labelLg(C.primary).copyWith(
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                            decorationColor: C.primary.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _showcaseCard() {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: C.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: shadowMd,
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -40,
            child: _glow(144, C.secondaryFixed.withOpacity(0.25)),
          ),
          Positioned(
            bottom: -32,
            left: -32,
            child: _glow(128, C.primaryFixed.withOpacity(0.30)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: C.containerLow,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const PingDot(),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Deteksi Wajah Aktif',
                                overflow: TextOverflow.ellipsis,
                                style: labelSm(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: C.containerHighest,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt, size: 14, color: C.primary),
                          const SizedBox(width: 4),
                          Text(
                            '98% Akurasi',
                            style: labelSm(C.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    for (var i = 0; i < moods.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(child: _pill(i)),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: C.containerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: C.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.psychology_alt,
                          size: 18,
                          color: C.primaryContainer,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              moods[selected].status,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: labelSm(),
                            ),
                            Text(
                              'Diproses instan pada chip lokal',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: bodySm(C.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.check_circle,
                        size: 18,
                        color: C.secondary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glow(double size, Color color) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
      ),
    ),
  );

  Widget _pill(int i) {
    final m = moods[i];
    final on = i == selected;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => selected = i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: on ? C.secondaryFixed.withOpacity(0.4) : C.containerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(m.emoji, style: const TextStyle(fontSize: 24, height: 1.33)),
            const SizedBox(height: 4),
            Text(
              m.label,
              style: labelSm(on ? C.onSecondaryFixedVariant : C.onSurface),
            ),
            const SizedBox(height: 2),
            Text(
              m.percent,
              style: labelSm(
                on ? C.secondary : C.outline,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Header logo + judul ─────────────────────────
const String _logoSvg = '''
<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="haloGrad" x1="8" y1="8" x2="40" y2="40" gradientUnits="userSpaceOnUse">
      <stop offset="0" stop-color="#004ac6"/>
      <stop offset="1" stop-color="#4edea3"/>
    </linearGradient>
    <linearGradient id="brandStroke" x1="6" y1="6" x2="42" y2="42" gradientUnits="userSpaceOnUse">
      <stop offset="0" stop-color="#2563eb"/>
      <stop offset="1" stop-color="#006c49"/>
    </linearGradient>
  </defs>
  <circle cx="24" cy="24" r="19" fill="url(#haloGrad)" fill-opacity="0.15"/>
  <circle cx="24" cy="24" r="18" stroke="url(#brandStroke)" stroke-width="2" stroke-dasharray="3 2.5" stroke-opacity="0.6"/>
  <circle cx="17" cy="19" r="2.5" fill="#004ac6"/>
  <circle cx="31" cy="19" r="2.5" fill="#004ac6"/>
  <path d="M16 27C17.8 31.5 30.2 31.5 32 27" stroke="#004ac6" stroke-width="2.5" stroke-linecap="round"/>
  <circle cx="14" cy="24" r="1" fill="#006c49"/>
  <circle cx="34" cy="24" r="1" fill="#006c49"/>
  <circle cx="24" cy="12" r="1" fill="#006c49"/>
  <circle cx="24" cy="35" r="1" fill="#006c49"/>
  <path d="M9 16L9 11C9 9.9 9.9 9 11 9L16 9" stroke="#2563eb" stroke-width="1.8" stroke-linecap="round"/>
  <path d="M39 16L39 11C39 9.9 38.1 9 37 9L32 9" stroke="#2563eb" stroke-width="1.8" stroke-linecap="round"/>
  <path d="M9 32L9 37C9 38.1 9.9 39 11 39L16 39" stroke="#2563eb" stroke-width="1.8" stroke-linecap="round"/>
  <path d="M39 32L39 37C39 38.1 38.1 39 37 39L32 39" stroke="#2563eb" stroke-width="1.8" stroke-linecap="round"/>
</svg>
''';

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: shadowMd,
                  gradient: LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: [
                      C.primary.withOpacity(0.2),
                      C.containerHigh,
                      C.secondaryFixed.withOpacity(0.3),
                    ],
                  ),
                ),
                child: Container(
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: C.white,
                    shape: BoxShape.circle,
                  ),
                  child: SvgPicture.string(_logoSvg, width: 48, height: 48),
                ),
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: C.secondaryContainer,
                    shape: BoxShape.circle,
                    border: Border.all(color: C.surface, width: 2),
                    boxShadow: shadowSm,
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 14,
                    color: C.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text.rich(
              TextSpan(
                text: 'Emo',
                children: const [
                  TextSpan(
                    text: 'Sense',
                    style: TextStyle(color: C.primaryContainer),
                  ),
                ],
              ),
              style: headline(),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: C.secondaryFixed,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('AI v2.4', style: labelSm(C.onSecondaryFixed)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Text(
            'Kenali dan Pantau Suasana Hatimu Secara Real-Time dengan Cerdas & Lembut',
            textAlign: TextAlign.center,
            style: bodyMd(C.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── Kartu keunggulan ─────────────────────────
class BenefitTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor, borderColor;
  final List<Color> gradient;
  final String title, body;

  const BenefitTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.gradient,
    required this.borderColor,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: C.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: shadowSm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
              boxShadow: shadowSm,
              gradient: LinearGradient(
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                colors: gradient,
              ),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: labelLg()),
                Text(body, style: bodySm(C.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Titik berdenyut ─────────────────────────
class PingDot extends StatefulWidget {
  const PingDot({super.key});

  @override
  State<PingDot> createState() => _PingDotState();
}

class _PingDotState extends State<PingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const dot = BoxDecoration(color: C.secondary, shape: BoxShape.circle);
    return SizedBox(
      width: 8,
      height: 8,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedBuilder(
            animation: _c,
            builder:
                (_, __) => Opacity(
                  opacity: 0.75 * (1 - _c.value),
                  child: Transform.scale(
                    scale: 1 + _c.value,
                    child: Container(decoration: dot),
                  ),
                ),
          ),
          Container(decoration: dot),
        ],
      ),
    );
  }
}

// ───────────────────────── Halaman sementara (Masuk / Daftar) ─────────────────────────
class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('Halaman $title (belum dibuat)')),
    );
  }
}
