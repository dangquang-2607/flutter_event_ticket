import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../model/event.dart';
import '../services/event_service.dart';

class EventCreateScreen extends StatefulWidget {
  const EventCreateScreen({super.key});

  @override
  State<EventCreateScreen> createState() => _EventCreateScreenState();
}

class _EventCreateScreenState extends State<EventCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController titleCtrl = TextEditingController();
  final TextEditingController descCtrl = TextEditingController();
  final TextEditingController locationCtrl = TextEditingController();
  final TextEditingController maxTicketsCtrl = TextEditingController();
  final TextEditingController priceCtrl = TextEditingController();
  DateTime? startTime;
  DateTime? endTime;

  bool isLoading = false;
  bool isRegistrationOpen = false;
  String eventStatus = "Sắp diễn ra";
  int registeredTickets = 0;

  final List<String> statuses = ["Sắp diễn ra", "Đang diễn ra", "Đã kết thúc"];

  Future<void> handleCreate() async {
    if (!_formKey.currentState!.validate() ||
        startTime == null ||
        endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập đầy đủ thông tin")),
      );
      return;
    }

    // Validate ngày bắt đầu < ngày kết thúc
    if (startTime!.isAfter(endTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Ngày bắt đầu phải trước ngày kết thúc"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (startTime!.isAtSameMomentAs(endTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Ngày bắt đầu và kết thúc không được giống nhau"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    final newEvent = Event(
      title: titleCtrl.text,
      description: descCtrl.text,
      location: locationCtrl.text,
      startTime: startTime!,
      endTime: endTime!,
      maxTickets: int.parse(maxTicketsCtrl.text),
      price: double.parse(priceCtrl.text),
      isRegistrationOpen: isRegistrationOpen,
      status: eventStatus,
      registeredTickets: registeredTickets,
    );

    final created = await EventService.createEvent(newEvent);

    setState(() => isLoading = false);

    if (created != null) {
      Navigator.pop(context, true); // ✅ quay lại list screen và refresh
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Tạo sự kiện thành công")));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Tạo sự kiện thất bại")));
    }
  }

  Future<void> pickDateTime(bool isStart) async {
    final today = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (startTime ?? today)
          : (endTime ?? today.add(const Duration(hours: 1))),
      firstDate: today,
      lastDate: DateTime(2100),
    );
    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: isStart
          ? (startTime != null
                ? TimeOfDay.fromDateTime(startTime!)
                : TimeOfDay.now())
          : (endTime != null
                ? TimeOfDay.fromDateTime(endTime!)
                : TimeOfDay.now()),
    );
    if (pickedTime == null) return;

    final dateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      if (isStart) {
        startTime = dateTime;
        // Nếu endTime cũ nhỏ hơn startTime mới, auto set endTime
        if (endTime != null && endTime!.isBefore(startTime!)) {
          endTime = startTime!.add(const Duration(hours: 1));
        }
      } else {
        endTime = dateTime;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat("dd/MM/yyyy HH:mm");

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tạo sự kiện mới"),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Tiêu đề sự kiện
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: "Tiêu đề sự kiện",
                    border: InputBorder.none,
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0xFFDDDDDD),
                        width: 1,
                      ),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue, width: 1),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? "Không được bỏ trống" : null,
                ),
              ),

              // Mô tả
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  controller: descCtrl,
                  decoration: InputDecoration(
                    labelText: "Mô tả",
                    border: InputBorder.none,
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0xFFDDDDDD),
                        width: 1,
                      ),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue, width: 1),
                    ),
                  ),
                  maxLines: 3,
                ),
              ),

              // Địa điểm
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  controller: locationCtrl,
                  decoration: InputDecoration(
                    labelText: "Địa điểm",
                    border: InputBorder.none,
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0xFFDDDDDD),
                        width: 1,
                      ),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue, width: 1),
                    ),
                  ),
                ),
              ),

              // Số lượng vé tối đa
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  controller: maxTicketsCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: "Số lượng vé tối đa",
                    border: InputBorder.none,
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0xFFDDDDDD),
                        width: 1,
                      ),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue, width: 1),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return "Không được bỏ trống";
                    }
                    if (int.tryParse(v) == null) {
                      return "Vui lòng nhập số nguyên dương";
                    }
                    if (int.parse(v) <= 0) {
                      return "Số vé phải lớn hơn 0";
                    }
                    return null;
                  },
                ),
              ),

              // Giá vé
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  controller: priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+(\.\d{0,2})?$'),
                    ),
                  ],
                  decoration: InputDecoration(
                    labelText: "Giá vé (đ)",
                    border: InputBorder.none,
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0xFFDDDDDD),
                        width: 1,
                      ),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue, width: 1),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return "Không được bỏ trống";
                    }
                    if (double.tryParse(v) == null) {
                      return "Vui lòng nhập giá hợp lệ";
                    }
                    if (double.parse(v) < 0) {
                      return "Giá vé không được âm";
                    }
                    return null;
                  },
                ),
              ),

              // Mở đăng ký
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Mở đăng ký",
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                "Cho phép người dùng đăng ký về",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          Checkbox(
                            value: isRegistrationOpen,
                            onChanged: (val) {
                              setState(() => isRegistrationOpen = val ?? false);
                            },
                            activeColor: Colors.blue,
                          ),
                        ],
                      ),
                      const Divider(height: 1, color: Color(0xFFDDDDDD)),
                    ],
                  ),
                ),
              ),

              // Trạng thái
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Trạng thái",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    DropdownButtonFormField<String>(
                      value: eventStatus,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFFDDDDDD),
                            width: 1,
                          ),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue, width: 1),
                        ),
                      ),
                      items: statuses
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => eventStatus = val);
                        }
                      },
                    ),
                    const Divider(height: 1, color: Color(0xFFDDDDDD)),
                  ],
                ),
              ),

              // Số vé đã đăng ký
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Số vé đã đăng ký"),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          registeredTickets.toString(),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Ngày bắt đầu
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: GestureDetector(
                  onTap: () => pickDateTime(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFDDDDDD), width: 1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ngày bắt đầu',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                startTime == null
                                    ? "Chọn ngày bắt đầu"
                                    : formatter.format(startTime!),
                                style: TextStyle(
                                  color: startTime == null
                                      ? Colors.grey
                                      : Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.calendar_today,
                          size: 20,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Duration / Status
              if (startTime != null && endTime != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info, color: Colors.blue, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Khoảng thời gian: ${endTime!.difference(startTime!).inHours}h ${endTime!.difference(startTime!).inMinutes % 60}m',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Ngày kết thúc
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: GestureDetector(
                  onTap: () => pickDateTime(false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFDDDDDD), width: 1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ngày kết thúc',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                endTime == null
                                    ? "Chọn ngày kết thúc"
                                    : formatter.format(endTime!),
                                style: TextStyle(
                                  color: endTime == null
                                      ? Colors.grey
                                      : Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.calendar_today,
                          size: 20,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Nút tạo sự kiện
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ElevatedButton(
                  onPressed: isLoading ? null : handleCreate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Tạo sự kiện",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
}
