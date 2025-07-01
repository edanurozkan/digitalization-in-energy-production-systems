import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/db_helper.dart';
import '../theme/theme.dart';
import '../widgets/animated_wrapper.dart';
import '../widgets/custom_input_decoration.dart'; 

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('userEmail');
    final imagePath = prefs.getString('profileImage');
    if (email != null) {
      final user = await DBHelper.getUserByEmail(email);
      if (user != null) {
        _nameController.text = user['name'];
        _emailController.text = user['email'];
        _passwordController.text = user['password'];
      }
    }
    if (imagePath != null && File(imagePath).existsSync()) {
      setState(() {
        _imageFile = File(imagePath);
      });
    }
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profileImage', picked.path);
    }
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      final oldEmail = prefs.getString('userEmail');

      if (oldEmail != null) {
        await DBHelper.updateUser(
          oldEmail,
          _nameController.text,
          _emailController.text,
          _passwordController.text,
        );

        await prefs.setString('userEmail', _emailController.text);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bilgiler başarıyla güncellendi')),
        );

        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profili Düzenle')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: AnimatedWrapper(
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundImage: _imageFile != null
                                ? FileImage(_imageFile!)
                                : null,
                            backgroundColor: Colors.grey.shade200,
                            child: _imageFile == null
                                ? const Icon(Icons.person,
                                    size: 48, color: Colors.grey)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary,
                                ),
                                child: const Icon(Icons.edit,
                                    size: 18, color: Colors.white),
                              ),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildTextField(_nameController, "Adınız", Icons.person),
                      const SizedBox(height: 16),
                      _buildTextField(_emailController, "E-posta", Icons.email),
                      const SizedBox(height: 16),
                      _buildTextField(_passwordController, "Şifre", Icons.lock,
                          isPassword: true),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'Kaydet',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary),
                          ),
                        ),
                      ),
                    ],
                  ),
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
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.black),
      decoration: CustomInputDecoration.input(
          label: label, icon: icon), // ✅ Custom input burada kullanıldı
      validator: (value) =>
          value == null || value.isEmpty ? '$label boş olamaz' : null,
    );
  }
}
