import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:marga_app/auth_services/auth_service.dart';

class AgregarMedicamentoScreen extends StatefulWidget {
  final int familiarId;
  /// Si se provee, la pantalla entra en modo edición y precarga estos datos
  /// (debe incluir al menos: id, nombre, dosis, horario, adulto_mayor_id,
  /// recurrencia_horas, nota).
  final Map<String, dynamic>? medicamentoExistente;

  const AgregarMedicamentoScreen({
    Key? key,
    required this.familiarId,
    this.medicamentoExistente,
  }) : super(key: key);

  @override
  _AgregarMedicamentoScreenState createState() => _AgregarMedicamentoScreenState();
}

class _AgregarMedicamentoScreenState extends State<AgregarMedicamentoScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreMedController = TextEditingController();
  final TextEditingController _dosisController = TextEditingController();
  final TextEditingController _notaController = TextEditingController();

  int? _adultoMayorSeleccionadoId;
  List<dynamic> _listaAdultosVinculados = [];
  bool _isLoadingAdultos = true;
  bool _isSaving = false;

  TimeOfDay _horaSeleccionada = const TimeOfDay(hour: 8, minute: 0);
  int _recurrenciaHoras = 8;

  bool get _esEdicion => widget.medicamentoExistente != null;

  // REEMPLAZA CON TU IP LOCAL DE XAMPP
  final String _baseUri = "http://192.168.1.155/derek_solutions_api/";

  @override
  void initState() {
    super.initState();
    if (_esEdicion) {
      final med = widget.medicamentoExistente!;
      _nombreMedController.text = med['nombre']?.toString() ?? "";
      _dosisController.text = med['dosis']?.toString() ?? "";
      _notaController.text = med['nota']?.toString() ?? "";
      _adultoMayorSeleccionadoId = int.tryParse(med['adulto_mayor_id'].toString());
      _recurrenciaHoras = int.tryParse(med['recurrencia_horas'].toString()) ?? 8;

      final horarioStr = med['horario']?.toString() ?? "08:00:00";
      final partes = horarioStr.split(':');
      if (partes.length >= 2) {
        _horaSeleccionada = TimeOfDay(
          hour: int.tryParse(partes[0]) ?? 8,
          minute: int.tryParse(partes[1]) ?? 0,
        );
      }
    }
    _cargarAdultosVinculados();
  }

  // Carga los abuelitos vinculados activos desde la base de datos
  Future<void> _cargarAdultosVinculados() async {
    setState(() { _isLoadingAdultos = true; });

    try {
      final token = await AuthService.obtenerToken();
      if (token == null) {
        setState(() { _isLoadingAdultos = false; });
        return;
      }

      final response = await http.get(
        Uri.parse("${_baseUri}obtener_vinculados.php?familiar_id=${widget.familiarId}"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _listaAdultosVinculados = data['adultos'];
            _isLoadingAdultos = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint("Error al cargar vinculados: $e");
    }

    setState(() { _isLoadingAdultos = false; });
  }

  Future<void> _seleccionarHora(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _horaSeleccionada,
    );
    if (picked != null) {
      setState(() { _horaSeleccionada = picked; });
    }
  }

  Future<void> _guardarMedicamento() async {
    if (!_formKey.currentState!.validate()) return;
    if (_adultoMayorSeleccionadoId == null) {
      _showSnackbar("Por favor, selecciona a un Adulto Mayor", Colors.orange);
      return;
    }

    setState(() { _isSaving = true; });

    final String horaFormateada = "${_horaSeleccionada.hour.toString().padLeft(2, '0')}:${_horaSeleccionada.minute.toString().padLeft(2, '0')}:00";

    try {
      final Map<String, dynamic> bodyData = {
        "adulto_mayor_id": _adultoMayorSeleccionadoId,
        "nombre": _nombreMedController.text.trim(),
        "dosis": _dosisController.text.trim(),
        "horario": horaFormateada,
        "recurrencia_horas": _recurrenciaHoras,
        "nota": _notaController.text.trim(),
      };

      final endpoint = _esEdicion ? "editar_medicamento.php" : "guardar_medicamento.php";
      if (_esEdicion) {
        bodyData["id"] = widget.medicamentoExistente!['id'];
      }

      final token = await AuthService.obtenerToken();
      if (token == null) {
        _showSnackbar("Sesión expirada. Vuelve a iniciar sesión.", Colors.red);
        setState(() { _isSaving = false; });
        return;
      }

      final response = await http.post(
        Uri.parse("$_baseUri$endpoint"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(bodyData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _showSnackbar(
            _esEdicion ? "¡Medicamento actualizado correctamente!" : "¡Medicamento asignado correctamente!",
            Colors.green,
          );
          Navigator.pop(context, true);
        } else {
          _showSnackbar(data['message'] ?? "Error al guardar", Colors.redAccent);
        }
      } else {
        _showSnackbar("Error en el servidor (${response.statusCode})", Colors.redAccent);
      }
    } catch (e) {
      _showSnackbar("Error de red al intentar guardar", Colors.redAccent);
    } finally {
      if (mounted) {
        setState(() { _isSaving = false; });
      }
    }
  }

  void _showSnackbar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  static const Color _primary = Color(0xFF1D4ED8); // blue-700

  InputDecoration _decoracionCampo({required String label, required IconData icono, String? hint, bool alignTop = false}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      alignLabelWithHint: alignTop,
      prefixIcon: Icon(icono, color: Colors.grey.shade500),
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
      appBar: AppBar(
        title: Text(_esEdicion ? "Editar Medicamento" : "Programar Medicamento"),
        elevation: 0,
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _cargarAdultosVinculados,
            tooltip: "Actualizar lista de abuelitos",
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoadingAdultos
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                padding: const EdgeInsets.all(20),
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
                      // --- SELECTOR DE ADULTO MAYOR ---
                      DropdownButtonFormField<int>(
                        value: _adultoMayorSeleccionadoId,
                        isExpanded: true,
                        decoration: _decoracionCampo(label: "Asignar al Adulto Mayor", icono: Icons.person_search_outlined),
                        hint: const Text("Selecciona un abuelito enlazado", overflow: TextOverflow.ellipsis),
                        items: _listaAdultosVinculados.map<DropdownMenuItem<int>>((dynamic adulto) {
                          return DropdownMenuItem<int>(
                            value: int.parse(adulto['id'].toString()),
                            child: Text(adulto['nombre'].toString(), overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() { _adultoMayorSeleccionadoId = val; });
                        },
                        validator: (value) => value == null ? "Este campo es requerido" : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _nombreMedController,
                        decoration: _decoracionCampo(label: "Nombre del Medicamento", icono: Icons.medication_outlined),
                        validator: (v) => v!.isEmpty ? "Ingresa el nombre del medicamento" : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _dosisController,
                        decoration: _decoracionCampo(label: "Dosis", icono: Icons.shutter_speed_outlined, hint: "Ej: 1 tableta, 5ml"),
                        validator: (v) => v!.isEmpty ? "Ingresa la dosis requerida" : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notaController,
                        maxLines: 3,
                        decoration: _decoracionCampo(
                          label: "Nota (opcional)",
                          icono: Icons.sticky_note_2_outlined,
                          hint: "Ej: Tomar con alimentos, no combinar con...",
                          alignTop: true,
                        ),
                      ),
                      const SizedBox(height: 16),

                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _seleccionarHora(context),
                        child: InputDecorator(
                          decoration: _decoracionCampo(label: "Hora de toma", icono: Icons.access_time_rounded),
                          child: Text(
                            _horaSeleccionada.format(context),
                            style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<int>(
                        value: _recurrenciaHoras,
                        isExpanded: true,
                        decoration: _decoracionCampo(label: "Frecuencia de repetición", icono: Icons.repeat_rounded),
                        items: [0, 4, 6, 8, 12, 24].map((int value) {
                          return DropdownMenuItem<int>(
                            value: value,
                            child: Text(
                              value == 0 ? "Toma única (no se repite)" : "Cada $value horas",
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() { _recurrenciaHoras = val!; }),
                      ),
                      const SizedBox(height: 28),

                      ElevatedButton(
                        onPressed: _isSaving ? null : _guardarMedicamento,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : Text(
                                _esEdicion ? "Guardar Cambios" : "Guardar y Sincronizar",
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}