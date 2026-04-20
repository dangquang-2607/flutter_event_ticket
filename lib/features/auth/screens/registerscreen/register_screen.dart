import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController userCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();

  bool isLoading = false;
  bool hidePassword = true;

  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late List<Animation<Offset>> _slideAnims = [];
  bool _isUiReady = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _slideAnims = List.generate(6, (index) {
      double start = 0.1 * index;
      double end = (0.1 * index + 0.5).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeInOutCubic),
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
    emailCtrl.dispose();
    super.dispose();
  }

  Future<void> handleRegister() async {
    final username = userCtrl.text.trim();
    final password = passCtrl.text.trim();
    final email = emailCtrl.text.trim();

    if (username.isEmpty || password.isEmpty || email.isEmpty) {
      Get.snackbar(
        "Thông tin không hợp lệ",
        "Vui lòng điền đầy đủ thông tin",
        backgroundColor: Colors.orangeAccent.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
      );
      return;
    }

    setState(() => isLoading = true);

    final url = Uri.parse("http://10.0.2.2:5054/api/auth/register");
    final body = jsonEncode({
      "userName": username,
      "password": password,
      "email": email,
    });

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      // Luôn dừng loading sau khi có phản hồi
      setState(() => isLoading = false);

      // TRƯỜ-NG HỢP 1: ĐĂNG KÝ THÀNH CÔNG
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final msg =
            data["message"] ??
            "Ban đã đăng ký thành công! Đăng nhập ngay bây giờ.";

        // Đợi cho snackbar hiển thị xong và tự đóng
        Get.snackbar(
          "Thành công",
          msg,
          backgroundColor: Colors.green.withOpacity(0.9),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          borderRadius: 12,
          margin: const EdgeInsets.all(16),
          icon: const Icon(
            Icons.check_circle_outline_rounded,
            color: Colors.white,
          ),
        ).future.then((_) {
          // Chỉ gọi Get.back() sau khi snackbar đã đóng
          Get.back();
        });
      }
      // TRƯỜNG HỢP 2: TÊN NGƯỜI DÙNG ĐÃ TỒN TẠI (LỖI 409)
      else if (response.statusCode == 409) {
        Get.snackbar(
          "Đăng ký thất bại",
          // Body của response 409 là text thuần, không phải JSON
          response.body,
          backgroundColor: Colors.orangeAccent.withOpacity(0.9),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          borderRadius: 12,
          margin: const EdgeInsets.all(16),
          icon: const Icon(Icons.error_outline_rounded, color: Colors.white),
        );
      }
      // TRƯỜNG HỢP 3: CÁC LỖI KHÁC TỪ SERVER
      else {
        Get.snackbar(
          "Đăng ký thất bại",
          "Có lỗi xảy ra từ máy chủ, vui lòng thử lại.",
          backgroundColor: Colors.redAccent.withOpacity(0.9),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          borderRadius: 12,
          margin: const EdgeInsets.all(16),
          icon: const Icon(Icons.error_outline_rounded, color: Colors.white),
        );
      }
    } catch (e) {
      // TRƯỜNG HỢP 4: LỖI MẠNG, KHÔNG KẾT NỐI ĐƯỢC SERVER
      setState(() => isLoading = false);
      Get.snackbar(
        "Lỗi kết nối",
        "Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại mạng.",
        backgroundColor: Colors.redAccent.withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
        icon: const Icon(Icons.cloud_off_rounded, color: Colors.white),
      );
    }
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
              color: Colors.purpleAccent.withOpacity(0.5),
              size: 300,
            ),
          ),
          Positioned(
            bottom: -150,
            right: -100,
            child: _buildLightBlob(
              color: Colors.deepPurple.withOpacity(0.6),
              size: 400,
            ),
          ),
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
          if (_isUiReady)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 10,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white70,
                ),
                onPressed: () => Get.back(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFrostedGlassCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
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
                _buildAnimatedChild(
                  2,
                  _buildTextField(
                    emailCtrl,
                    "Email",
                    Icons.email_outlined,
                    isEmail: true,
                  ),
                ),
                const SizedBox(height: 16),
                _buildAnimatedChild(3, _buildPasswordField()),
                const SizedBox(height: 24),
                _buildAnimatedChild(4, _buildRegisterButton()),
                const SizedBox(height: 24),
                _buildAnimatedChild(5, _buildLoginLink()),
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
            color: Colors.white.withOpacity(0.2),
          ),
          child: const Icon(
            Icons.person_add_alt_1_outlined,
            color: Colors.white,
            size: 50,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "Create Account",
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Tạo tài khoản mới để bắt đầu",
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isEmail = false,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.7)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.8),
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
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        prefixIcon: Icon(
          Icons.lock_outline,
          color: Colors.white.withOpacity(0.7),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            hidePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: Colors.white.withOpacity(0.7),
          ),
          onPressed: () => setState(() => hidePassword = !hidePassword),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.8),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
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
          shadowColor: Colors.black.withOpacity(0.3),
        ),
        onPressed: isLoading ? null : handleRegister,
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
                "Register",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Đã có tài khoản? ",
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
        GestureDetector(
          onTap: () => Get.back(),
          child: const Text(
            "Đăng nhập",
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
