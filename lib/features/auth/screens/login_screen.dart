import 'dart:ui';
import 'package:event_ticket_app/features/auth/screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/api/api_client.dart';
import '../../../data/services/auth_service.dart';
import 'package:get_storage/get_storage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController userCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  bool isLoading = false;
  bool hidePassword = true;

  late AnimationController _controller;
  List<Animation<Offset>> _slideAnims = [];
  late Animation<double> _fadeAnim;
  bool _isUiReady = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _slideAnims = List.generate(5, (index) {
      return Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            0.1 * index,
            (0.7 + 0.1 * index).clamp(0.0, 1.0),
            curve: Curves.easeInOutCubic,
          ),
        ),
      );
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isUiReady = true;
        });
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    userCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  Future<void> handleLogin() async {
    FocusScope.of(context).unfocus();
    setState(() => isLoading = true);
    try {
      final response = await AuthService.login(
        userCtrl.text.trim(),
        passCtrl.text.trim(),
      );
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      setState(() => isLoading = false);

      if (response != null) {
        final box = GetStorage();
        await box.write("accessToken", response.accessToken);
        await box.write("role", response.role);
        await box.write("userName", response.userName);

        if (response.expiresIn > 0) {
          final expiry = DateTime.now().add(
            Duration(seconds: response.expiresIn),
          );
          await box.write("tokenExpiry", expiry.toIso8601String());
        }

        Get.offAllNamed(AppRoutes.home, arguments: response);
      } else {
        _showLoginError("Sai tài khoản hoặc mật khẩu.");
      }
    } on ApiException catch (e) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      setState(() => isLoading = false);
      _showLoginError(e.message);
    }
  }

  void _showLoginError(String message) {
    Get.snackbar(
      "Đăng nhập thất bại",
      message,
      backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      icon: const Icon(Icons.error_outline_rounded, color: Colors.white),
    );
  }

  void goToRegister() {
    Get.to(
      () => const RegisterScreen(),
      transition: Transition.rightToLeftWithFade,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF673AB7), Color(0xFF311B92)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            top: -100,
            left: -100,
            child: _buildLightBlob(
              color: Colors.purpleAccent.withValues(alpha: 0.5),
              size: 300,
            ),
          ),
          Positioned(
            bottom: -150,
            right: -100,
            child: _buildLightBlob(
              color: Colors.deepPurple.withValues(alpha: 0.6),
              size: 400,
            ),
          ),

          // Sử dụng AnimatedOpacity để form xuất hiện mượt mà
          AnimatedOpacity(
            opacity: _isUiReady ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 500),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: _buildFrostedGlassCard(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrostedGlassCard() {
    // Chỉ build nội dung khi animation đã sẵn sàng để tránh lỗi
    if (_slideAnims.isEmpty) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(20.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildAnimatedChild(0, _buildHeader()),
                const SizedBox(height: 32),
                _buildAnimatedChild(
                  1,
                  _buildTextField(userCtrl, "Tài khoản", Icons.person_outline),
                ),
                const SizedBox(height: 16),
                _buildAnimatedChild(2, _buildPasswordField()),
                const SizedBox(height: 24),
                _buildAnimatedChild(3, _buildLoginButton()),
                const SizedBox(height: 24),
                _buildAnimatedChild(4, _buildRegisterLink()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedChild(int index, Widget child) {
    return SlideTransition(position: _slideAnims[index], child: child);
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          child: const Icon(
            Icons.event_seat_outlined,
            color: Colors.white,
            size: 50,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "Welcome Back",
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Đăng nhập để tiếp tục",
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.7)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.8),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: passCtrl,
      obscureText: hidePassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: "Mật khẩu",
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        prefixIcon: Icon(
          Icons.lock_outline,
          color: Colors.white.withValues(alpha: 0.7),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            hidePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: Colors.white.withValues(alpha: 0.7),
          ),
          onPressed: () => setState(() => hidePassword = !hidePassword),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.8),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF311B92),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 8,
          shadowColor: Colors.black.withValues(alpha: 0.3),
        ),
        onPressed: isLoading ? null : handleLogin,
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Color(0xFF311B92),
                ),
              )
            : const Text(
                "Login",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Chưa có tài khoản? ",
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
        ),
        GestureDetector(
          onTap: goToRegister,
          child: const Text(
            "Đăng ký",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              decoration: TextDecoration.underline,
              decorationColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLightBlob({required Color color, required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
