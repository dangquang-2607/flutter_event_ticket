import 'package:flutter/material.dart';
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
  DateTime? startTime;
  DateTime? endTime;

  bool isLoading = false;

  Future<void> handleCreate() async {
    if (!_formKey.currentState!.validate() || startTime == null || endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập đầy đủ thông tin")),
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
    );

    final created = await EventService.createEvent(newEvent);

    setState(() => isLoading = false);

    if (created != null) {
      Navigator.pop(context, true); // ✅ quay lại list screen và refresh
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tạo sự kiện thành công")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tạo sự kiện thất bại")),
      );
    }
  }

  Future<void> pickDateTime(bool isStart) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
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
      } else {
        endTime = dateTime;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat("dd/MM/yyyy HH:mm");

    return Scaffold(
      appBar: AppBar(title: const Text("Tạo sự kiện mới")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: "Tiêu đề sự kiện"),
                validator: (v) => v == null || v.isEmpty ? "Không được bỏ trống" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: "Mô tả"),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: locationCtrl,
                decoration: const InputDecoration(labelText: "Địa điểm"),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: Text(startTime == null
                    ? "Chọn ngày bắt đầu"
                    : "Bắt đầu: ${formatter.format(startTime!)}"),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => pickDateTime(true),
              ),
              ListTile(
                title: Text(endTime == null
                    ? "Chọn ngày kết thúc"
                    : "Kết thúc: ${formatter.format(endTime!)}"),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => pickDateTime(false),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading ? null : handleCreate,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Tạo sự kiện"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
