import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/db_helper.dart';
import 'login_page.dart';
import '../theme/theme.dart';
import '../widgets/animated_wrapper.dart';
import '../widgets/custom_input_decoration.dart'; 

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String message = '';

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final emailRegex =
        RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => message = 'Lütfen tüm alanları doldurun');
      return;
    }

    if (!emailRegex.hasMatch(email)) {
      setState(() => message = 'Geçerli bir e-posta girin.');
      return;
    }

    if (password.length < 6) {
      setState(() => message = 'Şifre en az 6 karakter olmalı.');
      return;
    }

    final existingUser = await DBHelper.getUserByEmail(email);
    if (existingUser != null) {
      setState(() => message = 'Bu e-posta zaten kayıtlı.');
      return;
    }

    await DBHelper.addUser(name, email, password);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userEmail', email);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: AnimatedWrapper(
            child: Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Kayıt Ol',
                      style: TextStyle(
                        color: Color.fromARGB(255, 133, 175, 25),
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(_nameController, 'Ad Soyad', Icons.person),
                    const SizedBox(height: 16),
                    _buildTextField(_emailController, 'Email', Icons.email),
                    const SizedBox(height: 16),
                    _buildTextField(_passwordController, 'Şifre', Icons.lock,
                        isPassword: true),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Kayıt Ol',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      ),
                      child: const Text('Zaten bir hesabın var mı? Giriş Yap'),
                    ),
                    if (message.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(message, style: const TextStyle(color: Colors.red)),
                    ]
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      style: const TextStyle(color: Colors.black),
      decoration: CustomInputDecoration.input(
          label: label, icon: icon), // ✅ Burada kullanıldı
    );
  }
}
