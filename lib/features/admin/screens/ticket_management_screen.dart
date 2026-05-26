import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/api/api_client.dart';
import '../../../data/models/event_model.dart';
import '../../../data/models/ticket_type_model.dart';
import '../../../data/models/ticket_model.dart';
import '../../../data/services/event_service.dart';
import '../../../data/services/ticket_service.dart';

class TicketManagementScreen extends StatefulWidget {
  const TicketManagementScreen({super.key});

  @override
  State<TicketManagementScreen> createState() => _TicketManagementScreenState();
}

class _TicketManagementScreenState extends State<TicketManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Events list dùng cho dropdown filter
  List<Event> _events = [];
  Event? _selectedEvent;
  bool _isLoadingEvents = true;

  // TicketTypes
  List<TicketTypeModel> _ticketTypes = [];
  bool _isLoadingTypes = false;
  String? _typesError;

  // Tickets
  List<TicketModel> _tickets = [];
  bool _isLoadingTickets = false;
  String? _ticketsError;

  // Statistics
  Map<String, dynamic> _stats = {};
  bool _isLoadingStats = false;
  String? _statsError;

  static const _tabs = ['Loại vé', 'Vé', 'Thống kê'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging &&
          _tabController.index == 2 &&
          _stats.isEmpty) {
        _fetchStats();
      }
    });
    _loadEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── DATA ─────────────────────────────────────────────────────────────────

  Future<void> _loadEvents() async {
    try {
      final list = await EventService.getEvents();
      if (!mounted) return;
      setState(() {
        _events = list;
        _isLoadingEvents = false;
        if (list.isNotEmpty) {
          _selectedEvent = list.first;
          _fetchTicketTypes();
          _fetchTickets();
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingEvents = false);
    }
  }

  Future<void> _fetchTicketTypes() async {
    if (_selectedEvent == null) return;
    setState(() {
      _isLoadingTypes = true;
      _typesError = null;
    });
    try {
      final list = await TicketService.getTicketTypesByEvent(
        _selectedEvent!.id!,
      );
      if (!mounted) return;
      setState(() {
        _ticketTypes = list;
        _isLoadingTypes = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingTypes = false;
        _typesError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingTypes = false;
        _typesError = 'Không thể tải danh sách loại vé.';
      });
    }
  }

  Future<void> _fetchTickets() async {
    setState(() {
      _isLoadingTickets = true;
      _ticketsError = null;
    });
    try {
      final list = await TicketService.getTickets(eventId: _selectedEvent?.id);
      if (!mounted) return;
      setState(() {
        _tickets = list;
        _isLoadingTickets = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingTickets = false;
        _ticketsError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingTickets = false;
        _ticketsError = 'Không thể tải danh sách vé.';
      });
    }
  }

  Future<void> _fetchStats() async {
    setState(() {
      _isLoadingStats = true;
      _statsError = null;
    });
    try {
      final data = _selectedEvent != null
          ? await TicketService.getEventRevenue(_selectedEvent!.id!)
          : await TicketService.getRevenue();
      if (!mounted) return;
      setState(() {
        _stats = data;
        _isLoadingStats = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingStats = false;
        _statsError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingStats = false;
        _statsError = 'Không thể tải thống kê.';
      });
    }
  }

  void _onEventChanged(Event? event) {
    setState(() {
      _selectedEvent = event;
      _ticketTypes = [];
      _tickets = [];
      _stats = {};
    });
    _fetchTicketTypes();
    _fetchTickets();
    if (_tabController.index == 2) _fetchStats();
  }

  // ─── TICKET TYPE ACTIONS ───────────────────────────────────────────────────

  void _showCreateTicketTypeDialog() {
    if (_selectedEvent == null) {
      Get.snackbar(
        'Lưu ý',
        'Vui lòng chọn sự kiện trước.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool isSaving = false;

    Get.dialog(
      StatefulBuilder(
        builder: (_, setD) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('➕ Thêm loại vé'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _textField(
                    nameCtrl,
                    'Tên loại vé *',
                    Icons.label_outline,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Bắt buộc' : null,
                  ),
                  const SizedBox(height: 12),
                  _textField(
                    priceCtrl,
                    'Giá vé (VNĐ) *',
                    Icons.attach_money,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n <= 0) {
                        return 'Giá phải > 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _textField(
                    qtyCtrl,
                    'Số lượng *',
                    Icons.confirmation_number_outlined,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'Số lượng phải > 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _textField(descCtrl, 'Mô tả', Icons.description_outlined),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Get.back(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setD(() => isSaving = true);
                      Get.back();
                      try {
                        final created = await TicketService.createTicketType(
                          _selectedEvent!.id!,
                          name: nameCtrl.text.trim(),
                          price: double.parse(priceCtrl.text.trim()),
                          quantity: int.parse(qtyCtrl.text.trim()),
                          description: descCtrl.text.trim(),
                        );
                        if (!mounted) return;
                        setState(() => _ticketTypes.add(created));
                        Get.snackbar(
                          'Thành công',
                          'Đã thêm loại vé mới.',
                          backgroundColor: Colors.green,
                          colorText: Colors.white,
                          snackPosition: SnackPosition.BOTTOM,
                          margin: const EdgeInsets.all(16),
                        );
                      } on ApiException catch (e) {
                        Get.snackbar(
                          'Lỗi',
                          e.message,
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      }
                    },
              style: _purpleBtn(),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  void _showEditTicketTypeDialog(TicketTypeModel tt) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: tt.name);
    final priceCtrl = TextEditingController(text: tt.price.toString());
    final qtyCtrl = TextEditingController(text: tt.quantity.toString());
    final descCtrl = TextEditingController(text: tt.description);
    bool isSaving = false;

    Get.dialog(
      StatefulBuilder(
        builder: (_, setD) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('✏️ Sửa loại vé'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _textField(
                    nameCtrl,
                    'Tên loại vé *',
                    Icons.label_outline,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Bắt buộc' : null,
                  ),
                  const SizedBox(height: 12),
                  _textField(
                    priceCtrl,
                    'Giá vé (VNĐ) *',
                    Icons.attach_money,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'Giá phải > 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _textField(
                    qtyCtrl,
                    'Số lượng *',
                    Icons.confirmation_number_outlined,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'Số lượng phải > 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _textField(descCtrl, 'Mô tả', Icons.description_outlined),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Get.back(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setD(() => isSaving = true);
                      Get.back();
                      try {
                        final updated = await TicketService.updateTicketType(
                          tt.id,
                          name: nameCtrl.text.trim(),
                          price: double.parse(priceCtrl.text.trim()),
                          quantity: int.parse(qtyCtrl.text.trim()),
                          description: descCtrl.text.trim(),
                        );
                        if (!mounted) return;
                        setState(() {
                          final i = _ticketTypes.indexWhere(
                            (t) => t.id == tt.id,
                          );
                          if (i != -1) _ticketTypes[i] = updated;
                        });
                        Get.snackbar(
                          'Thành công',
                          'Đã cập nhật loại vé.',
                          backgroundColor: Colors.green,
                          colorText: Colors.white,
                          snackPosition: SnackPosition.BOTTOM,
                          margin: const EdgeInsets.all(16),
                        );
                      } on ApiException catch (e) {
                        Get.snackbar(
                          'Lỗi',
                          e.message,
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      }
                    },
              style: _purpleBtn(),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  void _confirmDeleteTicketType(TicketTypeModel tt) {
    if (tt.quantitySold > 0) {
      Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Không thể xóa',
            style: TextStyle(color: Colors.orange),
          ),
          content: Text(
            'Loại vé "${tt.name}" đã có ${tt.quantitySold} vé được bán.\n'
            'Không thể xóa loại vé đã có giao dịch.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Get.back(),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
      return;
    }
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '⚠️ Xóa loại vé?',
          style: TextStyle(color: Colors.red),
        ),
        content: Text(
          'Xóa loại vé "${tt.name}"? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              try {
                await TicketService.deleteTicketType(tt.id);
                if (!mounted) return;
                setState(() => _ticketTypes.removeWhere((t) => t.id == tt.id));
                Get.snackbar(
                  'Đã xóa',
                  'Loại vé đã được xóa.',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                  snackPosition: SnackPosition.BOTTOM,
                  margin: const EdgeInsets.all(16),
                );
              } on ApiException catch (e) {
                Get.snackbar(
                  'Lỗi',
                  e.message,
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  // ─── TICKET ACTIONS ────────────────────────────────────────────────────────

  void _showCreateTicketDialog() {
    if (_selectedEvent == null) {
      Get.snackbar(
        'Lưu ý',
        'Vui lòng chọn sự kiện trước.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 30));
    bool isActive = true;
    bool isSaving = false;

    Get.dialog(
      StatefulBuilder(
        builder: (_, setD) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('➕ Thêm vé'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _textField(
                    nameCtrl,
                    'Tên vé *',
                    Icons.label_outline,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Bắt buộc' : null,
                  ),
                  const SizedBox(height: 12),
                  _textField(
                    priceCtrl,
                    'Giá (VNĐ) *',
                    Icons.attach_money,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'Giá phải > 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _textField(
                    qtyCtrl,
                    'Số lượng *',
                    Icons.confirmation_number_outlined,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'Số lượng phải > 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _textField(descCtrl, 'Mô tả', Icons.description_outlined),
                  const SizedBox(height: 12),
                  // Start date picker
                  _datePicker(
                    label: 'Bắt đầu bán',
                    date: startDate,
                    onPick: (d) => setD(() => startDate = d),
                  ),
                  const SizedBox(height: 8),
                  _datePicker(
                    label: 'Kết thúc bán',
                    date: endDate,
                    onPick: (d) => setD(() => endDate = d),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Bán ngay'),
                    value: isActive,
                    onChanged: (v) => setD(() => isActive = v),
                    contentPadding: EdgeInsets.zero,
                    thumbColor: WidgetStateProperty.resolveWith(
                      (s) => s.contains(WidgetState.selected)
                          ? Colors.deepPurple
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Get.back(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      if (endDate.isBefore(startDate)) {
                        Get.snackbar(
                          'Lỗi',
                          'Ngày kết thúc phải sau ngày bắt đầu.',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                        return;
                      }
                      setD(() => isSaving = true);
                      Get.back();
                      try {
                        final created = await TicketService.createTicket(
                          _selectedEvent!.id!,
                          ticketName: nameCtrl.text.trim(),
                          price: double.parse(priceCtrl.text.trim()),
                          quantity: int.parse(qtyCtrl.text.trim()),
                          description: descCtrl.text.trim(),
                          startSaleDate: startDate,
                          endSaleDate: endDate,
                          isActive: isActive,
                        );
                        if (!mounted) return;
                        setState(() => _tickets.add(created));
                        Get.snackbar(
                          'Thành công',
                          'Đã thêm vé mới.',
                          backgroundColor: Colors.green,
                          colorText: Colors.white,
                          snackPosition: SnackPosition.BOTTOM,
                          margin: const EdgeInsets.all(16),
                        );
                      } on ApiException catch (e) {
                        Get.snackbar(
                          'Lỗi',
                          e.message,
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      }
                    },
              style: _purpleBtn(),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  void _showEditTicketDialog(TicketModel ticket) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: ticket.ticketName);
    final priceCtrl = TextEditingController(text: ticket.price.toString());
    final qtyCtrl = TextEditingController(text: ticket.quantity.toString());
    final descCtrl = TextEditingController(text: ticket.description);
    DateTime startDate = ticket.startSaleDate;
    DateTime endDate = ticket.endSaleDate;
    bool isActive = ticket.isActive;
    bool isSaving = false;

    Get.dialog(
      StatefulBuilder(
        builder: (_, setD) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('✏️ Sửa vé'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _textField(
                    nameCtrl,
                    'Tên vé *',
                    Icons.label_outline,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Bắt buộc' : null,
                  ),
                  const SizedBox(height: 12),
                  _textField(
                    priceCtrl,
                    'Giá (VNĐ) *',
                    Icons.attach_money,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'Giá phải > 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _textField(
                    qtyCtrl,
                    'Số lượng *',
                    Icons.confirmation_number_outlined,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'Số lượng phải > 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _textField(descCtrl, 'Mô tả', Icons.description_outlined),
                  const SizedBox(height: 12),
                  _datePicker(
                    label: 'Bắt đầu bán',
                    date: startDate,
                    onPick: (d) => setD(() => startDate = d),
                  ),
                  const SizedBox(height: 8),
                  _datePicker(
                    label: 'Kết thúc bán',
                    date: endDate,
                    onPick: (d) => setD(() => endDate = d),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Đang bán'),
                    value: isActive,
                    onChanged: (v) => setD(() => isActive = v),
                    contentPadding: EdgeInsets.zero,
                    thumbColor: WidgetStateProperty.resolveWith(
                      (s) => s.contains(WidgetState.selected)
                          ? Colors.deepPurple
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Get.back(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      if (endDate.isBefore(startDate)) {
                        Get.snackbar(
                          'Lỗi',
                          'Ngày kết thúc phải sau ngày bắt đầu.',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                        return;
                      }
                      setD(() => isSaving = true);
                      Get.back();
                      try {
                        final updated = await TicketService.updateTicket(
                          ticket.id,
                          ticketName: nameCtrl.text.trim(),
                          price: double.parse(priceCtrl.text.trim()),
                          quantity: int.parse(qtyCtrl.text.trim()),
                          description: descCtrl.text.trim(),
                          startSaleDate: startDate,
                          endSaleDate: endDate,
                          isActive: isActive,
                        );
                        if (!mounted) return;
                        setState(() {
                          final i = _tickets.indexWhere(
                            (t) => t.id == ticket.id,
                          );
                          if (i != -1) _tickets[i] = updated;
                        });
                        Get.snackbar(
                          'Thành công',
                          'Đã cập nhật vé.',
                          backgroundColor: Colors.green,
                          colorText: Colors.white,
                          snackPosition: SnackPosition.BOTTOM,
                          margin: const EdgeInsets.all(16),
                        );
                      } on ApiException catch (e) {
                        Get.snackbar(
                          'Lỗi',
                          e.message,
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      }
                    },
              style: _purpleBtn(),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _toggleTicketStatus(TicketModel ticket) async {
    try {
      final updated = await TicketService.toggleTicketStatus(ticket.id);
      if (!mounted) return;
      setState(() {
        final i = _tickets.indexWhere((t) => t.id == ticket.id);
        if (i != -1) _tickets[i] = updated;
      });
      Get.snackbar(
        'Đã cập nhật',
        updated.isActive ? 'Vé đang mở bán.' : 'Đã tắt bán vé.',
        backgroundColor: updated.isActive ? Colors.green : Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } on ApiException catch (e) {
      Get.snackbar('Lỗi', e.message, snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _confirmDeleteTicket(TicketModel ticket) {
    if (ticket.sold > 0) {
      Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Không thể xóa',
            style: TextStyle(color: Colors.orange),
          ),
          content: Text(
            'Vé "${ticket.ticketName}" đã có ${ticket.sold} vé được bán.\n'
            'Không thể xóa vé đã có giao dịch.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Get.back(),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
      return;
    }
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('⚠️ Xóa vé?', style: TextStyle(color: Colors.red)),
        content: Text(
          'Xóa vé "${ticket.ticketName}"? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              try {
                await TicketService.deleteTicket(ticket.id);
                if (!mounted) return;
                setState(() => _tickets.removeWhere((t) => t.id == ticket.id));
                Get.snackbar(
                  'Đã xóa',
                  'Vé đã được xóa.',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                  snackPosition: SnackPosition.BOTTOM,
                  margin: const EdgeInsets.all(16),
                );
              } on ApiException catch (e) {
                Get.snackbar(
                  'Lỗi',
                  e.message,
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Quản lý vé',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.deepPurple,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.deepPurple,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: Column(
        children: [
          _buildEventSelector(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTicketTypesTab(),
                _buildTicketsTab(),
                _buildStatsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  // ─── EVENT SELECTOR ───────────────────────────────────────────────────────

  Widget _buildEventSelector() {
    if (_isLoadingEvents) {
      return const LinearProgressIndicator(color: Colors.deepPurple);
    }
    if (_events.isEmpty) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.event, size: 18, color: Colors.deepPurple),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Event>(
                value: _selectedEvent,
                isExpanded: true,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                items: _events
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e.title, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: _onEventChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── TICKET TYPES TAB ─────────────────────────────────────────────────────

  Widget _buildTicketTypesTab() {
    if (_isLoadingTypes) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_typesError != null) {
      return _errorState(_typesError!, _fetchTicketTypes);
    }
    if (_ticketTypes.isEmpty) {
      return _emptyState(
        Icons.label_outline,
        'Chưa có loại vé nào cho sự kiện này',
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchTicketTypes,
      color: Colors.deepPurple,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _ticketTypes.length,
        itemBuilder: (_, i) => _ticketTypeCard(_ticketTypes[i]),
      ),
    );
  }

  Widget _ticketTypeCard(TicketTypeModel tt) {
    final soldOut = tt.remaining <= 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tt.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _chip(
                  soldOut ? 'Hết vé' : 'Còn vé',
                  soldOut ? Colors.red : Colors.green,
                ),
              ],
            ),
            if (tt.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                tt.description,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                _statItem('Giá', _fmtPrice(tt.price), Colors.deepPurple),
                _statItem('Tổng', '${tt.quantity}', Colors.blue),
                _statItem('Đã bán', '${tt.quantitySold}', Colors.orange),
                _statItem(
                  'Còn lại',
                  '${tt.remaining}',
                  tt.remaining > 0 ? Colors.green : Colors.red,
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showEditTicketTypeDialog(tt),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Sửa'),
                  style: TextButton.styleFrom(foregroundColor: Colors.blue),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: () => _confirmDeleteTicketType(tt),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Xóa'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── TICKETS TAB ──────────────────────────────────────────────────────────

  Widget _buildTicketsTab() {
    if (_isLoadingTickets) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_ticketsError != null) {
      return _errorState(_ticketsError!, _fetchTickets);
    }
    if (_tickets.isEmpty) {
      return _emptyState(Icons.confirmation_number_outlined, 'Chưa có vé nào');
    }
    return RefreshIndicator(
      onRefresh: _fetchTickets,
      color: Colors.deepPurple,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tickets.length,
        itemBuilder: (_, i) => _ticketCard(_tickets[i]),
      ),
    );
  }

  Widget _ticketCard(TicketModel ticket) {
    final now = DateTime.now();
    final saleStarted = now.isAfter(ticket.startSaleDate);
    final saleEnded = now.isAfter(ticket.endSaleDate);
    final soldOut = ticket.remaining <= 0;

    String statusLabel;
    Color statusColor;
    if (!ticket.isActive) {
      statusLabel = 'Đã tắt';
      statusColor = Colors.grey;
    } else if (saleEnded) {
      statusLabel = 'Hết hạn';
      statusColor = Colors.red;
    } else if (soldOut) {
      statusLabel = 'Hết vé';
      statusColor = Colors.red;
    } else if (!saleStarted) {
      statusLabel = 'Chưa mở';
      statusColor = Colors.blue;
    } else {
      statusLabel = 'Đang bán';
      statusColor = Colors.green;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    ticket.ticketName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _chip(statusLabel, statusColor),
              ],
            ),
            if (ticket.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                ticket.description,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                _statItem('Giá', _fmtPrice(ticket.price), Colors.deepPurple),
                _statItem('Tổng', '${ticket.quantity}', Colors.blue),
                _statItem('Đã bán', '${ticket.sold}', Colors.orange),
                _statItem(
                  'Còn lại',
                  '${ticket.remaining}',
                  ticket.remaining > 0 ? Colors.green : Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 12, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  '${_fmtDate(ticket.startSaleDate)} → ${_fmtDate(ticket.endSaleDate)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Toggle bán
                TextButton.icon(
                  onPressed: () => _toggleTicketStatus(ticket),
                  icon: Icon(
                    ticket.isActive
                        ? Icons.toggle_on_outlined
                        : Icons.toggle_off_outlined,
                    size: 16,
                  ),
                  label: Text(ticket.isActive ? 'Tắt bán' : 'Mở bán'),
                  style: TextButton.styleFrom(
                    foregroundColor: ticket.isActive
                        ? Colors.orange
                        : Colors.green,
                  ),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: () => _showEditTicketDialog(ticket),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Sửa'),
                  style: TextButton.styleFrom(foregroundColor: Colors.blue),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: () => _confirmDeleteTicket(ticket),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Xóa'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── STATISTICS TAB ───────────────────────────────────────────────────────

  Widget _buildStatsTab() {
    if (_isLoadingStats) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_statsError != null) {
      return _errorState(_statsError!, _fetchStats);
    }
    if (_stats.isEmpty) {
      return Center(
        child: ElevatedButton.icon(
          onPressed: _fetchStats,
          icon: const Icon(Icons.bar_chart),
          label: const Text('Tải thống kê'),
          style: _purpleBtn(),
        ),
      );
    }

    // Tính từ local data nếu backend trả đủ hoặc dùng API response
    final localTotalSold = _tickets.fold<int>(0, (s, t) => s + t.sold);
    final localRemaining = _tickets.fold<int>(0, (s, t) => s + t.remaining);
    final localRevenue = _tickets.fold<double>(
      0,
      (s, t) => s + t.price * t.sold,
    );

    final apiTotalSold =
        _stats['totalSold'] ?? _stats['totalTicketsSold'] ?? localTotalSold;
    final apiRemaining =
        _stats['remaining'] ?? _stats['totalRemaining'] ?? localRemaining;
    final apiRevenue =
        _stats['totalRevenue'] ?? _stats['revenue'] ?? localRevenue;

    final byEvent =
        _stats['byEvent'] ?? _stats['events'] ?? _stats['eventStats'];

    return RefreshIndicator(
      onRefresh: _fetchStats,
      color: Colors.deepPurple,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _selectedEvent != null
                  ? _selectedEvent!.title
                  : 'Tổng quan tất cả sự kiện',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 12),
            // Overview cards
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    'Tổng vé bán',
                    '$apiTotalSold',
                    Icons.sell_outlined,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statCard(
                    'Còn lại',
                    '$apiRemaining',
                    Icons.confirmation_number_outlined,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _statCard(
              'Doanh thu',
              _fmtPrice((apiRevenue as num).toDouble()),
              Icons.payments_outlined,
              Colors.green,
              fullWidth: true,
            ),
            if (byEvent is List && byEvent.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                'Doanh thu theo sự kiện',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              ...byEvent.map((e) => _eventRevenueTile(e)),
            ],
            // Local breakdown if no byEvent from API
            if ((byEvent == null || byEvent is! List) &&
                _tickets.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                'Chi tiết vé trong sự kiện',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              ..._tickets.map(_ticketStatRow),
            ],
          ],
        ),
      ),
    );
  }

  Widget _ticketStatRow(TicketModel t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              t.ticketName,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Đã bán: ${t.sold}/${t.quantity}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                'DT: ${_fmtPrice(t.price * t.sold)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _eventRevenueTile(dynamic e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              (e['eventTitle'] ?? e['title'] ?? 'Sự kiện').toString(),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Bán: ${e['totalSold'] ?? e['sold'] ?? 0}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                _fmtPrice(
                  ((e['revenue'] ?? e['totalRevenue'] ?? 0) as num).toDouble(),
                ),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    bool fullWidth = false,
  }) {
    final card = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
    return fullWidth ? card : card;
  }

  // ─── FAB ──────────────────────────────────────────────────────────────────

  Widget? _buildFab() {
    final tab = _tabController.index;
    if (tab == 2) return null;
    return FloatingActionButton.extended(
      onPressed: tab == 0
          ? _showCreateTicketTypeDialog
          : _showCreateTicketDialog,
      backgroundColor: Colors.deepPurple,
      icon: const Icon(Icons.add, color: Colors.white),
      label: Text(
        tab == 0 ? 'Thêm loại vé' : 'Thêm vé',
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────────

  Widget _textField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      validator: validator,
    );
  }

  Widget _datePicker({
    required String label,
    required DateTime date,
    required void Function(DateTime) onPick,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (ctx, child) => Theme(
            data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(primary: Colors.deepPurple),
            ),
            child: child!,
          ),
        );
        if (picked != null) onPick(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today, size: 18),
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        child: Text(_fmtDate(date), style: const TextStyle(fontSize: 14)),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _errorState(String msg, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(IconData icon, String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(msg, style: TextStyle(fontSize: 15, color: Colors.grey[600])),
        ],
      ),
    );
  }

  ButtonStyle _purpleBtn() => ElevatedButton.styleFrom(
    backgroundColor: Colors.deepPurple,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );

  String _fmtPrice(double price) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(price)}đ';
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';
}
