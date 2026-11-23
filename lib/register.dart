import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'auth_store.dart';
import 'login.dart';
import 'main.dart';

const String _googleSvg = '''
<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/>
  <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/>
  <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l2.85-2.22.81-.63z" fill="#FBBC05"/>
  <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84c.87-2.6 3.3-4.52 6.16-4.52z" fill="#EA4335"/>
</svg>
''';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  static const _error = Color(0xFFBA1A1A);
  static const _tertiary = Color(0xFF784B00);
  static const _tertiaryContainer = Color(0xFF996100);

  final _formKey = GlobalKey<FormState>();
  final _nameC = TextEditingController();
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  final _confirmC = TextEditingController();

  bool _hidePass = true;
  bool _hideConfirm = true;
  bool _agree = false;
  bool _termsError = false;
  bool _loading = false;
  String? _serverError;

  @override
  void dispose() {
    _nameC.dispose();
    _emailC.dispose();
    _passC.dispose();
    _confirmC.dispose();
    super.dispose();
  }

  // ── Validasi ──
  String? _validateName(String? v) {
    if ((v ?? '').trim().isEmpty) return 'Nama lengkap wajib diisi';
    return null;
  }

  String? _validateEmail(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Email wajib diisi';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);
    return ok ? null : 'Format email tidak valid';
  }

  String? _validatePass(String? v) {
    if (v == null || v.isEmpty) return 'Password wajib diisi';
    if (v.length < 8) return 'Password minimal 8 karakter';
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v == null || v.isEmpty) return 'Konfirmasi password wajib diisi';
    if (v != _passC.text) return 'Password tidak sama';
    return null;
  }

  // Kekuatan password: 0 = kosong, 1 = lemah, 2 = sedang, 3 = sangat kuat
  int get _strength {
    final n = _passC.text.length;
    if (n == 0) return 0;
    if (n < 6) return 1;
    if (n < 10) return 2;
    return 3;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final formOk = _formKey.currentState!.validate();
    setState(() => _termsError = !_agree);
    if (!formOk || !_agree) return;

    setState(() {
      _loading = true;
      _serverError = null;
    });

    try {
      final created = AuthStore.register(
        name: _nameC.text,
        email: _emailC.text,
        password: _passC.text,
      );

      if (!mounted) return;
      if (!created) {
        setState(
          () =>
              _serverError =
                  'Email sudah terdaftar. Silakan masuk atau gunakan email lain.',
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Akun berhasil dibuat. Silakan masuk.')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _serverError = 'Pendaftaran gagal. Coba lagi nanti.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _dec(String hint, IconData icon, {Widget? suffix}) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: c, width: w),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: bodyMd(C.outline.withOpacity(0.7)),
      prefixIcon: Icon(icon, size: 20, color: C.outline),
      suffixIcon: suffix,
      filled: true,
      fillColor: C.containerLow,
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      border: border(Colors.transparent),
      enabledBorder: border(Colors.transparent),
      focusedBorder: border(C.primary, 2),
      errorBorder: border(_error),
      focusedErrorBorder: border(_error, 2),
      errorStyle: labelSm(_error),
    );
  }

  TextStyle get _labelMd => labelSm().copyWith(fontSize: 12, height: 16 / 12);

  Widget _eyeButton(bool hidden, VoidCallback onTap) => IconButton(
    icon: Icon(
      hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      size: 18,
      color: C.outline,
    ),
    onPressed: onTap,
  );

  @override
  Widget build(BuildContext context) {
    final level = _strength;
    final strengthColors = [C.outline, _error, _tertiaryContainer, C.secondary];
    final strengthLabelColors = [C.outline, _error, _tertiary, C.secondary];
    final strengthTexts = ['-', 'Lemah', 'Sedang', 'Sangat Kuat'];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: C.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 64,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 24, color: C.onSurface),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: C.primary,
                borderRadius: BorderRadius.circular(8),
                boxShadow: shadowSm,
              ),
              child: const Icon(
                Icons.sentiment_satisfied,
                size: 18,
                color: C.onPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Text.rich(
              TextSpan(
                text: 'Emo',
                children: const [
                  TextSpan(text: 'Sense', style: TextStyle(color: C.primary)),
                ],
              ),
              style: labelLg().copyWith(
                fontSize: 20,
                height: 28 / 20,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: C.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, size: 18, color: C.onPrimary),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Judul & badge peran ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: C.secondaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.badge, size: 16, color: C.secondary),
                    const SizedBox(width: 4),
                    Text(
                      'AKUN PENGGUNA PRIBADI',
                      style: labelSm(C.secondary).copyWith(letterSpacing: 0.55),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text('Buat Akun Pengguna', style: headline()),
              const SizedBox(height: 4),
              Text(
                'Bergabung untuk melacak ekspresi & suasana hatimu setiap hari.',
                style: bodyMd(C.onSurfaceVariant),
              ),
              const SizedBox(height: 24),

              // ── Kartu form ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: C.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: shadowMd,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Informasi Pendaftaran',
                            style: labelLg().copyWith(
                              fontSize: 18,
                              height: 28 / 18,
                            ),
                          ),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: C.primaryFixed,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lock_reset,
                              size: 15,
                              color: C.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_serverError != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFDAD6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 18,
                                color: _error,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _serverError!,
                                  style: bodySm(const Color(0xFF93000A)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Nama lengkap
                      Text('Nama Lengkap', style: _labelMd),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _nameC,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.name],
                        style: bodyMd(),
                        validator: _validateName,
                        decoration: _dec(
                          'Contoh: Rian Anggoro',
                          Icons.person_outline,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Email
                      Text('Email', style: _labelMd),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _emailC,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        style: bodyMd(),
                        validator: _validateEmail,
                        decoration: _dec('nama@email.com', Icons.mail_outline),
                      ),
                      const SizedBox(height: 16),

                      // Password + indikator kekuatan
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Buat Password', style: _labelMd),
                          Text(
                            'Kekuatan: ${strengthTexts[level]}',
                            style: labelSm(strengthLabelColors[level]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _passC,
                        obscureText: _hidePass,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newPassword],
                        style: bodyMd(),
                        validator: _validatePass,
                        onChanged: (_) => setState(() {}),
                        decoration: _dec(
                          'Minimal 8 karakter unik',
                          Icons.vpn_key_outlined,
                          suffix: _eyeButton(
                            _hidePass,
                            () => setState(() => _hidePass = !_hidePass),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          for (var i = 0; i < 3; i++) ...[
                            if (i > 0) const SizedBox(width: 4),
                            Expanded(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                height: 4,
                                decoration: BoxDecoration(
                                  color:
                                      i < level
                                          ? strengthColors[level]
                                          : C.containerHighest,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Konfirmasi password
                      Text('Konfirmasi Password', style: _labelMd),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _confirmC,
                        obscureText: _hideConfirm,
                        textInputAction: TextInputAction.done,
                        style: bodyMd(),
                        validator: _validateConfirm,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: _dec(
                          'Ketik ulang password',
                          Icons.check_circle_outline,
                          suffix: _eyeButton(
                            _hideConfirm,
                            () => setState(() => _hideConfirm = !_hideConfirm),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Persetujuan
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap:
                            () => setState(() {
                              _agree = !_agree;
                              if (_agree) _termsError = false;
                            }),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: const EdgeInsets.only(top: 2),
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: _agree ? C.primary : C.containerHigh,
                                borderRadius: BorderRadius.circular(6),
                                border:
                                    _termsError
                                        ? Border.all(color: _error, width: 1.5)
                                        : null,
                              ),
                              child:
                                  _agree
                                      ? const Icon(
                                        Icons.check,
                                        size: 16,
                                        color: C.onPrimary,
                                      )
                                      : null,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  style: bodySm(C.onSurfaceVariant),
                                  children: [
                                    const TextSpan(text: 'Saya menyetujui '),
                                    TextSpan(
                                      text: 'Ketentuan Layanan',
                                      style: labelSm(C.primary),
                                    ),
                                    const TextSpan(text: ' & '),
                                    TextSpan(
                                      text: 'Kebijakan Privasi Data Wajah',
                                      style: labelSm(C.secondary),
                                    ),
                                    const TextSpan(text: ' EmoSense.'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_termsError) ...[
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(left: 28),
                          child: Text(
                            'Anda harus menyetujui terlebih dahulu',
                            style: labelSm(_error),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Tombol daftar
                      SizedBox(
                        width: double.infinity,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: shadowMd,
                          ),
                          child: Material(
                            color:
                                _loading
                                    ? C.primary.withOpacity(0.6)
                                    : C.primary,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: _loading ? null : _submit,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (_loading)
                                      const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: C.onPrimary,
                                        ),
                                      )
                                    else ...[
                                      Text(
                                        'Daftar Akun Baru',
                                        style: labelLg(
                                          C.onPrimary,
                                        ).copyWith(fontSize: 16),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.arrow_forward,
                                        size: 18,
                                        color: C.onPrimary,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Daftar cepat ──
              Row(
                children: [
                  Expanded(child: Container(height: 1, color: C.containerHigh)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Atau daftar cepat', style: labelSm(C.outline)),
                  ),
                  Expanded(child: Container(height: 1, color: C.containerHigh)),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: shadowSm,
                  ),
                  child: Material(
                    color: C.white,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap:
                          () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Daftar dengan Google belum tersedia',
                              ),
                            ),
                          ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 16,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.string(
                              _googleSvg,
                              width: 20,
                              height: 20,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Daftar Cepat dengan Google',
                              style: labelLg(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Link ke Login ──
              Center(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Sudah punya akun?',
                      style: bodyMd(C.onSurfaceVariant),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap:
                          () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginPage(),
                            ),
                          ),
                      child: Text('Masuk di Sini', style: labelLg(C.primary)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
