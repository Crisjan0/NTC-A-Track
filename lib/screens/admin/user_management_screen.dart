import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../utils/formatters.dart';
import '../../services/database_service.dart';
import '../../services/session_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/gradient_header.dart';
import 'user_form_dialog.dart';

/// Admin screen for managing admin user accounts: list, search, add, edit
/// username/role, reset password, and delete (with a guard against deleting
/// your own account).
class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final DatabaseService _db = DatabaseService.instance;
  final _searchController = TextEditingController();

  List<User> _users = [];
  bool _loading = true;
  String? _search;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final users = await _db.getAllUsers();
    final filtered = _search == null || _search!.isEmpty
        ? users
        : users
            .where((u) =>
                u.username.contains(_search!) ||
                u.role.contains(_search!))
            .toList();
    if (!mounted) return;
    setState(() {
      _users = filtered;
      _loading = false;
    });
  }

  Future<void> _openAdd() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const UserFormDialog()),
    );
    if (created == true) _load();
  }

  Future<void> _openEdit(User user) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => UserFormDialog(user: user)),
    );
    if (changed == true) _load();
  }

  Future<void> _confirmDelete(User user) async {
    final session = SessionService.instance.current;
    final message = session?.username == user.username
        ? 'You cannot delete your own admin account. Change your password '
            'or username instead.'
        : 'This will permanently remove ${user.username} from the system. '
            'This cannot be undone.';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Admin Account?'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 44),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await _db.deleteUser(
      user.id!,
      currentUserId: session?.username == user.username ? user.id : null,
    );
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete your own account')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${user.username} deleted successfully')),
    );
    _load();
  }

  Future<void> _resetPassword(User user) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: Text(
          'Enter a new password for ${user.username}. This replaces the '
              'current password immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 44),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (result != true) return;

    final controller = TextEditingController();
    final confirm = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                hintText: 'At least 6 characters',
              ),
              maxLength: 64,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirm,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
              ),
              maxLength: 64,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 44),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final password = controller.text.trim();
    if (password.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password cannot be empty')),
      );
      return;
    }
    if (password != confirm.text.trim()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    await _db.updateUserPassword(user.id!, password);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${user.username} password updated')),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: 'Admin Users',
            subtitle: '${_users.length} ${_users.length == 1 ? "account" : "accounts"}',
            icon: Icons.admin_panel_settings_rounded,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _load(),
              decoration: InputDecoration(
                hintText: 'Search by username or role…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _load();
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? const EmptyState(
                        icon: Icons.admin_panel_settings_rounded,
                        title: 'No admin accounts',
                        subtitle:
                            'Add an admin to manage attendance and events',
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(16, 8, 16, 96),
                          itemCount: _users.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final u = _users[index];
                            return _UserCard(
                              user: u,
                              onEdit: () => _openEdit(u),
                              onResetPassword: () => _resetPassword(u),
                              onDelete: () => _confirmDelete(u),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: Transform.translate(
      offset: const Offset(0, -40),
      child: FloatingActionButton.extended(
        onPressed: _openAdd,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text(
          'Add Admin',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final User user;
  final VoidCallback onEdit;
  final VoidCallback onResetPassword;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.onEdit,
    required this.onResetPassword,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.paletteOf(context);
    final isCurrent = SessionService.instance.current?.username == user.username;
    final initials = _initials(user.username);

    return GlassPanel(
      radius: kCardRadius,
      blur: 22,
      strong: true,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Avatar circle with initials.
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _RoleChip(role: user.role),
                    const SizedBox(width: 8),
                    Text(
                      'Created ${Formatters.shortDate(user.createdAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: p.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  onEdit();
                  break;
                case 'password':
                  onResetPassword();
                  break;
                case 'delete':
                  onDelete();
                  break;
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_rounded, size: 20),
                    SizedBox(width: 10),
                    Text('Edit Account'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'password',
                child: Row(
                  children: [
                    Icon(Icons.lock_reset_rounded, size: 20),
                    SizedBox(width: 10),
                    Text('Reset Password'),
                  ],
                ),
              ),
              if (!isCurrent)
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_rounded, size: 20, color: AppColors.danger),
                      SizedBox(width: 10),
                      Text('Delete Account',
                          style: TextStyle(color: AppColors.danger)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _initials(String username) {
    final parts = username.trim().split(RegExp(r'[_\-\. ]+'));
    final letters = parts
        .map((p) => p.isNotEmpty ? p[0] : '')
        .where((c) => c.isNotEmpty)
        .take(2)
        .join()
        .toUpperCase();    return letters.isEmpty ? username.substring(0, 1).toUpperCase() : letters;
  }
}

class _RoleChip extends StatelessWidget {
  final String role;
  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: AppColors.primary,
        ),
      ),
    );
  }
}


