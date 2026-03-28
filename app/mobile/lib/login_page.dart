// lib/login_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscure = true;
  bool _loading = false;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Widget _eyeToggle() {
    return IconButton(
      icon: Icon(
        _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: Colors.grey,
      ),
      onPressed: () => setState(() => _obscure = !_obscure),
    );
  }

  // ===== Đăng nhập / Đăng ký Firebase =====
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (_isLogin) {
        // === Đăng nhập ===
        final userCred = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        final user = userCred.user;
        if (user == null) throw Exception("Login failed");

        final token = (await user.getIdToken()) ?? '';
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('uid', user.uid);
        await prefs.setString('email', email);
        await prefs.setString('token', token);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        // === Đăng ký ===
        final userCred = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        final user = userCred.user;
        if (user == null) throw Exception("Registration failed");

        final uid = user.uid;

        await _firestore.collection('users').doc(uid).set({
          'uid': uid,
          'full name': _nameController.text.trim(),
          'email': email,
          'password': password, // ⚠️ chỉ để test, KHÔNG nên lưu mật khẩu thật
          'createdAt': FieldValue.serverTimestamp(),
        });

        final token = (await user.getIdToken()) ?? '';
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('uid', uid);
        await prefs.setString('email', email);
        await prefs.setString('token', token);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Registration successful! Please log in.'),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 600));
        setState(() => _isLogin = true);
      }
    } on FirebaseAuthException catch (e) {
      String msg = e.message ?? e.code;
      switch (e.code) {
        case 'user-not-found':
          msg = '⚠️ Email chưa được đăng ký.';
          break;
        case 'wrong-password':
          msg = '❌ Sai mật khẩu.';
          break;
        case 'email-already-in-use':
          msg = '⚠️ Email này đã tồn tại.';
          break;
        case 'invalid-email':
          msg = '📧 Email không hợp lệ.';
          break;
        case 'weak-password':
          msg = '🔒 Mật khẩu phải có ít nhất 6 ký tự.';
          break;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('🔥 Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ===== Đổi mật khẩu (không gửi email) =====
  Future<void> _resetPassword(String email, String newPassword) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Email này chưa được đăng ký!')),
        );
        return;
      }

      final userData = snapshot.docs.first.data();
      final uid = userData['uid'];

      await _firestore.collection('users').doc(uid).update({
        'password': newPassword,
      });

      try {
        final user = _auth.currentUser;
        if (user != null && user.email == email) {
          await user.updatePassword(newPassword);
        }
      } catch (e) {
        debugPrint("⚠️ Không thể cập nhật mật khẩu Firebase: $e");
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Mật khẩu đã được cập nhật thành công!'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('🔥 Lỗi: $e')));
    }
  }

  // ===== Hộp thoại Forgot Password (Email + Mật khẩu mới) =====
  void _showForgotPasswordDialog() {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    bool submitting = false;
    bool obscure = true;

    showDialog(
      context: context,
      barrierDismissible: !submitting,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            Future<void> submit() async {
              final email = emailCtrl.text.trim();
              final newPass = passCtrl.text.trim();

              if (email.isEmpty || newPass.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('⚠️ Vui lòng nhập đủ thông tin!'),
                  ),
                );
                return;
              }

              setLocal(() => submitting = true);
              await _resetPassword(email, newPass);
              setLocal(() => submitting = false);
            }

            return Dialog(
              insetPadding: const EdgeInsets.all(24),
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.refresh_rounded,
                      size: 42,
                      color: Color(0xFF2F80ED),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Reset Password',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter your email and new password.',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Email address',
                        prefixIcon: Icon(Icons.email_outlined),
                        filled: true,
                        fillColor: Color(0xFFF4F7FB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: passCtrl,
                      obscureText: obscure,
                      decoration: InputDecoration(
                        hintText: 'New password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.grey,
                          ),
                          onPressed: () => setLocal(() => obscure = !obscure),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF4F7FB),
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: submitting
                              ? null
                              : () => Navigator.pop(context),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: submitting ? null : submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2F80ED),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Confirm',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4A90E2), Color(0xFF74B3F3), Color(0xFFD3E7FF)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: 390,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.96),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF3FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.school,
                      size: 42,
                      color: Color(0xFF2F80ED),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _isLogin ? 'Login' : 'Create a new account',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E2E50),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isLogin
                        ? 'Sign in to continue your learning journey.'
                        : 'Start your journey to master new knowledge.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 26),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        if (!_isLogin)
                          Column(
                            children: [
                              TextFormField(
                                controller: _nameController,
                                decoration: _inputDecoration(
                                  hint: 'Full name',
                                  icon: Icons.badge_outlined,
                                ),
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Enter your full name'
                                    : null,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _emailController,
                                decoration: _inputDecoration(
                                  hint: 'Email address',
                                  icon: Icons.email_outlined,
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Enter your email';
                                  }
                                  if (!RegExp(
                                    r'^[\w\.-]+@[\w\.-]+\.\w+$',
                                  ).hasMatch(v)) {
                                    return 'Enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                            ],
                          ),
                        if (_isLogin)
                          TextFormField(
                            controller: _emailController,
                            decoration: _inputDecoration(
                              hint: 'Email address',
                              icon: Icons.email_outlined,
                            ),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Enter your email'
                                : null,
                          ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscure,
                          decoration: _inputDecoration(
                            hint: 'Password',
                            icon: Icons.lock_outline,
                            suffix: _eyeToggle(),
                          ),
                          validator: (v) => v == null || v.length < 6
                              ? 'At least 6 characters'
                              : null,
                        ),
                      ],
                    ),
                  ),
                  if (_isLogin)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showForgotPasswordDialog,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF2F80ED),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text('Forgot password?'),
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2F80ED),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            )
                          : Text(
                              _isLogin ? 'Login' : 'Register',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isLogin
                            ? 'Don’t have an account? '
                            : 'Already have an account? ',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _isLogin = !_isLogin),
                        child: Text(
                          _isLogin ? 'Sign up' : 'Sign in',
                          style: const TextStyle(
                            color: Color(0xFF2F80ED),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.grey),
      suffixIcon: suffix,
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF4F7FB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    );
  }
}
