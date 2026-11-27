import 'package:flutter/material.dart';

import '../../data/stores/auth_store.dart';
import 'login.dart';
import '../pages/user/user_home_page.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

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

  // Validasi
  String? _validateName(String? v) {
    if ((v ?? '').trim().isEmpty) {
      return 'Nama lengkap wajib diisi';
    }
    return null;
  }

  String? _validateEmail(String? v) {
    final s = (v ?? '').trim();

    if (s.isEmpty) return 'Email wajib diisi';

    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
        .hasMatch(s);

    return ok ? null : 'Format email tidak valid';
  }

  String? _validatePass(String? v) {
    if (v == null || v.isEmpty) {
      return 'Password wajib diisi';
    }

    if (v.length < 8) {
      return 'Password minimal 8 karakter';
    }

    return null;
  }

  String? _validateConfirm(String? v) {
    if (v == null || v.isEmpty) {
      return 'Konfirmasi password wajib diisi';
    }

    if (v != _passC.text) {
      return 'Password tidak sama';
    }

    return null;
  }

  // Kekuatan password
  // 0 = kosong, 1 = lemah, 2 = sedang, 3 = sangat kuat
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
      final created = await AuthStore.register(
        name: _nameC.text,
        email: _emailC.text,
        password: _passC.text,
      );

      if (!mounted) return;

      if (!created) {
        setState(() {
          _serverError =
              'Email sudah terdaftar. Silakan masuk atau gunakan email lain.';
        });
        return;
      }

      final user = AuthStore.currentUser;

      if (user == null) {
        throw StateError(
          'Akun berhasil dibuat tetapi sesi tidak tersedia.',
        );
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => UserHomePage(user: user),
        ),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _serverError = 'Pendaftaran gagal. Coba lagi nanti.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  InputDecoration _dec(
    String hint,
    IconData icon, {
    Widget? suffix,
  }) {
    OutlineInputBorder border(Color c, [double w = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: c, width: w),
      );
    }

    return InputDecoration(
      hintText: hint,
      hintStyle: AppText.bodyMd(
        AppColors.outline.withOpacity(0.7),
      ),
      prefixIcon: Icon(
        icon,
        size: 20,
        color: AppColors.outline,
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.surfaceContainerLow,
      contentPadding: const EdgeInsets.symmetric(
        vertical: 12,
        horizontal: 12,
      ),
      border: border(Colors.transparent),
      enabledBorder: border(Colors.transparent),
      focusedBorder: border(AppColors.primary, 2),
      errorBorder: border(_error),
      focusedErrorBorder: border(_error, 2),
      errorStyle: AppText.labelSm(_error),
    );
  }

  TextStyle get _labelMd =>
      AppText.labelSm().copyWith(
        fontSize: 12,
        height: 16 / 12,
      );

  Widget _eyeButton(
    bool hidden,
    VoidCallback onTap,
  ) =>
      IconButton(
        icon: Icon(
          hidden
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          size: 18,
          color: AppColors.outline,
        ),
        onPressed: onTap,
      );

  @override
  Widget build(BuildContext context) {
    final level = _strength;

    final strengthColors = [
      AppColors.outline,
      _error,
      _tertiaryContainer,
      AppColors.secondary,
    ];

    final strengthLabelColors = [
      AppColors.outline,
      _error,
      _tertiary,
      AppColors.secondary,
    ];

    final strengthTexts = [
      '-',
      'Lemah',
      'Sedang',
      'Sangat Kuat',
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 64,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            size: 24,
            color: AppColors.onSurface,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
                boxShadow: AppShadows.sm,
              ),
              child: const Icon(
                Icons.sentiment_satisfied,
                size: 18,
                color: AppColors.onPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Text.rich(
              TextSpan(
                text: 'Emo',
                children: const [
                  TextSpan(
                    text: 'Sense',
                    style: TextStyle(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              style: AppText.labelLg().copyWith(
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
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                size: 18,
                color: AppColors.onPrimary,
              ),
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
              // Judul dan badge peran
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.badge,
                      size: 16,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'AKUN PENGGUNA PRIBADI',
                      style: AppText.labelSm(
                        AppColors.secondary,
                      ).copyWith(letterSpacing: 0.55),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Buat Akun Pengguna',
                style: AppText.headlineXlMobile(),
              ),

              const SizedBox(height: 4),

              Text(
                'Bergabung untuk melacak ekspresi & suasana hatimu setiap hari.',
                style: AppText.bodyMd(
                  AppColors.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 24),

              // Kartu form
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppShadows.md,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Informasi Pendaftaran',
                            style: AppText.labelLg().copyWith(
                              fontSize: 18,
                              height: 28 / 18,
                            ),
                          ),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryFixed,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lock_reset,
                              size: 15,
                              color: AppColors.primary,
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
                                  style: AppText.bodySm(
                                    const Color(0xFF93000A),
                                  ),
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
                        textCapitalization:
                            TextCapitalization.words,
                        autofillHints: const [
                          AutofillHints.name,
                        ],
                        style: AppText.bodyMd(),
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
                        keyboardType:
                            TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [
                          AutofillHints.email,
                        ],
                        style: AppText.bodyMd(),
                        validator: _validateEmail,
                        decoration: _dec(
                          'nama@email.com',
                          Icons.mail_outline,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Password dan indikator kekuatan
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Buat Password',
                            style: _labelMd,
                          ),
                          Text(
                            'Kekuatan: ${strengthTexts[level]}',
                            style: AppText.labelSm(
                              strengthLabelColors[level],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      TextFormField(
                        controller: _passC,
                        obscureText: _hidePass,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [
                          AutofillHints.newPassword,
                        ],
                        style: AppText.bodyMd(),
                        validator: _validatePass,
                        onChanged: (_) => setState(() {}),
                        decoration: _dec(
                          'Minimal 8 karakter unik',
                          Icons.vpn_key_outlined,
                          suffix: _eyeButton(
                            _hidePass,
                            () => setState(
                              () => _hidePass = !_hidePass,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          for (var i = 0; i < 3; i++) ...[
                            if (i > 0)
                              const SizedBox(width: 4),
                            Expanded(
                              child: AnimatedContainer(
                                duration: const Duration(
                                  milliseconds: 200,
                                ),
                                height: 4,
                                decoration: BoxDecoration(
                                  color: i < level
                                      ? strengthColors[level]
                                      : AppColors
                                          .surfaceContainerHighest,
                                  borderRadius:
                                      BorderRadius.circular(999),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Konfirmasi password
                      Text(
                        'Konfirmasi Password',
                        style: _labelMd,
                      ),
                      const SizedBox(height: 4),

                      TextFormField(
                        controller: _confirmC,
                        obscureText: _hideConfirm,
                        textInputAction: TextInputAction.done,
                        style: AppText.bodyMd(),
                        validator: _validateConfirm,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: _dec(
                          'Ketik ulang password',
                          Icons.check_circle_outline,
                          suffix: _eyeButton(
                            _hideConfirm,
                            () => setState(
                              () => _hideConfirm = !_hideConfirm,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Persetujuan
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() {
                          _agree = !_agree;
                          if (_agree) _termsError = false;
                        }),
                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(
                                milliseconds: 150,
                              ),
                              margin: const EdgeInsets.only(top: 2),
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: _agree
                                    ? AppColors.primary
                                    : AppColors.surfaceContainerHigh,
                                borderRadius:
                                    BorderRadius.circular(6),
                                border: _termsError
                                    ? Border.all(
                                        color: _error,
                                        width: 1.5,
                                      )
                                    : null,
                              ),
                              child: _agree
                                  ? const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: AppColors.onPrimary,
                                    )
                                  : null,
                            ),

                            const SizedBox(width: 8),

                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  style: AppText.bodySm(
                                    AppColors.onSurfaceVariant,
                                  ),
                                  children: [
                                    const TextSpan(
                                      text: 'Saya menyetujui ',
                                    ),
                                    TextSpan(
                                      text: 'Ketentuan Layanan',
                                      style: AppText.labelSm(
                                        AppColors.primary,
                                      ),
                                    ),
                                    const TextSpan(text: ' & '),
                                    TextSpan(
                                      text:
                                          'Kebijakan Privasi Data Wajah',
                                      style: AppText.labelSm(
                                        AppColors.secondary,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: ' EmoSense.',
                                    ),
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
                            style: AppText.labelSm(_error),
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
                            boxShadow: AppShadows.md,
                          ),
                          child: Material(
                            color: _loading
                                ? AppColors.primary.withOpacity(0.6)
                                : AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              borderRadius:
                                  BorderRadius.circular(8),
                              onTap: _loading ? null : _submit,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    if (_loading)
                                      const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color:
                                              AppColors.onPrimary,
                                        ),
                                      )
                                    else ...[
                                      Text(
                                        'Daftar Akun Baru',
                                        style: AppText.labelLg(
                                          AppColors.onPrimary,
                                        ).copyWith(fontSize: 16),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.arrow_forward,
                                        size: 18,
                                        color: AppColors.onPrimary,
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

              // Link ke Login
              Center(
                child: Wrap(
                  crossAxisAlignment:
                      WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Sudah punya akun?',
                      style: AppText.bodyMd(
                        AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginPage(),
                        ),
                      ),
                      child: Text(
                        'Masuk di Sini',
                        style: AppText.labelLg(
                          AppColors.primary,
                        ),
                      ),
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