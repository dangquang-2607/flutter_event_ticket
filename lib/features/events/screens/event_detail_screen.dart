import 'dart:convert';
import 'package:event_ticket_app/features/events/screens/event_user_buttons.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:event_ticket_app/features/events/eventmembers/event_members_list.dart';

class EventDetailScreen extends StatefulWidget {
  final int eventId;
  final String? userRole;
  const EventDetailScreen({super.key, required this.eventId, this.userRole});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  Map<String, dynamic>? event;
  bool isLoading = true;
  String? role;

  @override
  void initState() {
    super.initState();
    fetchEventDetail();
  }

  Future<void> fetchEventDetail() async {
    setState(() => isLoading = true);
    try {
      final box = GetStorage();
      final token = box.read('accessToken') as String?;
      role = (box.read('role') as String?) ?? widget.userRole;

      if (token == null || token.isEmpty) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Token không tồn tại. Vui lòng đăng nhập lại.'),
          ),
        );
        return;
      }

      final url = Uri.parse(
        'http://10.0.2.2:5054/api/events/${widget.eventId}',
      );
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          event = decoded is Map<String, dynamic>
              ? decoded
              : Map<String, dynamic>.from(decoded);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi ${response.statusCode}: ${response.body}'),
          ),
        );
      }
    } catch (e, st) {
      setState(() => isLoading = false);
      debugPrint('fetchEventDetail error: $e\n$st');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<void> updateEvent(
    String title,
    String location,
    String start,
    String end,
    String desc,
  ) async {
    try {
      final box = GetStorage();
      final token = box.read('accessToken') as String?;
      if (token == null || token.isEmpty) return;

      final response = await http.put(
        Uri.parse('http://10.0.2.2:5054/api/events/${widget.eventId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'title': title,
          'location': location,
          'startTime': start,
          'endTime': end,
          'description': desc,
        }),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✅ Cập nhật thành công')));
        await fetchEventDetail();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi ${response.statusCode}: ${response.body}'),
          ),
        );
      }
    } catch (e) {
      debugPrint('updateEvent error: $e');
    }
  }

  Future<void> deleteEvent() async {
    try {
      final box = GetStorage();
      final token = box.read('accessToken') as String?;
      if (token == null || token.isEmpty) return;

      final response = await http.delete(
        Uri.parse('http://10.0.2.2:5054/api/events/${widget.eventId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        if (!mounted) return;
        Navigator.pop(context, true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✅ Sự kiện đã bị xóa')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi khi xóa: ${response.statusCode}')),
        );
      }
    } catch (e) {
      debugPrint('deleteEvent error: $e');
    }
  }

  void showEditDialog() async {
    final titleCtrl = TextEditingController(text: event?['title'] ?? '');
    final locationCtrl = TextEditingController(text: event?['location'] ?? '');
    final startCtrl = TextEditingController(text: event?['startTime'] ?? '');
    final endCtrl = TextEditingController(text: event?['endTime'] ?? '');
    final descCtrl = TextEditingController(text: event?['description'] ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh sửa sự kiện'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Tiêu đề'),
              ),
              TextField(
                controller: locationCtrl,
                decoration: const InputDecoration(labelText: 'Địa điểm'),
              ),
              TextField(
                controller: startCtrl,
                decoration: const InputDecoration(
                  labelText: 'Bắt đầu (yyyy-MM-dd HH:mm)',
                ),
              ),
              TextField(
                controller: endCtrl,
                decoration: const InputDecoration(
                  labelText: 'Kết thúc (yyyy-MM-dd HH:mm)',
                ),
              ),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Mô tả'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              updateEvent(
                titleCtrl.text.trim(),
                locationCtrl.text.trim(),
                startCtrl.text.trim(),
                endCtrl.text.trim(),
                descCtrl.text.trim(),
              );
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa sự kiện'),
        content: const Text('Bạn có chắc muốn xóa sự kiện này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) await deleteEvent();
  }

  bool get isOrganizer => role?.toLowerCase() == 'organizer';
  bool get isUser => role?.toLowerCase() == 'user';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết sự kiện'),
        actions: [
          if (event != null && isOrganizer)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  showEditDialog();
                } else if (value == 'delete') {
                  confirmDelete();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa')),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Xóa', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : event == null
          ? const Center(child: Text('Không có dữ liệu'))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 220,
                    child: Image.asset(
                      'assets/images/events/event.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event!['title'] ?? 'No title',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.red),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                event!['location'] ?? 'Không rõ địa điểm',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: Colors.deepPurple,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Bắt đầu: ${event!['startTime']?.toString().substring(0, 16) ?? 'N/A'}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.event_available,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Kết thúc: ${event!['endTime']?.toString().substring(0, 16) ?? 'N/A'}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        const Divider(height: 30),
                        const Text(
                          'Mô tả',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          event!['description'] ?? 'Không có mô tả',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 20),
                        EventMembersList(eventId: widget.eventId),
                        if (isUser) EventUserButtons(eventId: widget.eventId),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
