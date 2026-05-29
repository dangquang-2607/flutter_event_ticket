import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../../core/constants/api_constants.dart';
import '../../home/screens/home_screen.dart';

class PaymentScreen extends StatefulWidget {
  final int eventId;
  final String eventTitle;
  final double price;

  const PaymentScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
    required this.price,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  // Stepper State
  int _currentStep = 0; // 0: Personal Info, 1: Payment Method, 2: VietQR Code
  
  // Timer State
  Timer? _timer;
  int _secondsRemaining = 1200; // 20 minutes countdown

  // Form Fields State
  final _formKey = GlobalKey<FormState>();
  final _hoController = TextEditingController();
  final _tenController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _cccdController = TextEditingController();
  final _nationalityController = TextEditingController(text: "Việt Nam");
  final _countryController = TextEditingController(text: "Việt Nam");
  final _cityController = TextEditingController();
  String _gender = "Nam";
  DateTime? _birthDate;

  // Step 2 Selection State
  String _paymentMethod = "vietqr"; // default is VietQR
  bool _agreeToTerms = false;
  bool _isProcessing = false;

  // Royal Amethyst Light & Slate Color System
  static const Color bgColor = Color(0xFFF8FAFC);
  static const Color cardColor = Colors.white;
  static const Color primaryAmethyst = Color(0xFF7C3AED);
  static const Color primaryDark = Color(0xFF6D28D9);
  static const Color accentTeal = Color(0xFF0D9488);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color borderColor = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    
    // Autofill user details from storage if available
    final box = GetStorage();
    final userName = box.read("userName") ?? "";
    _hoController.text = "";
    _tenController.text = userName;
    _emailController.text = "";
  }

  @override
  void dispose() {
    _timer?.cancel();
    _hoController.dispose();
    _tenController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _cccdController.dispose();
    _nationalityController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
        _showTimeoutDialog();
      }
    });
  }

  void _showTimeoutDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Hết thời gian giao dịch", style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
        content: const Text("Thời gian đăng ký và thanh toán của bạn đã hết hạn. Vui lòng thực hiện lại giao dịch.", style: TextStyle(color: textSecondary)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryAmethyst,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Get.close(2); // Close dialog and go back to event detail
            },
            child: const Text("OK"),
          )
        ],
      ),
      barrierDismissible: false,
    );
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  String? _getToken() {
    final box = GetStorage();
    return box.read("accessToken");
  }

  Future<void> confirmPayment() async {
    setState(() => _isProcessing = true);
    try {
      final token = _getToken();
      final url = Uri.parse("${AppConstants.registrationsEndpoint}/register-event");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"eventId": widget.eventId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _timer?.cancel();
        Get.off(() => PaymentSuccessScreen(eventTitle: widget.eventTitle));
      } else {
        final data = jsonDecode(response.body);
        Get.snackbar("Lỗi thanh toán", data["message"] ?? "Đăng ký thất bại: ${response.statusCode}",
            backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Lỗi mạng", "Không thể kết nối đến máy chủ: $e",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedPrice = widget.price > 0 
        ? "${NumberFormat('#,##0', 'vi_VN').format(widget.price)} đ"
        : "Miễn phí";

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: textPrimary),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() {
                _currentStep--;
                if (_currentStep < 2) {
                  _timer?.cancel();
                }
              });
            } else {
              Get.back();
            }
          },
        ),
        title: Text(
          _currentStep == 0
              ? "Thông tin người đăng ký"
              : _currentStep == 1
                  ? "Phương thức thanh toán"
                  : "Thanh toán VietQR",
          style: const TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Step progress indicator
          _buildStepper(),
          
          // Countdown timer display
          if (_currentStep == 2) _buildCountdownRow(),
          
          // Step content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildCurrentStepContent(),
            ),
          ),
          
          // Bottom Price and Action Footer
          _buildPriceFooter(formattedPrice),
        ],
      ),
    );
  }

  // Progress Stepper Component
  Widget _buildStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepItem(1, "Chọn vé", true, false),
          _buildStepLine(true),
          _buildStepItem(2, "Thông tin", _currentStep >= 0, _currentStep == 0),
          _buildStepLine(_currentStep >= 1),
          _buildStepItem(3, "Thanh toán", _currentStep >= 1, _currentStep >= 1),
        ],
      ),
    );
  }

  Widget _buildStepItem(int step, String title, bool isReached, bool isActive) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isActive 
                ? primaryAmethyst 
                : (isReached ? primaryAmethyst.withValues(alpha: 0.15) : Colors.white),
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive || isReached ? primaryAmethyst : const Color(0xFFCBD5E1), 
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: TextStyle(
                color: isActive ? Colors.white : (isReached ? primaryAmethyst : const Color(0xFF94A3B8)),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            color: isActive ? textPrimary : textSecondary,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool isActive) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        height: 1.5,
        color: isActive ? primaryAmethyst : const Color(0xFFE2E8F0),
      ),
    );
  }

  // Countdown timer component
  Widget _buildCountdownRow() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.timer_outlined, color: Color(0xFFEF4444), size: 20),
              SizedBox(width: 8),
              Text(
                "Thời gian còn lại",
                style: TextStyle(color: Color(0xFF991B1B), fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          Text(
            _formatDuration(_secondsRemaining),
            style: const TextStyle(
              color: Color(0xFFEF4444),
              fontWeight: FontWeight.bold,
              fontSize: 16,
              fontFamily: "monospace",
            ),
          ),
        ],
      ),
    );
  }

  // Render content according to current step state
  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1InfoForm();
      case 1:
        return _buildStep2PaymentSelector();
      case 2:
        return _buildStep3VietQrCode();
      default:
        return _buildStep1InfoForm();
    }
  }

  // STEP 1: Personal Info Form Layout
  Widget _buildStep1InfoForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Title Header summary card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.eventTitle,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "Standard Ticket",
                    style: TextStyle(fontSize: 11, color: primaryDark, fontWeight: FontWeight.w600),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Form Title
          const Text(
            "Thông tin người tham dự",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: 12),
          
          // Input Card Wrapper
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                // Họ & Tên
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _hoController,
                        style: const TextStyle(color: textPrimary),
                        decoration: _buildInputDeco("Họ *"),
                        validator: (val) => val == null || val.trim().isEmpty ? "Nhập họ" : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _tenController,
                        style: const TextStyle(color: textPrimary),
                        decoration: _buildInputDeco("Tên *"),
                        validator: (val) => val == null || val.trim().isEmpty ? "Nhập tên" : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Số điện thoại
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: textPrimary),
                  decoration: _buildInputDeco("Số điện thoại *").copyWith(
                    prefixText: "(+84) ",
                    prefixStyle: const TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return "Nhập số điện thoại";
                    if (val.trim().length < 9) return "Số điện thoại không hợp lệ";
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: textPrimary),
                  decoration: _buildInputDeco("Email *"),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return "Nhập email";
                    if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]+").hasMatch(val)) {
                      return "Email không hợp lệ";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // CCCD / CMND
                TextFormField(
                  controller: _cccdController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: textPrimary),
                  decoration: _buildInputDeco("Số CMND/CCCD *"),
                  validator: (val) => val == null || val.trim().isEmpty ? "Nhập số CMND/CCCD" : null,
                ),
                const SizedBox(height: 16),
                
                // Quốc tịch & Quốc gia
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _nationalityController,
                        style: const TextStyle(color: textPrimary),
                        decoration: _buildInputDeco("Quốc tịch *"),
                        validator: (val) => val == null || val.trim().isEmpty ? "Nhập quốc tịch" : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _countryController,
                        style: const TextStyle(color: textPrimary),
                        decoration: _buildInputDeco("Quốc gia *"),
                        validator: (val) => val == null || val.trim().isEmpty ? "Nhập quốc gia" : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Tỉnh/Thành phố sinh sống
                TextFormField(
                  controller: _cityController,
                  style: const TextStyle(color: textPrimary),
                  decoration: _buildInputDeco("Tỉnh/thành đang sinh sống *"),
                  validator: (val) => val == null || val.trim().isEmpty ? "Nhập tỉnh/thành" : null,
                ),
                const SizedBox(height: 16),
                
                // Giới tính
                DropdownButtonFormField<String>(
                  initialValue: _gender,
                  style: const TextStyle(color: textPrimary),
                  dropdownColor: Colors.white,
                  decoration: _buildInputDeco("Giới tính *"),
                  items: const [
                    DropdownMenuItem(value: "Nam", child: Text("Nam")),
                    DropdownMenuItem(value: "Nữ", child: Text("Nữ")),
                    DropdownMenuItem(value: "Khác", child: Text("Khác")),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _gender = val);
                  },
                ),
                const SizedBox(height: 16),
                
                // Ngày sinh Date Picker
                TextFormField(
                  readOnly: true,
                  style: const TextStyle(color: textPrimary),
                  controller: TextEditingController(
                    text: _birthDate == null ? "" : DateFormat("dd/MM/yyyy").format(_birthDate!)
                  ),
                  decoration: _buildInputDeco("Ngày sinh *").copyWith(
                    suffixIcon: const Icon(Icons.calendar_today, color: primaryAmethyst, size: 20),
                  ),
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _birthDate ?? DateTime(2000, 1, 1),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: primaryAmethyst,
                              onPrimary: Colors.white,
                              onSurface: textPrimary,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (pickedDate != null) {
                      setState(() {
                        _birthDate = pickedDate;
                      });
                    }
                  },
                  validator: (value) => _birthDate == null ? "Chọn ngày sinh" : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // STEP 2: Select Payment Method Layout
  Widget _buildStep2PaymentSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Thông tin người đăng ký",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: primaryAmethyst,
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: () {
                      setState(() => _currentStep = 0);
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text("Chỉnh sửa", style: TextStyle(fontWeight: FontWeight.bold)),
                  )
                ],
              ),
              const Divider(height: 16, color: borderColor),
              _buildSummaryRow("Họ tên:", "${_hoController.text} ${_tenController.text}"),
              const SizedBox(height: 8),
              _buildSummaryRow("Số điện thoại:", "(+84) ${_phoneController.text}"),
              const SizedBox(height: 8),
              _buildSummaryRow("Email:", _emailController.text),
              const SizedBox(height: 8),
              _buildSummaryRow("CMND/CCCD:", _cccdController.text),
            ],
          ),
        ),
        const SizedBox(height: 24),

        const Text(
          "Phương thức thanh toán",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
        ),
        const SizedBox(height: 12),

        // Method options list
        Column(
          children: [
            _buildPaymentMethodTile(
              id: "vietqr",
              title: "VIETQR - QR chuyển khoản",
              subtitle: "Thanh toán nhanh bằng mã QR ngân hàng",
              icon: Icons.qr_code_scanner,
              iconBgColor: const Color(0xFFEEF2FF),
              iconColor: primaryAmethyst,
            ),
            const SizedBox(height: 12),
            _buildPaymentMethodTile(
              id: "credit",
              title: "Thẻ Tín Dụng / Ghi Nợ Quốc Tế",
              subtitle: "Visa, Mastercard, JCB...",
              icon: Icons.credit_card,
              iconBgColor: const Color(0xFFF0FDF4),
              iconColor: accentTeal,
            ),
            const SizedBox(height: 12),
            _buildPaymentMethodTile(
              id: "atm",
              title: "Thẻ ATM Nội Địa",
              subtitle: "Thanh toán qua cổng ATM internet banking",
              icon: Icons.account_balance,
              iconBgColor: const Color(0xFFFFF7ED),
              iconColor: Colors.orange,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Disclaimer check box
        Container(
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _agreeToTerms,
                  activeColor: primaryAmethyst,
                  onChanged: (val) {
                    if (val != null) setState(() => _agreeToTerms = val);
                  },
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Bằng việc nhấp vào nút thanh toán, tôi xác nhận đã đọc kỹ và đồng ý với Điều khoản sử dụng cùng Quy định & thỏa thuận của ban tổ chức.",
                  style: TextStyle(fontSize: 12, color: textSecondary, height: 1.5),
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // STEP 3: VietQR Code display Layout
  Widget _buildStep3VietQrCode() {
    final regId = 1000 + widget.eventId + DateTime.now().millisecond;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // OnePay details
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              const Text(
                "Đơn vị chấp nhận thanh toán",
                style: TextStyle(color: textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 4),
              const Text(
                "NEXUS VIETNAM",
                style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Divider(color: borderColor.withValues(alpha: 0.8)),
              const SizedBox(height: 12),
              
              // QR Code network image container
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: primaryAmethyst.withValues(alpha: 0.08),
                        blurRadius: 12,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      "https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=VietQR_Techcombank_19035678901234_Amount_${widget.price}_Order_$regId",
                      height: 180,
                      width: 180,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const SizedBox(
                          height: 180,
                          width: 180,
                          child: Center(child: CircularProgressIndicator(color: primaryAmethyst)),
                        );
                      },
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Download Button
              ElevatedButton.icon(
                onPressed: () {
                  Get.snackbar(
                    "Thành công",
                    "Đã lưu ảnh mã QR thanh toán vào album của bạn.",
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                    snackPosition: SnackPosition.BOTTOM,
                    margin: const EdgeInsets.all(16),
                  );
                },
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text("Tải mã thanh toán", style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryAmethyst.withValues(alpha: 0.1),
                  foregroundColor: primaryAmethyst,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Banking details card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Thông tin chuyển khoản",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary),
              ),
              const Divider(height: 20, color: borderColor),
              _buildBankDetailRow("Ngân hàng:", "Techcombank (TCB)"),
              _buildBankDetailRow("Số tài khoản:", "1903 5678 9012 34"),
              _buildBankDetailRow("Chủ tài khoản:", "CONG TY TNHH EVENTICK"),
              _buildBankDetailRow("Nội dung chuyển:", "EVENTICK_REG_$regId"),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Notes Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7), // Amber 100
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFCD34D)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: Color(0xFFD97706), size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Lưu ý: Không tắt trình duyệt cho đến khi nhận được kết quả cuối cùng. Vui lòng ghi chính xác nội dung chuyển khoản để hệ thống đối soát tự động.",
                  style: TextStyle(fontSize: 12, color: Color(0xFF92400E), height: 1.4),
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // Form input decoration utility
  InputDecoration _buildInputDeco(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: textSecondary, fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: primaryAmethyst, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: const TextStyle(color: textSecondary, fontSize: 13)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        )
      ],
    );
  }

  Widget _buildPaymentMethodTile({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    final isSelected = _paymentMethod == id;
    
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? primaryAmethyst : borderColor,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: ListTile(
        onTap: () {
          setState(() {
            _paymentMethod = id;
          });
        },
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 14),
        ),
        subtitle: Text(subtitle, style: const TextStyle(color: textSecondary, fontSize: 12)),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: primaryAmethyst)
            : const Icon(Icons.circle_outlined, color: textSecondary),
      ),
    );
  }

  Widget _buildBankDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 13)),
        ],
      ),
    );
  }

  // Sticky bottom footer displaying price and step navigation buttons
  Widget _buildPriceFooter(String formattedPrice) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: borderColor, width: 1)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Tổng tiền", style: TextStyle(color: textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  formattedPrice,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryAmethyst),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _handleFooterAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryAmethyst,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE2E8F0),
                    disabledForegroundColor: const Color(0xFF94A3B8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    elevation: 0,
                  ),
                  child: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _currentStep == 0
                              ? "Tiếp theo"
                              : _currentStep == 1
                                  ? "Thanh toán"
                                  : "Xác nhận chuyển khoản",
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Footer button click handler depending on active step
  void _handleFooterAction() {
    if (_currentStep == 0) {
      if (_formKey.currentState!.validate()) {
        setState(() {
          _currentStep = 1;
        });
      }
    } else if (_currentStep == 1) {
      if (!_agreeToTerms) {
        Get.snackbar("Chưa xác nhận", "Vui lòng xác nhận đồng ý với điều khoản sử dụng để tiếp tục.",
            backgroundColor: Colors.orangeAccent, colorText: Colors.white);
        return;
      }
      
      if (_paymentMethod != "vietqr") {
        Get.snackbar("Không hỗ trợ", "Phương thức thanh toán này hiện chưa được mở rộng. Vui lòng chọn quét mã VietQR.",
            backgroundColor: Colors.orangeAccent, colorText: Colors.white);
        return;
      }
      
      setState(() {
        _currentStep = 2;
        _secondsRemaining = 1200;
        _startTimer();
      });
    } else if (_currentStep == 2) {
      confirmPayment();
    }
  }
}

class PaymentSuccessScreen extends StatelessWidget {
  final String eventTitle;

  const PaymentSuccessScreen({super.key, required this.eventTitle});

  @override
  Widget build(BuildContext context) {
    const primaryAmethyst = Color(0xFF7C3AED);
    const textPrimary = Color(0xFF0F172A);
    const textSecondary = Color(0xFF475569);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFFD1FAE5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF059669),
                  size: 100,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                "Đăng ký thành công!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary),
              ),
              const SizedBox(height: 12),
              Text(
                "Bạn đã đăng ký tham gia sự kiện\n\"$eventTitle\" thành công.",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: textSecondary, height: 1.5),
              ),
              const SizedBox(height: 8),
              const Text(
                "Vé điện tử (mã QR) đã được tạo. Bạn có thể kiểm tra ở trang \"Vé của tôi\".",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), height: 1.4),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Get.offAll(() => const HomeScreen()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryAmethyst,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Quay về trang chủ",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
