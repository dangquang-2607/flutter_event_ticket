import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../data/services/admin_service.dart';
import '../../../data/api/api_client.dart';
import '../../../data/models/user_model.dart';

// UserDetailScreen — full CRUD detail view for a single user

class UserDetailScreen extends StatefulWidget {
  final UserModel user;

  const UserDetailScreen({super.key, required this.user});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen>
    with SingleTickerProviderStateMixin {
  final _box = GetStorage();
  late UserModel _user;
  late TabController _tabController;
  late String _currentUserName;

  // tab data
  List<dynamic> _tickets = [];
  List<dynamic> _events = [];
  bool _isLoadingTickets = true;
  bool _isLoadingEvents = true;

  // action booleans
  bool _isTogglingLock = false;
  bool _isDeleting = false;
  bool _isUpdatingRole = false;
  bool _isUpdatingInfo = false;

  // tab error messages
  String? _ticketsError;
  String? _eventsError;

  static const _tabs = ['Hồ sơ', 'Lịch sử đăng ký', 'Sự kiện'];

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _currentUserName = ((_box.read('userName') as String?) ?? '').toLowerCase();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        if (_tabController.index == 1 && _isLoadingTickets) {
          _fetchTickets();
        } else if (_tabController.index == 2 && _isLoadingEvents) {
          _fetchEvents();
        }
      }
    });
    _fetchTickets();
    _fetchEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _isSelf => _user.userName.toLowerCase() == _currentUserName;

  // ─── DATA ────────────────────────────────────────────────────────────────────

  Future<void> _fetchTickets() async {
    setState(() {
      _isLoadingTickets = true;
      _ticketsError = null;
    });
    try {
      final detail = await AdminService.getUserDetail(_user.userId);
      if (!mounted) return;
      // Backend trả về lịch sử đăng ký trong field registrations (hoặc tương đương)
      final raw =
          detail['registrations'] ??
          detail['eventRegistrations'] ??
          detail['ticketHistory'] ??
          detail['tickets'] ??
          [];
      setState(() {
        _tickets = raw is List ? List<dynamic>.from(raw) : [];
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
        _ticketsError = 'Không thể tải lịch sử đăng ký.';
      });
    }
  }

  Future<void> _fetchEvents() async {
    setState(() {
      _isLoadingEvents = true;
      _eventsError = null;
    });
    try {
      final result = await AdminService.getUserAttendedEvents(_user.userId);
      if (!mounted) return;
      setState(() {
        _events = result;
        _isLoadingEvents = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingEvents = false;
        _eventsError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingEvents = false;
        _eventsError = 'Không thể tải danh sách sự kiện.';
      });
    }
  }

  // ─── ACTIONS ─────────────────────────────────────────────────────────────────

  void _navigateBack() {
    Get.back(result: {'action': 'updated', 'user': _user});
  }

  Future<void> _toggleLock() async {
    if (_isSelf) return;
    setState(() => _isTogglingLock = true);
    try {
      if (_user.isLocked) {
        await AdminService.unlockUser(_user.userId);
      } else {
        await AdminService.lockUser(_user.userId);
      }
      if (!mounted) return;
      setState(() {
        _user = _user.copyWith(isLocked: !_user.isLocked);
        _isTogglingLock = false;
      });
      Get.snackbar(
        'Đã thực hiện',
        _user.isLocked
            ? 'Đã khóa tài khoản ${_user.userName}'
            : 'Đã mở khóa tài khoản ${_user.userName}',
        backgroundColor: _user.isLocked ? Colors.orange : Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isTogglingLock = false);
      Get.snackbar('Lỗi', e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isTogglingLock = false);
      Get.snackbar('Lỗi', 'Không thể thay đổi trạng thái tài khoản.');
    }
  }

  Future<void> _updateRole(String newRole) async {
    setState(() => _isUpdatingRole = true);
    try {
      await AdminService.updateUserInfo(_user.userId, role: newRole);
      if (!mounted) return;
      setState(() {
        _user = _user.copyWith(role: newRole);
        _isUpdatingRole = false;
      });
      Get.snackbar(
        'Đã cập nhật',
        'Vai trò đã đổi thành $newRole',
        backgroundColor: Colors.deepPurple,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isUpdatingRole = false);
      Get.snackbar('Lỗi', e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isUpdatingRole = false);
      Get.snackbar('Lỗi', 'Không thể cập nhật vai trò.');
    }
  }

  Future<void> _updateInfo({
    required String userName,
    required String email,
  }) async {
    setState(() => _isUpdatingInfo = true);
    try {
      await AdminService.updateUserInfo(
        _user.userId,
        userName: userName,
        email: email,
      );
      if (!mounted) return;
      setState(() {
        _user = _user.copyWith(userName: userName, email: email);
        _isUpdatingInfo = false;
      });
      Get.snackbar(
        'Đã cập nhật',
        'Thông tin tài khoản đã được cập nhật',
        backgroundColor: Colors.deepPurple,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isUpdatingInfo = false);
      Get.snackbar('Lỗi', e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isUpdatingInfo = false);
      Get.snackbar('Lỗi', 'Không thể cập nhật thông tin.');
    }
  }

  void _showEditInfoDialog() {
    final formKey = GlobalKey<FormState>();
    final userNameCtrl = TextEditingController(text: _user.userName);
    final emailCtrl = TextEditingController(text: _user.email);
    bool isSaving = false;

    Get.dialog(
      StatefulBuilder(
        builder: (_, setD) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Chỉnh sửa thông tin'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: userNameCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Tên đăng nhập',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Vui lòng nhập tên đăng nhập';
                    }
                    if (v.trim().length < 3) return 'Tối thiểu 3 ký tự';
                    if (v.trim().contains(' ')) {
                      return 'Không được chứa khoảng trắng';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Vui lòng nhập email';
                    }
                    final re = RegExp(
                      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
                    );
                    if (!re.hasMatch(v.trim())) return 'Email không hợp lệ';
                    return null;
                  },
                ),
              ],
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
                  : () {
                      if (!formKey.currentState!.validate()) return;
                      final newName = userNameCtrl.text.trim();
                      final newEmail = emailCtrl.text.trim();
                      if (newName == _user.userName &&
                          newEmail == _user.email) {
                        Get.back();
                        return;
                      }
                      setD(() => isSaving = true);
                      Get.back();
                      _updateInfo(userName: newName, email: newEmail);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Lưu'),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _deleteUser() async {
    setState(() => _isDeleting = true);
    try {
      await AdminService.deleteUser(_user.userId);
      if (!mounted) return;
      setState(() => _isDeleting = false);
      Get.back(result: {'action': 'deleted', 'userId': _user.userId});
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      Get.snackbar('Lỗi', e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      Get.snackbar('Lỗi', 'Không thể xóa tài khoản.');
    }
  }

  // ─── DIALOGS ──────────────────────────────────────────────────────────────────

  void _showLockDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              _user.isLocked ? Icons.lock_open : Icons.lock,
              color: _user.isLocked ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            Text(_user.isLocked ? 'Mở khóa?' : 'Khóa tài khoản?'),
          ],
        ),
        content: Text(
          _user.isLocked
              ? 'Mở khóa cho ${_user.userName}? Người dùng sẽ đăng nhập được lại.'
              : 'Khóa ${_user.userName}? Người dùng sẽ không thể đăng nhập.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _toggleLock();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _user.isLocked ? Colors.green : Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(_user.isLocked ? 'Mở khóa' : 'Khóa'),
          ),
        ],
      ),
    );
  }

  void _showEditRoleDialog() {
    // Normalize to exact values backend accepts: 'user' or 'Organizer'
    String currentRole = _user.role.toLowerCase() == 'organizer'
        ? 'Organizer'
        : 'user';
    String selectedRole = currentRole;
    bool isSaving = false;

    Get.dialog(
      StatefulBuilder(
        builder: (_, setD) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Chỉnh sửa vai trò'),
          content: DropdownButtonFormField<String>(
            initialValue: selectedRole,
            decoration: const InputDecoration(
              labelText: 'Vai trò',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            items: const [
              DropdownMenuItem(value: 'user', child: Text('user')),
              DropdownMenuItem(value: 'Organizer', child: Text('organizer')),
            ],
            onChanged: (v) => setD(() => selectedRole = v ?? selectedRole),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Get.back(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: (isSaving || selectedRole == currentRole)
                  ? null
                  : () async {
                      setD(() => isSaving = true);
                      Get.back();
                      await _updateRole(selectedRole);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Lưu'),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  void _showDeleteDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '⚠️ Xóa tài khoản?',
          style: TextStyle(color: Colors.red),
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa tài khoản "${_user.userName}"?\n\nHành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _deleteUser();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _navigateBack();
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: _navigateBack,
          ),
          title: Text(
            _user.userName,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          actions: [
            if (!_isSelf)
              _isUpdatingInfo
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.deepPurple,
                        ),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(
                        Icons.manage_accounts_outlined,
                        color: Colors.black87,
                      ),
                      onPressed: _showEditInfoDialog,
                      tooltip: 'Chỉnh sửa thông tin',
                    ),
          ],
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
            _buildProfileHeader(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildProfileTab(),
                  _buildTicketsTab(),
                  _buildEventsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── HEADER ───────────────────────────────────────────────────────────────────

  Widget _buildProfileHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          _buildAvatarWithLock(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _user.userName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_isSelf) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Bạn',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.deepPurple.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  _user.email,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _roleBadge(_user.role),
                    const SizedBox(width: 6),
                    _lockBadge(_user.isLocked),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              // Toggle lock
              if (!_isSelf)
                _isTogglingLock
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        onPressed: _showLockDialog,
                        icon: Icon(
                          _user.isLocked ? Icons.lock_open : Icons.lock,
                          color: _user.isLocked ? Colors.green : Colors.orange,
                        ),
                        tooltip: _user.isLocked ? 'Mở khóa' : 'Khóa',
                      ),
              // Edit role
              _isUpdatingRole
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      onPressed: _showEditRoleDialog,
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: Colors.deepPurple,
                      ),
                      tooltip: 'Đổi vai trò',
                    ),
              // Delete
              if (!_isSelf)
                _isDeleting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        onPressed: _showDeleteDialog,
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.red.shade400,
                        ),
                        tooltip: 'Xóa tài khoản',
                      ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarWithLock() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.deepPurple.shade100,
          child: Text(
            _user.userName.isNotEmpty ? _user.userName[0].toUpperCase() : 'U',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ),
        if (_user.isLocked)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lock, size: 12, color: Colors.red.shade600),
            ),
          ),
      ],
    );
  }

  Widget _roleBadge(String role) {
    final isOrg = role.toLowerCase() == 'organizer';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isOrg ? Colors.orange.shade100 : Colors.blue.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        role,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isOrg ? Colors.orange.shade700 : Colors.blue.shade700,
        ),
      ),
    );
  }

  Widget _lockBadge(bool locked) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: locked ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        locked ? 'Đã khóa' : 'Hoạt động',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: locked ? Colors.red.shade600 : Colors.green.shade600,
        ),
      ),
    );
  }

  // ─── PROFILE TAB ──────────────────────────────────────────────────────────────

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _infoCard('Thông tin cơ bản', [
            _infoRow('Tên đăng nhập', _user.userName, Icons.person_outline),
            _divider(),
            _infoRow('Email', _user.email, Icons.email_outlined),
            _divider(),
            _infoRow('Vai trò', _user.role, Icons.badge_outlined),
            _divider(),
            _infoRow(
              'Trạng thái',
              _user.isLocked ? 'Đã khóa' : 'Hoạt động',
              _user.isLocked ? Icons.lock : Icons.check_circle_outline,
            ),
          ]),
          const SizedBox(height: 16),
          _infoCard('Thời gian hoạt động', [
            _infoRow(
              'Ngày đăng ký',
              _fmtFull(_user.createdDate),
              Icons.calendar_today,
            ),
            _divider(),
            _infoRow(
              'Lần đăng nhập cuối',
              _user.lastLoginDate != null
                  ? _fmtFull(_user.lastLoginDate!)
                  : 'Chưa đăng nhập',
              Icons.access_time,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _infoCard(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.deepPurple,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 10),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Divider _divider() =>
      Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey[100]);

  // ─── TICKETS TAB ──────────────────────────────────────────────────────────────

  Widget _buildTicketsTab() {
    if (_isLoadingTickets) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_ticketsError != null) {
      return _tabErrorState(_ticketsError!, _fetchTickets);
    }
    if (_tickets.isEmpty) {
      return _emptyState(
        Icons.confirmation_number_outlined,
        'Chưa có lịch sử đăng ký sự kiện',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tickets.length,
      itemBuilder: (_, i) => _ticketCard(_tickets[i]),
    );
  }

  Widget _ticketCard(dynamic t) {
    final status = (t['status'] as String?) ?? 'Đã đăng ký';
    final isConfirmed =
        status.toLowerCase().contains('confirm') ||
        status.toLowerCase().contains('mua') ||
        status.toLowerCase().contains('paid') ||
        status.toLowerCase().contains('approved');
    // Hỗ trợ nhiều tên field khác nhau tuỳ backend
    final title =
        (t['eventTitle'] as String?) ??
        (t['eventName'] as String?) ??
        'Sự kiện không tên';
    final regId = t['registrationId'] ?? t['ticketId'] ?? t['id'];
    final dateRaw =
        t['registrationDate'] ?? t['purchaseDate'] ?? t['createdAt'];
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Mã đăng ký: ${regId ?? 'N/A'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isConfirmed
                        ? Colors.green.shade50
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isConfirmed
                          ? Colors.green.shade300
                          : Colors.orange.shade300,
                    ),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isConfirmed
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
            if (dateRaw != null) ...[
              const SizedBox(height: 4),
              Text(
                'Ngày đăng ký: ${_tryFmtDateStr(dateRaw.toString())}',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── EVENTS TAB ───────────────────────────────────────────────────────────────

  Widget _buildEventsTab() {
    if (_isLoadingEvents) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_eventsError != null) {
      return _tabErrorState(_eventsError!, _fetchEvents);
    }
    if (_events.isEmpty) {
      return _emptyState(Icons.event_outlined, 'Chưa tham gia sự kiện nào');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _events.length,
      itemBuilder: (_, i) => _eventCard(_events[i]),
    );
  }

  Widget _eventCard(dynamic e) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              (e['title'] as String?) ?? 'Sự kiện không tên',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            if (e['date'] != null)
              _eventMeta(
                Icons.calendar_today,
                _tryFmtDateStr(e['date'].toString()),
              ),
            if (e['location'] != null)
              _eventMeta(Icons.location_on_outlined, e['location'].toString()),
          ],
        ),
      ),
    );
  }

  Widget _eventMeta(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 13, color: Colors.grey[500]),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────────

  Widget _tabErrorState(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(
              message,
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

  Widget _emptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 15, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  String _fmtFull(DateTime d) {
    final months = [
      'Thg 1',
      'Thg 2',
      'Thg 3',
      'Thg 4',
      'Thg 5',
      'Thg 6',
      'Thg 7',
      'Thg 8',
      'Thg 9',
      'Thg 10',
      'Thg 11',
      'Thg 12',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _tryFmtDateStr(String raw) {
    try {
      return _fmtFull(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }
}
