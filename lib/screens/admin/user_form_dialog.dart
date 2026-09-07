import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../services/database_service_factory.dart';
import '../../services/database_service_interface.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';

/// Dialog for adding a new admin account or editing an existing one.
///
/// When [user] is provided the dialog edits that account (username + role).
/// When omitted it creates a new admin account with a randomly generated
/// password shown to the admin once.
class UserFormDialog extends StatefulWidget {
  final User? user;

  const UserFormDialog({super.key, this.user});

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _generatedPassword;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  bool get _isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _usernameController.text = widget.user!.username;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final db = DatabaseServiceFactory.instance;

    if (_isEditing) {
      await db.updateUser(
        widget.user!,
        newUsername: _usernameController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      return;
    }

    // New admin: use the provided password, or generate one if empty.
    String password;
    if (_passwordController.text.trim().isEmpty) {
      password = _generatePassword();
      setState(() => _generatedPassword = password);
    } else if (_passwordController.text.trim() !=
        _confirmController.text.trim()) {
      return;
    } else {
      password = _passwordController.text.trim();
    }
    final creds = DatabaseServiceInterface.hashPassword(password);
    final newUser = User(
      username: _usernameController.text.trim(),
      passwordHash: creds['hash']!,
      salt: creds['salt']!,
      role: 'admin',
      createdAt: DateTime.now(),
    );
    await db.insertUser(newUser);

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  String _generatePassword() {
    const lower = 'abcdefghijklmnopqrstuvwxyz';
    const upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const digits = '0123456789';
    const all = lower + upper + digits;
    final random = DateTime.now().microsecondsSinceEpoch;
    String r(int i) {
      final idx = (random + i * 7) % all.length;
      return all[idx.toInt()];
    }
    return '${r(0)}${r(1)}${r(2)}${r(3)}${r(4)}${r(5)}${r(6)}${r(7)}';
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _isEditing;
    final p = AppTheme.paletteOf(context);

    return AlertDialog(
      backgroundColor: Colors.transparent,
      contentPadding: EdgeInsets.zero,
      content: Container(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 520),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header band.
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: AppGradients.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isEditing ? Icons.edit_rounded : Icons.person_add_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEditing ? 'Edit Admin Account' : 'Add Admin Account',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isEditing
                                  ? 'Update username or account details'
                                  : 'Create a new administrator account',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                // Username.
                TextFormField(
                  controller: _usernameController,
                  autofocus: !isEditing,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    hintText: 'e.g. jdoe',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  textCapitalization: TextCapitalization.none,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Username is required';
                    }
                    final trimmed = value.trim();
                    if (trimmed.length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(trimmed)) {
                      return 'Only letters, numbers, and underscores';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Password (new accounts) or info (edit).
                if (!isEditing) ...[
                  TextFormField(
                    controller: _passwordController,
                    autofocus: false,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Leave blank to generate one',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(
                              () => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                    maxLength: 64,
                    textCapitalization: TextCapitalization.none,
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty ||
                          _generatedPassword != null) {
                        return null;
                      }
                      if (value.trim().length < 6) {
                        return 'At least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmController,
                    obscureText: _obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon:
                          const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(
                              () => _obscureConfirm = !_obscureConfirm);
                        },
                      ),
                    ),
                    maxLength: 64,
                    textCapitalization: TextCapitalization.none,
                    validator: (value) {
                      if (_generatedPassword != null) {
                        return 'Generated password: $_generatedPassword';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ] else ...[
                  Container(
                    padding:
                        const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Password changes are handled separately '
                                'via Reset Password.',
                            style: TextStyle(
                              fontSize: 13,
                              color: p.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                // Actions.
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          foregroundColor: AppColors.primary,
                          side: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 44),
                        ),
                        child:
                            Text(isEditing ? 'Save Changes' : 'Create Account'),
                      ),
                    ),
                  ],
                ),
                // Generated password footer.
                if (_generatedPassword != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.warningLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.warning,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Generated password: $_generatedPassword\n'
                                'Share this with the admin once. They can '
                                'change it later.',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.warningDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
