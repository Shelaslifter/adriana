import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:marga_app/auth_services/auth_service.dart';
import 'package:marga_app/config/api_config.dart';
import 'package:marga_app/screens/login/login_screen.dart';
import 'package:marga_app/screens/medicamento/agregar_medicamento_screen.dart';
import 'package:marga_app/screens/codigo/generar_codigo_screen.dart';

class FamiliarHomeScreen extends StatefulWidget {
  final int familiarId;
  final String nombreFamiliar;

  const FamiliarHomeScreen({
    Key? key,
    required this.familiarId,
    required this.nombreFamiliar,
  }) : super(key: key);

  @override
  _FamiliarHomeScreenState createState() => _FamiliarHomeScreenState();
}

class _FamiliarHomeScreenState extends State<FamiliarHomeScreen> {
  bool _isLoading = true;
  List<dynamic> _medicamentosAsignados = [];

  static const Color _primary = Color(0xFF1D4ED8); // blue-700
  static const Color _primaryDark = Color(0xFF1E3A8A); // blue-900

  final String _baseUri = ApiConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    _obtenerMedicamentosGlobales();
  }

  // Obtiene los medicamentos de TODOS los adultos mayores vinculados a este familiar
  Future<void> _obtenerMedicamentosGlobales() async {
    setState(() { _isLoading = true; });
    try {
      final token = await AuthService.obtenerToken();
      if (token == null) {
        setState(() { _isLoading = false; });
        return;
      }

      final response = await http.get(
        Uri.parse("${_baseUri}obtener_medicamentos_familiar.php?familiar_id=${widget.familiarId}"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _medicamentosAsignados = data['medicamentos'];
          });
        }
      }
    } catch (e) {
      debugPrint("Error de red al obtener medicamentos: $e");
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  // Borra el token y los datos de sesión, y redirige a la pantalla de login
  Future<void> _cerrarSesionFamiliar() async {
    try {
      await AuthService.cerrarSesion(); // Limpia el JWT del almacenamiento seguro
    } catch (e) {
      debugPrint("Error al limpiar datos locales de sesión: $e");
    }

    if (mounted) {
      // Limpia todo el historial de navegación para evitar regresos accidentales
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _confirmarCerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Cerrar Sesión"),
        content: const Text("¿Estás seguro de que deseas salir del perfil familiar?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Salir", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      _cerrarSesionFamiliar();
    }
  }

  Future<void> _editarMedicamento(Map<String, dynamic> med) async {
    final bool? resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AgregarMedicamentoScreen(
          familiarId: widget.familiarId,
          medicamentoExistente: med,
        ),
      ),
    );
    if (resultado == true) {
      _obtenerMedicamentosGlobales();
    }
  }

  Future<void> _eliminarMedicamento(Map<String, dynamic> med) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Eliminar medicamento"),
        content: Text("¿Seguro que deseas eliminar \"${med['nombre']}\"? Esta acción no se puede deshacer."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Eliminar", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    try {
      final token = await AuthService.obtenerToken();
      if (token == null) return;

      final response = await http.post(
        Uri.parse("${_baseUri}eliminar_medicamento.php"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"id": med['id']}),
      );

      final data = jsonDecode(response.body);
      if (!mounted) return;

      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Medicamento eliminado"), backgroundColor: Colors.green),
        );
        _obtenerMedicamentosGlobales();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "No se pudo eliminar"), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error de red al eliminar"), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _abrirDetalle(Map<String, dynamic> med) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _DetalleMedicamentoSheet(
        med: med,
        onEditar: () {
          Navigator.pop(context);
          _editarMedicamento(med);
        },
        onEliminar: () {
          Navigator.pop(context);
          _eliminarMedicamento(med);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 128,
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                "Hola, ${widget.nombreFamiliar}",
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_primaryDark, _primary],
                  ),
                ),
                child: const Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 20, bottom: 40),
                    child: Text(
                      "Panel de Cuidador",
                      style: TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Actualizar Medicamentos',
                onPressed: _isLoading ? null : _obtenerMedicamentosGlobales,
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                tooltip: 'Cerrar Sesión',
                onPressed: _confirmarCerrarSesion,
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.medical_services_rounded,
                      label: "Agregar\nMedicamento",
                      color: const Color(0xFF16A34A),
                      onTap: () async {
                        final bool? resultado = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AgregarMedicamentoScreen(familiarId: widget.familiarId)),
                        );
                        if (resultado == true) {
                          _obtenerMedicamentosGlobales();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.qr_code_scanner_rounded,
                      label: "Vincular\nAdulto Mayor",
                      color: _primary,
                      onTap: () async {
                        final bool? seAgregoNuevo = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => GenerarCodigoScreen(familiarId: widget.familiarId)),
                        );
                        if (seAgregoNuevo == true) {
                          _obtenerMedicamentosGlobales();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Text(
                "Medicamentos asignados actuales",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: _primary)),
            )
          else if (_medicamentosAsignados.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.assignment_late_rounded, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        "No hay medicamentos asignados aún.",
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final med = _medicamentosAsignados[index] as Map<String, dynamic>;
                    return _MedicamentoCard(
                      med: med,
                      onTap: () => _abrirDetalle(med),
                      onEditar: () => _editarMedicamento(med),
                      onEliminar: () => _eliminarMedicamento(med),
                    );
                  },
                  childCount: _medicamentosAsignados.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, height: 1.25, color: Color(0xFF1F2937)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicamentoCard extends StatelessWidget {
  final Map<String, dynamic> med;
  final VoidCallback onTap;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _MedicamentoCard({
    required this.med,
    required this.onTap,
    required this.onEditar,
    required this.onEliminar,
  });

  String get _horarioCorto {
    final h = med['horario']?.toString() ?? "00:00:00";
    final partes = h.split(':');
    return partes.length >= 2 ? "${partes[0]}:${partes[1]}" : h;
  }

  @override
  Widget build(BuildContext context) {
    final nombreAdulto = (med['nombre_adulto'] ?? med['paciente'])?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF1D4ED8).withValues(alpha: 0.1),
                  child: const Icon(Icons.vaccines_rounded, color: Color(0xFF1D4ED8)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        med['nombre']?.toString() ?? "Sin nombre",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5, color: Color(0xFF1F2937)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Dosis: ${med['dosis'] ?? 'N/A'}",
                        style: TextStyle(fontSize: 13.5, color: Colors.grey.shade700),
                      ),
                      if (nombreAdulto != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.elderly_rounded, size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                nombreAdulto,
                                style: TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic, color: Colors.grey.shade600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A8A),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _horarioCorto,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      color: Colors.grey.shade500,
                      visualDensity: VisualDensity.compact,
                      tooltip: "Editar",
                      onPressed: onEditar,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      color: Colors.redAccent,
                      visualDensity: VisualDensity.compact,
                      tooltip: "Eliminar",
                      onPressed: onEliminar,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetalleMedicamentoSheet extends StatelessWidget {
  final Map<String, dynamic> med;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _DetalleMedicamentoSheet({
    required this.med,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final nota = med['nota']?.toString();
    final tieneNota = nota != null && nota.trim().isNotEmpty;
    final recurrencia = int.tryParse(med['recurrencia_horas']?.toString() ?? '0') ?? 0;
    final nombreAdulto = (med['nombre_adulto'] ?? med['paciente'])?.toString();

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
              ),
            ),
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF1D4ED8).withValues(alpha: 0.1),
                  child: const Icon(Icons.vaccines_rounded, color: Color(0xFF1D4ED8)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        med['nombre']?.toString() ?? "Sin nombre",
                        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                      ),
                      if (nombreAdulto != null)
                        Text(
                          "Para $nombreAdulto",
                          style: TextStyle(fontSize: 13.5, color: Colors.grey.shade600),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _DetalleFila(icono: Icons.shutter_speed_rounded, etiqueta: "Dosis", valor: med['dosis']?.toString() ?? 'N/A'),
            const SizedBox(height: 14),
            _DetalleFila(
              icono: Icons.access_time_rounded,
              etiqueta: "Hora de toma",
              valor: (med['horario']?.toString() ?? '00:00:00').substring(0, 5),
            ),
            const SizedBox(height: 14),
            _DetalleFila(
              icono: Icons.repeat_rounded,
              etiqueta: "Frecuencia",
              valor: recurrencia == 0 ? "Toma única (no se repite)" : "Cada $recurrencia horas",
            ),
            if (tieneNota) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.sticky_note_2_rounded, size: 16, color: Colors.amber.shade800),
                        const SizedBox(width: 6),
                        Text(
                          "Nota",
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.amber.shade800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(nota, style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937), height: 1.4)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEditar,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text("Editar"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: const Color(0xFF1D4ED8),
                      side: const BorderSide(color: Color(0xFF1D4ED8)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEliminar,
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text("Eliminar"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetalleFila extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String valor;

  const _DetalleFila({required this.icono, required this.etiqueta, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, size: 18, color: Colors.grey.shade500),
        const SizedBox(width: 10),
        Text(etiqueta, style: TextStyle(fontSize: 13.5, color: Colors.grey.shade600)),
        const Spacer(),
        Text(valor, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
      ],
    );
  }
}
