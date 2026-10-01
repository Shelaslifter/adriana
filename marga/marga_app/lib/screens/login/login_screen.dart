import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:marga_app/admin/admin_screen.dart';
import 'package:marga_app/screens/adulto/adulto_mayor_screen.dart';
import 'dart:convert';

import 'package:marga_app/screens/familiar/familiar_home_screen.dart';
import 'package:marga_app/screens/registro/registro_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // Instancia de almacenamiento seguro para resolver H05
  final _secureStorage = const FlutterSecureStorage();

  bool _isLoading = false;
  bool _obscurePassword = true;

  final String _loginUrl = "http://192.168.1.155/derek_solutions_api/login.php";

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isLoading = true; });

    try {
      final response = await http.post(
        Uri.parse(_loginUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": _emailController.text.trim(),
          "password": _passwordController.text
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          String rol = data['rol'];
          String? token = data['token'];

          // 1. Guardar el token JWT de forma segura en el dispositivo
          if (token != null && token.isNotEmpty) {
            await _secureStorage.write(key: 'jwt_token', value: token);
            await _secureStorage.write(key: 'user_id', value: data['id'].toString());
            await _secureStorage.write(key: 'user_role', value: rol);
          }

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("¡Bienvenido, ${data['nombre']}!")),
          );

          // 2. Redirección por roles
          if (rol == 'familiar') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => FamiliarHomeScreen(
                  familiarId: int.parse(data['id'].toString()),
                  nombreFamiliar: data['nombre'],
                ),
              ),
            );
          } else if (rol == 'administrador') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminScreen(),
              ),
            );
          }
        } else {
          _showErrorSnackbar(data['message'] ?? "Credenciales incorrectas");
        }
      } else {
        _showErrorSnackbar("Error en el servidor (${response.statusCode})");
      }
    } catch (e) {
      _showErrorSnackbar("Error de red: No se pudo conectar al servidor");
      debugPrint("Error detallado en login: $e");
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  static const Color _primary = Color(0xFF1D4ED8); // blue-700

  InputDecoration _decoracionCampo({required String label, required IconData icono, Widget? sufijo}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icono, color: Colors.grey.shade500),
      suffixIcon: sufijo,
      filled: true,
      fillColor: const Color(0xFFF3F4F8),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: _primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.medical_services_rounded, size: 48, color: _primary),
                ),
                const SizedBox(height: 18),
                const Text(
                  "Derek Solutions",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                ),
                const SizedBox(height: 4),
                Text(
                  "Gestión y Monitoreo de Adherencia Médica",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13.5, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 32),

                // --- Tarjeta con el formulario de acceso ---
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _decoracionCampo(label: "Correo Electrónico", icono: Icons.email_outlined),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Por favor ingresa tu correo";
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return "Ingresa un correo electrónico válido";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: _decoracionCampo(
                            label: "Contraseña",
                            icono: Icons.lock_outline,
                            sufijo: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: Colors.grey.shade500,
                              ),
                              onPressed: () {
                                setState(() { _obscurePassword = !_obscurePassword; });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Por favor ingresa tu contraseña";
                            }
                            if (value.length < 6) {
                              return "La contraseña debe tener al menos 6 caracteres";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 22),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Text("Iniciar Sesión", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const RegistroScreen()),
                              );
                            },
                            child: Text(
                              "¿No tienes una cuenta de Cuidador? Regístrate",
                              style: TextStyle(color: _primary, fontSize: 13.5, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text("¿Eres Adulto Mayor?", style: TextStyle(color: Colors.grey.shade500, fontSize: 12.5)),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ],
                ),
                const SizedBox(height: 18),

                // Botón Adulto Mayor
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AdultoMayorScreen()),
                    );
                  },
                  icon: const Icon(Icons.pin_rounded, size: 24, color: Color(0xFF16A34A)),
                  label: const Text(
                    "Ingresar con Código de Cuidador",
                    style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF86EFAC), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}