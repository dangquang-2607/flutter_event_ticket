import 'dart:convert';
import 'package:event_ticket_app/features/events/widgets/event_user_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:event_ticket_app/features/events/widgets/event_members_list.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/services/event_service.dart';
import '../../../data/models/event_model.dart';

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
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final box = GetStorage();
      final token = box.read('accessToken') as String?;
      role = (box.read('role') as String?) ?? widget.userRole;

      if (token == null || token.isEmpty) {
        if (mounted) {
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Token không tồn tại. Vui lòng đăng nhập lại.'),
            ),
          );
        }
        return;
      }

      final url = Uri.parse('${AppConstants.eventsEndpoint}/${widget.eventId}');
      debugPrint('=== Fetching event detail from: $url ===');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Raw response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final decoded = jsonDecode(response.body);
          debugPrint('=== FULL DECODED JSON ===');
          debugPrint('$decoded');
          debugPrint('===========================');
          debugPrint('Title: ${decoded['title']}');
          debugPrint('Location: ${decoded['location']}');
          debugPrint('Description: ${decoded['description']}');
          debugPrint('StartTime: ${decoded['startTime']}');
          debugPrint('EndTime: ${decoded['endTime']}');
          debugPrint(
            'Price: ${decoded['price']} (type: ${decoded['price'].runtimeType})',
          );
          debugPrint(
            'MaxTickets: ${decoded['maxTickets']} (type: ${decoded['maxTickets'].runtimeType})',
          );
          debugPrint('RegisteredTickets: ${decoded['registeredTickets']}');
          debugPrint('IsRegistrationOpen: ${decoded['isRegistrationOpen']}');
          debugPrint('Status: ${decoded['status']}');

          if (!mounted) return;

          setState(() {
            event = decoded is Map<String, dynamic>
                ? decoded
                : Map<String, dynamic>.from(decoded);
            isLoading = false;
          });

          debugPrint('Event state updated. Current event: $event');
        } catch (parseError) {
          debugPrint('JSON parse error: $parseError');
          if (mounted) {
            setState(() => isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('❌ Lỗi parse dữ liệu: $parseError')),
            );
          }
        }
      } else {
        if (mounted) {
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Lỗi ${response.statusCode}: ${response.body}'),
            ),
          );
        }
      }
    } catch (e, st) {
      debugPrint('fetchEventDetail error: $e\n$st');
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  Future<void> updateEvent(
    String title,
    String location,
    String start,
    String end,
    String desc, [
    int maxTickets = 0,
    double price = 0,
    bool isRegistrationOpen = false,
    String status = 'Sắp diễn ra',
  ]) async {
    try {
      debugPrint('=== updateEvent called ===');
      debugPrint('  title: $title');
      debugPrint('  location: $location');
      debugPrint('  start: $start');
      debugPrint('  end: $end');
      debugPrint('  desc: $desc');
      debugPrint('  maxTickets: $maxTickets');
      debugPrint('  price: $price');
      debugPrint('  isRegistrationOpen: $isRegistrationOpen');
      debugPrint('  status: $status');

      final updatedEvent = Event(
        id: widget.eventId,
        title: title,
        location: location,
        startTime: DateTime.parse(start),
        endTime: DateTime.parse(end),
        description: desc,
        maxTickets: maxTickets,
        price: price,
        isRegistrationOpen: isRegistrationOpen,
        status: status,
        registeredTickets:
            event?['registeredCount'] ?? event?['registeredTickets'] ?? 0,
      );

      debugPrint('Event object created: ${updatedEvent.toJson()}');
      debugPrint('Calling EventService.updateEvent');
      final success = await EventService.updateEvent(updatedEvent);

      if (!mounted) return;
      if (success) {
        debugPrint('Update successful, fetching new data');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✅ Cập nhật thành công')));

        // Force rebuild trước fetch để ensure UI refresh
        setState(() {
          event = null;
          isLoading = true;
        });

        // Add small delay để ensure backend xử lý xong
        await Future.delayed(const Duration(milliseconds: 800));

        debugPrint('Starting fetchEventDetail after update');
        await fetchEventDetail();
        debugPrint('fetchEventDetail completed');
      } else {
        debugPrint('Update failed: service returned false');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('❌ Cập nhật thất bại')));
      }
    } catch (e, st) {
      debugPrint('updateEvent error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  Future<void> deleteEvent() async {
    try {
      final box = GetStorage();
      final token = box.read('accessToken') as String?;
      if (token == null || token.isEmpty) return;

      final response = await http.delete(
        Uri.parse('${AppConstants.eventsEndpoint}/${widget.eventId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✅ Sự kiện đã bị xóa')));
        Navigator.pop(context, true);
      } else {
        if (!mounted) return;
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
    final descCtrl = TextEditingController(text: event?['description'] ?? '');
    final maxTicketsCtrl = TextEditingController(
      text: (event?['maxAttendees'] ?? event?['maxTickets'] ?? 0).toString(),
    );
    final priceCtrl = TextEditingController(
      text: (event?['ticketPrice'] ?? event?['price'] ?? 0).toString(),
    );
    final startCtrl = TextEditingController(text: event?['startTime'] ?? '');
    final endCtrl = TextEditingController(text: event?['endTime'] ?? '');

    debugPrint('=== showEditDialog ===');
    debugPrint('Event data: $event');
    debugPrint('maxTicketsCtrl: ${maxTicketsCtrl.text}');
    debugPrint('priceCtrl: ${priceCtrl.text}');
    debugPrint('startTime raw: ${event?['startTime']}');
    debugPrint('endTime raw: ${event?['endTime']}');

    final List<String> statuses = [
      "Sắp diễn ra",
      "Đang diễn ra",
      "Đã kết thúc",
    ];
    final formatter = DateFormat("dd/MM/yyyy HH:mm");

    // Khởi tạo state TRƯỚC showDialog để không bị reset khi rebuild
    bool isRegistrationOpen = event?['isRegistrationOpen'] ?? false;
    String eventStatus = event?['status'] ?? 'Sắp diễn ra';
    if (!statuses.contains(eventStatus)) {
      eventStatus = 'Sắp diễn ra';
    }
    DateTime? startTime = event?['startTime'] != null
        ? DateTime.parse(event!['startTime'])
        : null;
    DateTime? endTime = event?['endTime'] != null
        ? DateTime.parse(event!['endTime'])
        : null;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
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
            if (!context.mounted) return;

            final pickedTime = await showTimePicker(
              context: context,
              initialTime: isStart
                  ? TimeOfDay.fromDateTime(startTime ?? DateTime.now())
                  : TimeOfDay.fromDateTime(endTime ?? DateTime.now()),
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
                startCtrl.text = formatter.format(dateTime);
                // Nếu endTime cũ nhỏ hơn startTime mới, auto set endTime
                if (endTime != null && endTime!.isBefore(startTime!)) {
                  endTime = startTime!.add(const Duration(hours: 1));
                  endCtrl.text = formatter.format(endTime!);
                }
              } else {
                endTime = dateTime;
                endCtrl.text = formatter.format(dateTime);
              }
            });
          }

          return AlertDialog(
            title: const Text('Chỉnh sửa sự kiện'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Tên sự kiện'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Mô tả'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: locationCtrl,
                    decoration: const InputDecoration(labelText: 'Địa điểm'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: maxTicketsCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Số lượng vé tối đa',
                      hintText: 'Chỉ nhập số',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+(\.\d{0,2})?$'),
                      ),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Giá vé (đ)',
                      hintText: 'Chỉ nhập số',
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => pickDateTime(true),
                    child: TextField(
                      controller: startCtrl,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Thời gian bắt đầu',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => pickDateTime(false),
                    child: TextField(
                      controller: endCtrl,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Thời gian kết thúc',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                    ),
                  ),
                  if (startTime != null && endTime != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info,
                              color: Colors.blue,
                              size: 20,
                            ),
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
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: isRegistrationOpen,
                    onChanged: (val) {
                      debugPrint(
                        'Checkbox tapped! Old: $isRegistrationOpen, New: $val',
                      );
                      setState(() => isRegistrationOpen = val ?? false);
                      debugPrint('After setState: $isRegistrationOpen');
                    },
                    title: const Text('Mở đăng ký'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: eventStatus,
                    decoration: const InputDecoration(labelText: 'Trạng thái'),
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
                  // Validation
                  if (startTime == null || endTime == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          '❌ Vui lòng chọn cả ngày bắt đầu và kết thúc',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (startTime!.isAfter(endTime!)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          '❌ Ngày bắt đầu phải trước ngày kết thúc',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (startTime!.isAtSameMomentAs(endTime!)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          '❌ Ngày bắt đầu và kết thúc không được giống nhau',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  Navigator.pop(context);
                  debugPrint('=== Save button clicked ===');
                  debugPrint('titleCtrl: ${titleCtrl.text.trim()}');
                  debugPrint('locationCtrl: ${locationCtrl.text.trim()}');
                  debugPrint('descCtrl: ${descCtrl.text.trim()}');
                  debugPrint(
                    'maxTicketsCtrl: ${maxTicketsCtrl.text.trim()} => ${int.tryParse(maxTicketsCtrl.text) ?? 0}',
                  );
                  debugPrint(
                    'priceCtrl: ${priceCtrl.text.trim()} => ${double.tryParse(priceCtrl.text) ?? 0}',
                  );
                  debugPrint('startTime: ${startTime?.toIso8601String()}');
                  debugPrint('endTime: ${endTime?.toIso8601String()}');
                  debugPrint(
                    'isRegistrationOpen: $isRegistrationOpen (type: ${isRegistrationOpen.runtimeType})',
                  );
                  debugPrint('eventStatus: $eventStatus');

                  updateEvent(
                    titleCtrl.text.trim(),
                    locationCtrl.text.trim(),
                    startTime!.toIso8601String(),
                    endTime!.toIso8601String(),
                    descCtrl.text.trim(),
                    int.tryParse(maxTicketsCtrl.text) ?? 0,
                    double.tryParse(priceCtrl.text) ?? 0,
                    isRegistrationOpen,
                    eventStatus,
                  );
                },
                child: const Text('Lưu'),
              ),
            ],
          );
        },
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

  // Helper methods
  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return 'N/A';
    try {
      final dt = dateTime is String ? DateTime.parse(dateTime) : dateTime;
      final formatter = DateFormat('dd/MM/yyyy HH:mm');
      return formatter.format(dt);
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '0 đ';
    try {
      final priceNum = price is String
          ? double.parse(price)
          : (price as num).toDouble();
      final formatter = NumberFormat('#,##0', 'vi_VN');
      return '${formatter.format(priceNum)} đ';
    } catch (e) {
      return '0 đ';
    }
  }

  Widget _buildInfoItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, color: Color(0xFFE2E8F0), indent: 60),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryAmethyst = Color(0xFF7C3AED);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: const Text(
          'Chi tiết sự kiện',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchEventDetail,
          ),
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
          ? const Center(child: CircularProgressIndicator(color: primaryAmethyst))
          : event == null
          ? const Center(child: Text('Không có dữ liệu', style: TextStyle(color: Color(0xFF475569))))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header image
                  SizedBox(
                    width: double.infinity,
                    height: 220,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          'assets/images/events/event.png',
                          fit: BoxFit.cover,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withValues(alpha: 0.4),
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.4),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                        // Status badge
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Text(
                              event!['status'] ?? 'N/A',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          event!['title'] ?? 'Không có tiêu đề',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Info cards
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Column(
                            children: [
                              // Location
                              _buildInfoItem(
                                icon: Icons.location_on,
                                iconColor: const Color(0xFFEF4444),
                                label: 'Địa điểm',
                                value: event!['location'] ?? 'Không rõ',
                                isFirst: true,
                              ),
                              // Start time
                              _buildInfoItem(
                                icon: Icons.event_available,
                                iconColor: primaryAmethyst,
                                label: 'Bắt đầu',
                                value: _formatDateTime(event!['startTime']),
                              ),
                              // End time
                              _buildInfoItem(
                                icon: Icons.event_busy,
                                iconColor: const Color(0xFFF59E0B),
                                label: 'Kết thúc',
                                value: _formatDateTime(event!['endTime']),
                              ),
                              // Price
                              _buildInfoItem(
                                icon: Icons.local_offer,
                                iconColor: const Color(0xFF0D9488),
                                label: 'Giá vé',
                                value: _formatPrice(
                                  event!['ticketPrice'] ?? event!['price'] ?? 0,
                                ),
                              ),
                              // Max tickets
                              _buildInfoItem(
                                icon: Icons.confirmation_number,
                                iconColor: const Color(0xFF3B82F6),
                                label: 'Vé tối đa',
                                value:
                                    '${event!['maxAttendees'] ?? event!['maxTickets'] ?? 0} vé',
                              ),
                              // Registered
                              _buildInfoItem(
                                icon: Icons.people,
                                iconColor: const Color(0xFF8B5CF6),
                                label: 'Đã đăng ký',
                                value:
                                    '${event!['registeredCount'] ?? event!['registeredTickets'] ?? 0} người',
                              ),
                              // Registration status
                              _buildInfoItem(
                                icon: Icons.check_circle,
                                iconColor: const Color(0xFF10B981),
                                label: 'Mở đăng ký',
                                value: (event!['isRegistrationOpen'] ?? false)
                                    ? 'Mở đăng ký'
                                    : 'Đóng đăng ký',
                                isLast: true,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Description section
                        const Text(
                          'Mô tả sự kiện',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Text(
                            event!['description'] ?? 'Không có mô tả',
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.6,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Members section
                        EventMembersList(eventId: widget.eventId),
                        const SizedBox(height: 20),

                        if (isUser)
                          EventUserButtons(
                            eventId: widget.eventId,
                            eventTitle: event!['title'] ?? 'Sự kiện',
                            price: double.tryParse((event!['ticketPrice'] ?? event!['price'] ?? 0).toString()) ?? 0.0,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
