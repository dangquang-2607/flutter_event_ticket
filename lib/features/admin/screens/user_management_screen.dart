import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../data/services/admin_service.dart';
import '../../../data/models/user_model.dart';
import '../../../data/api/api_client.dart';
import 'user_detail_screen.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  final _box = GetStorage();
  List<UserModel> _allUsers = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  final Set<int> _processingIds = {};
  String _statusFilter = 'all'; // 'all' | 'active' | 'locked'
  int _currentPage = 1;
  static const int _pageSize = 10;
  late String _currentUserName;

  List<String> get _tabLabels {
    if (_isLoading || _allUsers.isEmpty) {
      return ['Tất cả', 'Người dùng', 'Organizer'];
    }
    final userCount = _allUsers
        .where((u) => u.role.toLowerCase() == 'user')
        .length;
    final orgCount = _allUsers
        .where((u) => u.role.toLowerCase() == 'organizer')
        .length;
    return [
      'Tất cả (${_allUsers.length})',
      'Người dùng ($userCount)',
      'Organizer ($orgCount)',
    ];
  }

  @override
  void initState() {
    super.initState();
    _currentUserName = ((_box.read('userName') as String?) ?? '').toLowerCase();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _applyFilter();
    });
    _searchController.addListener(_applyFilter);
    _fetchUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ─── DATA ────────────────────────────────────────────────────────

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final result = await AdminService.getUsers();
      if (!mounted) return;
      setState(() {
        _allUsers = result;
        _isLoading = false;
        _applyFilter();
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể tải danh sách người dùng.';
      });
    }
  }

  void _applyFilter() {
    final q = _searchController.text.toLowerCase().trim();
    final tab = _tabController.index;
    setState(() {
      _currentPage = 1;
      _filteredUsers = _allUsers.where((u) {
        final matchRole =
            tab == 0 ||
            (tab == 1 && u.role.toLowerCase() == 'user') ||
            (tab == 2 && u.role.toLowerCase() == 'organizer');
        final matchStatus =
            _statusFilter == 'all' ||
            (_statusFilter == 'active' && !u.isLocked) ||
            (_statusFilter == 'locked' && u.isLocked);
        final matchSearch =
            q.isEmpty ||
            u.userName.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q);
        return matchRole && matchStatus && matchSearch;
      }).toList();
    });
  }

  bool _isSelf(UserModel u) => u.userName.toLowerCase() == _currentUserName;

  // ─── ACTIONS ─────────────────────────────────────────────────────

  Future<void> _toggleLock(UserModel user) async {
    if (_isSelf(user)) return;
    setState(() => _processingIds.add(user.userId));
    try {
      if (user.isLocked) {
        await AdminService.unlockUser(user.userId);
      } else {
        await AdminService.lockUser(user.userId);
      }
      if (!mounted) return;
      final updated = user.copyWith(isLocked: !user.isLocked);
      setState(() {
        _processingIds.remove(user.userId);
        final i = _allUsers.indexWhere((u) => u.userId == user.userId);
        if (i != -1) _allUsers[i] = updated;
        _applyFilter();
      });
      Get.snackbar(
        'Đã thực hiện',
        updated.isLocked
            ? 'Đã khóa tài khoản ${user.userName}'
            : 'Đã mở khóa tài khoản ${user.userName}',
        backgroundColor: updated.isLocked ? Colors.orange : Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _processingIds.remove(user.userId));
      Get.snackbar('Lỗi', e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _processingIds.remove(user.userId));
      Get.snackbar('Lỗi', 'Không thể thay đổi trạng thái tài khoản.');
    }
  }

  void _showLockDialog(UserModel user) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              user.isLocked ? Icons.lock_open : Icons.lock,
              color: user.isLocked ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            Text(user.isLocked ? 'Mở khóa?' : 'Khóa tài khoản?'),
          ],
        ),
        content: Text(
          user.isLocked
              ? 'Mở khóa cho ${user.userName}? Người dùng sẽ đăng nhập được lại.'
              : 'Khóa ${user.userName}? Người dùng sẽ không thể đăng nhập.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _toggleLock(user);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: user.isLocked ? Colors.green : Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(user.isLocked ? 'Mở khóa' : 'Khóa'),
          ),
        ],
      ),
    );
  }

  void _showCreateUserDialog() {
    final formKey = GlobalKey<FormState>();
    final userNameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    String selectedRole = 'user';
    bool obscure = true;
    bool isCreating = false;

    Get.dialog(
      StatefulBuilder(
        builder: (_, setD) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('➕ Thêm người dùng'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: userNameCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Tên đăng nhập *',
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
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email *',
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
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passwordCtrl,
                    obscureText: obscure,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu *',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () => setD(() => obscure = !obscure),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Vui lòng nhập mật khẩu';
                      }
                      if (v.length < 6) return 'Tối thiểu 6 ký tự';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Vai trò',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'user', child: Text('user')),
                      DropdownMenuItem(
                        value: 'Organizer',
                        child: Text('organizer'),
                      ),
                    ],
                    onChanged: (v) => setD(() => selectedRole = v ?? 'user'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isCreating ? null : () => Get.back(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: isCreating
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setD(() => isCreating = true);
                      try {
                        final newUser = await AdminService.createUser(
                          userName: userNameCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          password: passwordCtrl.text,
                          role: selectedRole,
                        );
                        Get.back();
                        if (!mounted) return;
                        setState(() {
                          _allUsers.insert(0, newUser);
                          _applyFilter();
                        });
                        Get.snackbar(
                          'Thành công',
                          'Đã tạo tài khoản ${newUser.userName}',
                          backgroundColor: Colors.green,
                          colorText: Colors.white,
                          snackPosition: SnackPosition.BOTTOM,
                          margin: const EdgeInsets.all(16),
                        );
                      } on ApiException catch (e) {
                        setD(() => isCreating = false);
                        Get.snackbar('Lỗi', e.message);
                      } catch (_) {
                        setD(() => isCreating = false);
                        Get.snackbar('Lỗi', 'Không thể tạo tài khoản.');
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isCreating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Tạo'),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  void _navigateToDetail(UserModel user) async {
    final result = await Get.to(() => UserDetailScreen(user: user));
    if (!mounted || result == null || result is! Map) return;
    final action = result['action'] as String?;
    if (action == 'deleted') {
      final deletedId = result['userId'] as int?;
      // Xóa khỏi list local ngay lập tức
      setState(() {
        _allUsers.removeWhere((u) => u.userId == deletedId);
        _applyFilter();
      });
      Get.snackbar(
        'Xóa thành công',
        'Tài khoản đã được xóa khỏi hệ thống.',
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.check_circle_outline, color: Colors.white),
      );
      // Đồng bộ lại với server
      _fetchUsers();
    } else if (action == 'updated') {
      final updated = result['user'] as UserModel?;
      if (updated != null) {
        setState(() {
          final i = _allUsers.indexWhere((u) => u.userId == updated.userId);
          if (i != -1) _allUsers[i] = updated;
          _applyFilter();
        });
      }
    }
  }

  // ─── BUILD ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateUserDialog,
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text(
          'Thêm người dùng',
          style: TextStyle(color: Colors.white),
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Quản lý người dùng',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.deepPurple,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.deepPurple,
          tabs: _tabLabels.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return _buildErrorState();
    }
    final visibleCount = (_currentPage * _pageSize).clamp(
      0,
      _filteredUsers.length,
    );
    final visibleUsers = _filteredUsers.take(visibleCount).toList();
    final hasMore = visibleCount < _filteredUsers.length;
    final remaining = _filteredUsers.length - visibleCount;
    return Column(
      children: [
        _buildSearchBar(),
        _buildStatusFilterChips(),
        _buildStatsBar(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchUsers,
            child: _filteredUsers.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    itemCount: visibleUsers.length + (hasMore ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i == visibleUsers.length) {
                        return _buildLoadMoreButton(remaining);
                      }
                      return _buildUserCard(visibleUsers[i]);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          _statusChip('all', 'Tất cả', Icons.people_outline),
          const SizedBox(width: 8),
          _statusChip('active', 'Hoạt động', Icons.check_circle_outline),
          const SizedBox(width: 8),
          _statusChip('locked', 'Đã khóa', Icons.lock_outline),
        ],
      ),
    );
  }

  Widget _statusChip(String value, String label, IconData icon) {
    final isSelected = _statusFilter == value;
    return FilterChip(
      selected: isSelected,
      showCheckmark: false,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
          ),
        ],
      ),
      selectedColor: Colors.deepPurple,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      onSelected: (_) {
        setState(() => _statusFilter = value);
        _applyFilter();
      },
    );
  }

  Widget _buildLoadMoreButton(int remaining) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: OutlinedButton.icon(
        onPressed: () => setState(() => _currentPage++),
        icon: const Icon(Icons.expand_more, size: 18),
        label: Text('Tải thêm ($remaining người dùng còn lại)'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.deepPurple,
          side: BorderSide(color: Colors.deepPurple.shade200),
          minimumSize: const Size(double.infinity, 42),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchUsers,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        const SizedBox(height: 60),
        Center(
          child: Column(
            children: [
              Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                _searchController.text.isNotEmpty
                    ? 'Không tìm thấy người dùng phù hợp.'
                    : 'Không có người dùng nào.',
                style: TextStyle(fontSize: 15, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Tìm theo tên hoặc email…',
          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () => _searchController.clear(),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsBar() {
    final lockedCount = _filteredUsers.where((u) => u.isLocked).length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            '${_filteredUsers.length} người dùng',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          if (lockedCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                '$lockedCount bị khóa',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.red.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    final isProcessing = _processingIds.contains(user.userId);
    final isSelf = _isSelf(user);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildAvatar(user),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.userName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSelf) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
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
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _buildRoleBadge(user.role),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildInfoChip(
                    icon: Icons.calendar_today,
                    label: 'Đăng ký',
                    value: _fmtDate(user.createdDate),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoChip(
                    icon: Icons.access_time,
                    label: 'Lần cuối',
                    value: user.lastLoginDate != null
                        ? _fmtDate(user.lastLoginDate!)
                        : 'Chưa đăng nhập',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _navigateToDetail(user),
                    icon: const Icon(Icons.person_outline, size: 16),
                    label: const Text('Chi tiết'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.deepPurple,
                      side: BorderSide(color: Colors.deepPurple.shade200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (isProcessing || isSelf)
                        ? null
                        : () => _showLockDialog(user),
                    icon: isProcessing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            user.isLocked
                                ? Icons.lock_open_outlined
                                : Icons.lock_outline,
                            size: 16,
                          ),
                    label: Text(user.isLocked ? 'Mở khóa' : 'Khóa'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: user.isLocked
                          ? Colors.green.shade500
                          : Colors.red.shade400,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade200,
                      disabledForegroundColor: Colors.grey.shade400,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(UserModel user) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.deepPurple.shade100,
          child: Text(
            user.userName.isNotEmpty ? user.userName[0].toUpperCase() : 'U',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ),
        if (user.isLocked)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lock, size: 11, color: Colors.red.shade600),
            ),
          ),
      ],
    );
  }

  Widget _buildRoleBadge(String role) {
    final isOrganizer = role.toLowerCase() == 'organizer';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOrganizer ? Colors.orange.shade100 : Colors.blue.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        role,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isOrganizer ? Colors.orange.shade700 : Colors.blue.shade700,
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 11, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
