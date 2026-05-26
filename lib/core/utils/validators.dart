/// Utility class tập trung các logic validation dùng chung
class Validators {
  /// Kiểm tra email hợp lệ
  static bool isValidEmail(String email) {
    return RegExp(
      r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
    ).hasMatch(email);
  }

  /// Validator cho TextFormField: email
  static String? emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập email';
    }
    if (!isValidEmail(value)) {
      return 'Địa chỉ email không hợp lệ';
    }
    return null;
  }

  /// Validator cho TextFormField: trường bắt buộc
  static String? requiredValidator(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null
          ? 'Vui lòng nhập $fieldName'
          : 'Không được bỏ trống';
    }
    return null;
  }

  /// Validator cho TextFormField: mật khẩu (tối thiểu 6 ký tự)
  static String? passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    if (value.length < 6) {
      return 'Mật khẩu phải ít nhất 6 ký tự';
    }
    return null;
  }

  /// Validator cho TextFormField: xác nhận mật khẩu
  static String? confirmPasswordValidator(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng xác nhận mật khẩu mới';
    }
    if (value != password) {
      return 'Mật khẩu xác nhận không khớp';
    }
    return null;
  }

  /// Validator cho TextFormField: số nguyên dương
  static String? positiveIntValidator(String? value) {
    if (value == null || value.isEmpty) return 'Không được bỏ trống';
    if (int.tryParse(value) == null) return 'Vui lòng nhập số nguyên dương';
    if (int.parse(value) <= 0) return 'Giá trị phải lớn hơn 0';
    return null;
  }

  /// Validator cho TextFormField: số không âm (giá tiền)
  static String? nonNegativeDoubleValidator(String? value) {
    if (value == null || value.isEmpty) return 'Không được bỏ trống';
    if (double.tryParse(value) == null) return 'Vui lòng nhập giá hợp lệ';
    if (double.parse(value) < 0) return 'Giá trị không được âm';
    return null;
  }
}
