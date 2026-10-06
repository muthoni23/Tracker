import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../auth/login_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> with WidgetsBindingObserver {
  final _authService = AuthService();

  bool _checkingVerification = false;
  bool? _emailVerified;
  bool _sendingVerification = false;
  bool _sendingReset = false;
  bool _signingOut = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshVerificationStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check verification status when the user returns to the app,
    // e.g. after tapping the verification link in their email client.
    if (state == AppLifecycleState.resumed) {
      _refreshVerificationStatus();
    }
  }

  Future<void> _refreshVerificationStatus() async {
    setState(() => _checkingVerification = true);
    try {
      final verified = await _authService.isEmailVerified();
      if (mounted) setState(() => _emailVerified = verified);
    } catch (_) {
      // Leave status as unknown; the UI will just show a neutral state.
    } finally {
      if (mounted) setState(() => _checkingVerification = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.priorityHigh : null,
      ),
    );
  }

  String _friendlyAuthError(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'network-request-failed':
          return 'Network error. Check your connection and try again.';
        case 'requires-recent-login':
          return 'Please sign in again before making this change.';
        default:
          return e.message ?? 'Something went wrong (${e.code}).';
      }
    }
    return 'Something went wrong. Please try again.';
  }

  Future<void> _editProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    final controller = TextEditingController(text: user?.displayName ?? '');
    bool isSaving = false;
    String? errorText;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> save() async {
              final newName = controller.text.trim();
              if (newName.isEmpty) {
                setDialogState(() => errorText = 'Name cannot be empty.');
                return;
              }
              setDialogState(() {
                isSaving = true;
                errorText = null;
              });
              try {
                await _authService.updateDisplayName(newName);
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                _showSnack('Profile updated.');
              } catch (e) {
                setDialogState(() {
                  isSaving = false;
                  errorText = _friendlyAuthError(e);
                });
              }
            }

            return AlertDialog(
              title: const Text('Edit Profile'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Display name',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(hintText: 'Your name'),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 12),
                    Text(errorText!, style: const TextStyle(color: AppColors.priorityHigh)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : save,
                  child: isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _changePassword() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) {
      _showSnack('No email on this account.', isError: true);
      return;
    }
    setState(() => _sendingReset = true);
    try {
      await _authService.sendPasswordReset(email);
      _showSnack('Password reset email sent to $email.');
    } catch (e) {
      _showSnack(_friendlyAuthError(e), isError: true);
    } finally {
      if (mounted) setState(() => _sendingReset = false);
    }
  }

  Future<void> _sendVerificationEmail() async {
    setState(() => _sendingVerification = true);
    try {
      await _authService.sendEmailVerification();
      _showSnack('Verification email sent. Check your inbox.');
    } catch (e) {
      _showSnack(_friendlyAuthError(e), isError: true);
    } finally {
      if (mounted) setState(() => _sendingVerification = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    try {
      await _authService.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      _showSnack(_friendlyAuthError(e), isError: true);
      if (mounted) setState(() => _signingOut = false);
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently deletes your account. Your existing data will remain associated with this account and cannot be recovered through the app. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.priorityHigh),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await _deleteAccount();
  }

  Future<void> _deleteAccount({String? password}) async {
    try {
      await _authService.deleteAccount(password: password);
      if (!mounted) return;
      _showSnack('Account deleted.');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        await _promptReauthAndDelete();
      } else {
        _showSnack(_friendlyAuthError(e), isError: true);
      }
    } catch (e) {
      _showSnack(_friendlyAuthError(e), isError: true);
    }
  }

  Future<void> _promptReauthAndDelete() async {
    final passwordController = TextEditingController();
    String? errorText;
    bool isDeleting = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> confirmDelete() async {
              if (passwordController.text.isEmpty) {
                setDialogState(() => errorText = 'Enter your password to continue.');
                return;
              }
              setDialogState(() {
                isDeleting = true;
                errorText = null;
              });
              try {
                await _authService.deleteAccount(password: passwordController.text);
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                if (!mounted) return;
                _showSnack('Account deleted.');
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              } catch (e) {
                setDialogState(() {
                  isDeleting = false;
                  errorText = _friendlyAuthError(e);
                });
              }
            }

            return AlertDialog(
              title: const Text('Confirm your password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'For your security, please re-enter your password to delete your account.',
                    style: TextStyle(color: dialogContext.surfaceColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(hintText: 'Password'),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 12),
                    Text(errorText!, style: const TextStyle(color: AppColors.priorityHigh)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.priorityHigh),
                  onPressed: isDeleting ? null : confirmDelete,
                  child: isDeleting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Delete Account'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AuthService.profileVersion,
      builder: (context, _, __) => _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = (user?.displayName?.isNotEmpty ?? false) ? user!.displayName! : 'No name set';
    final email = user?.email ?? '';
    final initial =
        (user?.displayName?.isNotEmpty ?? false) ? user!.displayName![0].toUpperCase() : '?';
    final colors = context.surfaceColors;

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Profile information
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary,
                    child: Text(initial,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(email, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                    onPressed: _editProfile,
                    tooltip: 'Edit Profile',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Password & Security
            const Text('Password & Security',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 10),
            _AccountTile(
              icon: Icons.lock_outline,
              label: 'Change Password',
              subtitle: 'Send a password reset link to your email',
              trailing: _sendingReset
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              onTap: _sendingReset ? null : _changePassword,
            ),
            const SizedBox(height: 20),

            // Email verification
            const Text('Email Verification',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 10),
            _AccountTile(
              icon: _emailVerified == true ? Icons.verified_outlined : Icons.error_outline,
              label: _checkingVerification
                  ? 'Checking status…'
                  : (_emailVerified == true ? 'Email verified' : 'Email not verified'),
              subtitle: _emailVerified == true
                  ? null
                  : (_checkingVerification ? null : 'Verify your email to secure your account'),
              trailing: _emailVerified == true
                  ? const Icon(Icons.check_circle, color: AppColors.priorityLow)
                  : (_sendingVerification
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null),
              onTap: (_emailVerified == true || _checkingVerification)
                  ? null
                  : _sendVerificationEmail,
            ),
            const SizedBox(height: 20),

            // Sign out
            OutlinedButton.icon(
              icon: const Icon(Icons.logout),
              label: _signingOut
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Sign Out'),
              onPressed: _signingOut ? null : _signOut,
            ),
            const SizedBox(height: 28),

            // Danger zone
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.priorityHigh.withOpacity(0.06),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.priorityHigh.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Danger Zone',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: AppColors.priorityHigh, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(
                    'Deleting your account is permanent and cannot be undone.',
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.delete_outline, color: AppColors.priorityHigh),
                    label: const Text('Delete Account', style: TextStyle(color: AppColors.priorityHigh)),
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.priorityHigh)),
                    onPressed: _confirmDeleteAccount,
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

class _AccountTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _AccountTile({
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}
