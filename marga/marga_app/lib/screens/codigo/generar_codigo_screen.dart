import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:marga_app/auth_services/auth_service.dart';
import 'package:marga_app/config/api_config.dart';

class GenerarCodigoScreen extends StatefulWidget {
  final int familiarId;
  const GenerarCodigoScreen({Key? key, required this.familiarId}) : super(key: key);

  @override
  _GenerarCodigoScreenState createState() => _GenerarCodigoScreenState();
}

class _GenerarCodigoScreenState extends State<GenerarCodigoScreen> {
  final TextEditingController _nombreAdultoController = TextEditingController();
  String _codigoGenerado = "";
  bool _isLoading = false;

  static const Color _primary = Color(0xFF1D4ED8); // blue-700
  static const Color _primaryDark = Color(0xFF1E3A8A); // blue-900

  final String _apiUrl = "${ApiConfig.baseUrl}crear_vinculacion.php";

  Future<void> _generarCodigo() async {
    if (_nombreAdultoController.text.trim().isEmpty) return;
    setState(() { _isLoading = true; });

    try {
      final token = await AuthService.obtenerToken();
      if (token == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sesión expirada. Vuelve a iniciar sesión."), backgroundColor: Colors.red),
        );
        setState(() { _isLoading = false; });
        return;
      }

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"nombre": _nombreAdultoController.text.trim()}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() { _codigoGenerado = data['codigo']; });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message']), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? "Error desconocido"), backgroundColor: Colors.redAccent),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error en el servidor (${response.statusCode})."), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al conectar con el servidor."), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      appBar: AppBar(
        title: const Text("Vincular Adulto Mayor"),
        elevation: 0,
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        // Evitamos que el usuario regrese con la flecha estándar sin avisar de la actualización
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, _codigoGenerado.isNotEmpty),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
              child: _codigoGenerado.isEmpty ? _buildFormulario() : _buildCodigoGenerado(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFormulario() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 14, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _primary.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.person_add_alt_1_rounded, size: 40, color: _primary),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            "Registra el nombre de la persona de la tercera edad para generar su clave de acceso único.",
            style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          TextField(
            controller: _nombreAdultoController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: "Nombre del Adulto Mayor",
              hintText: "Ej: Abuela María",
              filled: true,
              fillColor: const Color(0xFFF3F4F8),
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 22),
          ElevatedButton(
            onPressed: _isLoading ? null : _generarCodigo,
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
                : const Text("Generar Código de Enlace", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildCodigoGenerado() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _primary.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: _primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Proporciona este código en el dispositivo del adulto mayor al abrir su aplicación por primera vez.",
                  style: TextStyle(fontSize: 14, color: Colors.blue.shade900, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 6)),
            ],
          ),
          child: Column(
            children: [
              Text(
                "CÓDIGO DE ENLACE",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
              const SizedBox(height: 14),
              Text(
                _codigoGenerado,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold, letterSpacing: 8, color: Color(0xFF16A34A)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: _primaryDark,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text("Terminar y Salir", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5)),
        ),
      ],
    );
  }
}
