import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marga_app/config/api_config.dart';

class AdultoMayorScreen extends StatefulWidget {
  const AdultoMayorScreen({Key? key}) : super(key: key);

  @override
  _AdultoMayorScreenState createState() => _AdultoMayorScreenState();
}

class _AdultoMayorScreenState extends State<AdultoMayorScreen> {
  final TextEditingController _codigoController = TextEditingController();

  bool _estaVinculado = false;
  int? _adultoMayorId;
  String _nombreAdulto = "";

  bool _isLoading = false;
  List<dynamic> _misMedicamentos = [];

  static const Color _primary = Color(0xFF1D4ED8); // blue-700
  static const Color _primaryDark = Color(0xFF1E3A8A); // blue-900

  final String _baseUri = ApiConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarSesionLocal();
    });
  }

  // Comprueba si el dispositivo ya se encuentra vinculado en el almacenamiento local
  Future<void> _verificarSesionLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? idGuardado = prefs.getInt('adulto_mayor_id');
      final String? nombreGuardado = prefs.getString('adulto_mayor_nombre');

      if (idGuardado != null && nombreGuardado != null) {
        setState(() {
          _adultoMayorId = idGuardado;
          _nombreAdulto = nombreGuardado;
          _estaVinculado = true;
        });
        _obtenerMisMedicamentos();
      }
    } catch (e) {
      debugPrint("Aviso: SharedPreferences no inicializado aún: $e");
    }
  }

  // Guarda las llaves de sesión localmente en formato persistente
  Future<void> _guardarSesionLocal(int id, String nombre) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('adulto_mayor_id', id);
      await prefs.setString('adulto_mayor_nombre', nombre);
    } catch (e) {
      debugPrint("Error al escribir en disco local: $e");
    }
  }

  // Envía el código de 6 dígitos introducido por el Adulto Mayor a la API PHP
  Future<void> _vincularDispositivo() async {
    if (_codigoController.text.trim().length != 6) {
      _msg("El código debe tener 6 dígitos", Colors.orange);
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final url = Uri.parse("${_baseUri}vincular_codigo.php");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"codigo_vinculacion": _codigoController.text.trim()}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final int idObtenido = int.parse(data['adulto_mayor_id'].toString());
        final String nombreObtenido = data['nombre'].toString();

        await _guardarSesionLocal(idObtenido, nombreObtenido);

        setState(() {
          _adultoMayorId = idObtenido;
          _nombreAdulto = nombreObtenido;
          _estaVinculado = true;
          _isLoading = false;
        });

        _msg("¡Enlace Exitoso!", Colors.green);

        await Future.delayed(const Duration(milliseconds: 300));
        _obtenerMisMedicamentos();
      } else {
        setState(() { _isLoading = false; });
        _msg(data['message'] ?? "Código inválido", Colors.red);
      }
    } catch (e) {
      setState(() { _isLoading = false; });
      _msg("Error de conexión al servidor", Colors.red);
    }
  }

  // Obtiene los medicamentos correspondientes asignados por el Familiar
  Future<void> _obtenerMisMedicamentos() async {
    if (_adultoMayorId == null) return;

    setState(() { _isLoading = true; });

    final String urlFinal = "${_baseUri}obtener_medicamentos_adulto.php?adulto_mayor_id=$_adultoMayorId";

    try {
      final response = await http.get(Uri.parse(urlFinal));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() { _misMedicamentos = data['medicamentos']; });
        }
      }
    } catch (e) {
      debugPrint("Error obteniendo la lista médica: $e");
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  // Limpia el almacenamiento local para reiniciar la aplicación
  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Cerrar sesión"),
        content: const Text("¿Deseas desvincular este dispositivo?"),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Cancelar")),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Salir", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      debugPrint("Error al limpiar preferencias: $e");
    }
    if (!mounted) return;
    setState(() {
      _estaVinculado = false;
      _adultoMayorId = null;
      _misMedicamentos = [];
      _codigoController.clear();
    });
  }

  void _msg(String texto, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto, style: const TextStyle(fontSize: 16)),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      appBar: AppBar(
        title: Text(_estaVinculado ? "Hola, $_nombreAdulto" : "Configuración Inicial"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: _primaryDark,
        foregroundColor: Colors.white,
        actions: _estaVinculado
            ? [
                IconButton(
                  icon: const Icon(Icons.sync_rounded),
                  tooltip: "Actualizar",
                  onPressed: _isLoading ? null : _obtenerMisMedicamentos,
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded),
                  tooltip: "Cerrar sesión",
                  onPressed: _cerrarSesion,
                ),
                const SizedBox(width: 4),
              ]
            : null,
      ),
      body: _estaVinculado ? _buildListaMedicamentos() : _buildFormularioCodigo(),
    );
  }

  Widget _buildFormularioCodigo() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(color: _primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.lock_person_rounded, size: 52, color: _primary),
                          ),
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          "¡Bienvenido a tu Recordatorio!",
                          style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Ingresa el código de 6 números que generó tu familiar en su aplicación para enlazar tu teléfono.",
                          style: TextStyle(fontSize: 15.5, color: Colors.grey.shade600, height: 1.4),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        TextField(
                          controller: _codigoController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 6),
                          decoration: InputDecoration(
                            counterText: "",
                            hintText: "000000",
                            filled: true,
                            fillColor: const Color(0xFFF3F4F8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 22),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _vincularDispositivo,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Text("Conectar con mi Familiar", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildListaMedicamentos() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _primary));
    }

    if (_misMedicamentos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded, size: 72, color: Colors.green.shade300),
              const SizedBox(height: 16),
              Text(
                "¡Todo listo! No tienes medicamentos pendientes.",
                style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _misMedicamentos.length,
      itemBuilder: (context, index) {
        final med = _misMedicamentos[index];
        final horario = (med['horario']?.toString() ?? '00:00:00');
        final horarioCorto = horario.length >= 5 ? horario.substring(0, 5) : horario;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 5)),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: _primary.withValues(alpha: 0.1),
                child: const Icon(Icons.alarm_rounded, size: 30, color: _primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      med['nombre'] ?? "Sin nombre",
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Dosis: ${med['dosis'] ?? 'N/A'}",
                      style: TextStyle(fontSize: 15.5, color: Colors.grey.shade600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: _primaryDark, borderRadius: BorderRadius.circular(12)),
                child: Text(
                  horarioCorto,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
