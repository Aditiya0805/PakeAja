import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pakeaja/core/constants/app_constants.dart';
import 'package:pakeaja/core/theme/app_theme.dart';
import 'package:pakeaja/core/utils/validators.dart';
import 'package:pakeaja/features/auth/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static const _crimson = Color(0xFFC4202F);
  static const _coralEnd = Color(0xFFEF5537);
  static const _fieldBorder = Color(0xFFD3C3C5);
  static const _outlineBtnBorder = Color(0xFFCF8A90);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authControllerProvider.notifier).login(
          email: _emailController.text,
          password: _passwordController.text,
          name: _nameController.text,
        );
    if (success && mounted) {
      context.go('/');
    }
  }

  Future<void> _googleSignIn() async {
    final nameVal = _nameController.text.trim();
    if (nameVal.isNotEmpty && nameVal.length < 2) {
      _formKey.currentState?.validate();
      return;
    }

    setState(() => _isGoogleLoading = true);
    final success = await ref
        .read(authControllerProvider.notifier)
        .signInWithGoogle(name: nameVal.isNotEmpty ? nameVal : null);
    if (mounted) {
      setState(() => _isGoogleLoading = false);
    }
    if (success && mounted) {
      context.go('/');
    }
  }

  InputDecoration _fieldDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    const radius = BorderRadius.all(Radius.circular(12));
    return InputDecoration(
      hintText: label,
      helperText: hint.isEmpty ? null : null,
      prefixIcon: Icon(icon, color: _crimson, size: 21),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      hintStyle: const TextStyle(
        color: Color(0xFF4A4E54),
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      border: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: _fieldBorder, width: 1.1),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: _fieldBorder, width: 1.1),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: _crimson, width: 1.6),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: AppTheme.errorColor, width: 1.2),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: AppTheme.errorColor, width: 1.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final errorMessage = authErrorMessage(authState);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Latar gradasi merah marun + pola garis lemari pakaian & kilau
          const _WardrobeAuthBackground(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 28,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: math.max(0, constraints.maxHeight - 56),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: _buildFloatingCard(
                          isLoading: isLoading,
                          errorMessage: errorMessage,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingCard({
    required bool isLoading,
    required String? errorMessage,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // Kartu putih utama
        Container(
          margin: const EdgeInsets.only(top: 44),
          padding: const EdgeInsets.fromLTRB(22, 56, 22, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'PakeAja',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: _crimson,
                    letterSpacing: -0.4,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  AppConstants.appTagline,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF2B2E33),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 24),

                if (errorMessage != null) ...[
                  _buildErrorBanner(errorMessage),
                  const SizedBox(height: 14),
                ],

                // Nama
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: Validators.optionalName,
                  decoration: _fieldDecoration(
                    label: 'Nama',
                    hint: 'Masukkan nama untuk ditampilkan di aplikasi',
                    icon: Icons.person_outline_rounded,
                  ),
                ),
                const SizedBox(height: 14),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.email,
                  decoration: _fieldDecoration(
                    label: 'Email',
                    hint: 'nama@email.com',
                    icon: Icons.mail_outline_rounded,
                  ),
                ),
                const SizedBox(height: 14),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => isLoading ? null : _login(),
                  validator: Validators.password,
                  decoration: _fieldDecoration(
                    label: 'Password',
                    hint: '',
                    icon: Icons.lock_outline_rounded,
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: const Color(0xFF555960),
                        size: 21,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    style: TextButton.styleFrom(
                      foregroundColor: _crimson,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Lupa password?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Tombol Masuk gradien pil (menggunakan FilledButton agar konsisten & teruji)
                _buildGradientMasukButton(isLoading: isLoading),
                const SizedBox(height: 16),

                // Pembatas "atau"
                const _OrnamentDivider(label: 'atau'),
                const SizedBox(height: 16),

                // Tombol Masuk dengan Google
                _buildGoogleButton(),
                const SizedBox(height: 20),

                // Footer Daftar
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Belum punya akun? ',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF2B2E33),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/register'),
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Text(
                          'Daftar',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: _crimson,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Lencana lingkaran hanger mengambang di atas kartu
        const Positioned(
          top: 0,
          child: _FloatingHangerBadge(),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.errorColor.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppTheme.errorColor, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientMasukButton({required bool isLoading}) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: isLoading
            ? const LinearGradient(
                colors: [Color(0xFFDF858C), Color(0xFFF1A391)],
              )
            : const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [_crimson, Color(0xFFDC3632), _coralEnd],
              ),
        boxShadow: isLoading
            ? null
            : [
                BoxShadow(
                  color: _crimson.withValues(alpha: 0.32),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: FilledButton(
        onPressed: isLoading ? null : _login,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Masuk',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: _isGoogleLoading ? null : _googleSignIn,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: _outlineBtnBorder, width: 1.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: _isGoogleLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _GoogleGMark(size: 19),
                  SizedBox(width: 10),
                  Text(
                    'Masuk dengan Google',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF23272B),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _FloatingHangerBadge extends StatelessWidget {
  const _FloatingHangerBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      height: 86,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE43542),
              Color(0xFFC11928),
              Color(0xFFA0111F),
            ],
          ),
        ),
        child: Center(
          child: CustomPaint(
            size: const Size(38, 28),
            painter: _HangerIconPainter(),
          ),
        ),
      ),
    );
  }
}

class _HangerIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Kait gantungan baju
    final hookPath = Path()
      ..moveTo(w * 0.44, h * 0.24)
      ..cubicTo(w * 0.44, h * 0.05, w * 0.62, h * 0.05, w * 0.60, h * 0.24)
      ..cubicTo(w * 0.59, h * 0.31, w * 0.50, h * 0.34, w * 0.50, h * 0.41);
    canvas.drawPath(hookPath, paint);

    // Bahu & alas gantungan
    final bodyPath = Path()
      ..moveTo(w * 0.50, h * 0.41)
      ..lineTo(w * 0.09, h * 0.78)
      ..quadraticBezierTo(w * 0.05, h * 0.85, w * 0.13, h * 0.85)
      ..lineTo(w * 0.87, h * 0.85)
      ..quadraticBezierTo(w * 0.95, h * 0.85, w * 0.91, h * 0.78)
      ..close();
    canvas.drawPath(bodyPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OrnamentDivider extends StatelessWidget {
  final String label;
  const _OrnamentDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(color: Color(0xFFE3D8DA), thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, size: 11, color: Color(0xFFC8A6AA)),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF45494F),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.auto_awesome, size: 11, color: Color(0xFFC8A6AA)),
            ],
          ),
        ),
        const Expanded(
          child: Divider(color: Color(0xFFE3D8DA), thickness: 1),
        ),
      ],
    );
  }
}

class _GoogleGMark extends StatelessWidget {
  final double size;
  const _GoogleGMark({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _GoogleGMarkPainter(),
    );
  }
}

class _GoogleGMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.19;
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: (size.width - stroke) / 2,
    );

    Paint arcPaint(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // Segmen warna resmi ikon Google G
    canvas.drawArc(rect, -0.58, 1.18, false, arcPaint(const Color(0xFF4285F4)));
    canvas.drawArc(rect, 0.56, 1.85, false, arcPaint(const Color(0xFF34A853)));
    canvas.drawArc(rect, 2.38, 1.35, false, arcPaint(const Color(0xFFFBBC05)));
    canvas.drawArc(rect, 3.70, 2.02, false, arcPaint(const Color(0xFFEA4335)));

    // Batang horizontal biru huruf G
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.50,
        size.height * 0.50 - stroke / 2,
        size.width * 0.45,
        stroke,
      ),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WardrobeAuthBackground extends StatelessWidget {
  const _WardrobeAuthBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE02B3D),
            Color(0xFFB71A29),
            Color(0xFF7D0D19),
            Color(0xFF560711),
          ],
          stops: [0.0, 0.38, 0.74, 1.0],
        ),
      ),
      child: CustomPaint(
        painter: _WardrobePatternPainter(),
      ),
    );
  }
}

class _WardrobePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.11)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final sparklePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    // Siluet hanger & pakaian di area tepi layar agar bingkai kartu tampak kaya
    _drawHanger(canvas, Offset(size.width * 0.32, size.height * 0.08), 58, -0.22, linePaint);
    _drawHanger(canvas, Offset(size.width * 0.86, size.height * 0.09), 52, 0.25, linePaint);
    _drawShirt(canvas, Offset(size.width * 0.05, size.height * 0.05), 88, 0.16, linePaint);
    _drawBlazer(canvas, Offset(size.width * 0.62, size.height * 0.02), 84, -0.10, linePaint);
    _drawDress(canvas, Offset(size.width * 0.94, size.height * 0.26), 80, -0.05, linePaint);
    _drawShirt(canvas, Offset(size.width * 0.02, size.height * 0.42), 76, -0.14, linePaint);
    _drawHanger(canvas, Offset(size.width * 0.07, size.height * 0.68), 64, 0.22, linePaint);
    _drawSkirt(canvas, Offset(size.width * 0.95, size.height * 0.63), 66, -0.18, linePaint);
    _drawShirt(canvas, Offset(size.width * 0.90, size.height * 0.88), 86, -0.15, linePaint);
    _drawHanger(canvas, Offset(size.width * 0.62, size.height * 0.95), 70, 0.06, linePaint);
    _drawBlazer(canvas, Offset(size.width * 0.12, size.height * 0.95), 84, 0.12, linePaint);

    // Kilau bintang empat sudut
    _drawSparkle(canvas, Offset(size.width * 0.94, size.height * 0.15), 11, sparklePaint);
    _drawSparkle(canvas, Offset(size.width * 0.91, size.height * 0.19), 5, sparklePaint);
    _drawSparkle(canvas, Offset(size.width * 0.05, size.height * 0.33), 6, sparklePaint);
    _drawSparkle(canvas, Offset(size.width * 0.06, size.height * 0.86), 11, sparklePaint);
    _drawSparkle(canvas, Offset(size.width * 0.86, size.height * 0.94), 6, sparklePaint);
  }

  void _drawHanger(
    Canvas canvas,
    Offset center,
    double width,
    double angle,
    Paint paint,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final h = width * 0.55;
    final path = Path()
      ..moveTo(-width * 0.04, -h * 0.55)
      ..cubicTo(-width * 0.04, -h * 0.85, width * 0.12, -h * 0.85, width * 0.10, -h * 0.55)
      ..quadraticBezierTo(width * 0.08, -h * 0.42, 0, -h * 0.35)
      ..lineTo(-width * 0.48, h * 0.25)
      ..lineTo(width * 0.48, h * 0.25)
      ..close();
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  void _drawShirt(
    Canvas canvas,
    Offset center,
    double size,
    double angle,
    Paint paint,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final w = size;
    final h = size * 0.95;
    final path = Path()
      ..moveTo(-w * 0.18, -h * 0.42)
      ..quadraticBezierTo(0, -h * 0.28, w * 0.18, -h * 0.42)
      ..lineTo(w * 0.48, -h * 0.22)
      ..lineTo(w * 0.36, 0)
      ..lineTo(w * 0.26, -h * 0.06)
      ..lineTo(w * 0.26, h * 0.44)
      ..lineTo(-w * 0.26, h * 0.44)
      ..lineTo(-w * 0.26, -h * 0.06)
      ..lineTo(-w * 0.36, 0)
      ..lineTo(-w * 0.48, -h * 0.22)
      ..close();
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  void _drawBlazer(
    Canvas canvas,
    Offset center,
    double size,
    double angle,
    Paint paint,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final w = size;
    final h = size * 1.1;
    final path = Path()
      ..moveTo(-w * 0.16, -h * 0.42)
      ..lineTo(-w * 0.44, -h * 0.28)
      ..lineTo(-w * 0.48, h * 0.30)
      ..lineTo(-w * 0.32, h * 0.30)
      ..lineTo(-w * 0.28, -h * 0.05)
      ..lineTo(-w * 0.28, h * 0.45)
      ..lineTo(w * 0.28, h * 0.45)
      ..lineTo(w * 0.28, -h * 0.05)
      ..lineTo(w * 0.32, h * 0.30)
      ..lineTo(w * 0.48, h * 0.30)
      ..lineTo(w * 0.44, -h * 0.28)
      ..lineTo(w * 0.16, -h * 0.42)
      ..lineTo(0, -h * 0.02)
      ..close();
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  void _drawDress(
    Canvas canvas,
    Offset center,
    double size,
    double angle,
    Paint paint,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final w = size * 0.85;
    final h = size * 1.2;
    final path = Path()
      ..moveTo(-w * 0.20, -h * 0.44)
      ..quadraticBezierTo(0, -h * 0.30, w * 0.20, -h * 0.44)
      ..lineTo(w * 0.26, -h * 0.14)
      ..lineTo(w * 0.46, h * 0.44)
      ..lineTo(-w * 0.46, h * 0.44)
      ..lineTo(-w * 0.26, -h * 0.14)
      ..close();
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  void _drawSkirt(
    Canvas canvas,
    Offset center,
    double size,
    double angle,
    Paint paint,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final w = size;
    final h = size * 0.9;
    final path = Path()
      ..moveTo(-w * 0.28, -h * 0.42)
      ..lineTo(w * 0.28, -h * 0.42)
      ..lineTo(w * 0.46, h * 0.42)
      ..lineTo(-w * 0.46, h * 0.42)
      ..close();
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  void _drawSparkle(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..quadraticBezierTo(center.dx, center.dy, center.dx + radius, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + radius)
      ..quadraticBezierTo(center.dx, center.dy, center.dx - radius, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - radius)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
