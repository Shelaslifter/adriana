import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:marga_app/auth_services/auth_service.dart';
import 'package:marga_app/screens/login/login_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool isLoading = true;
  List<dynamic> vinculaciones = [];

  final String baseUri = "http://192.168.1.155/derek_solutions_api/";

  static const Color _primary = Color(0xFF4338CA); // indigo-700
  static const Color _primaryDark = Color(0xFF312E81); // indigo-900

  @override
  void initState() {
    super.initState();
    obtenerVinculaciones();
  }

  Future<void> obtenerVinculaciones() async {
    try {
      setState(() {
        isLoading = true;
      });

      final token = await AuthService.obtenerToken();
      if (token == null) {
        throw Exception("Sesión expirada");
      }

      final response = await http.get(
        Uri.parse("${baseUri}obtener_vinculaciones_admin.php"),
        headers: {"Authorization": "Bearer $token"},
      );

      final data = jsonDecode(response.body);

      if (data["success"] == true) {
        setState(() {
          vinculaciones = data["vinculaciones"];
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al obtener vinculaciones")),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Cerrar sesión"),
        content: const Text("¿Estás seguro de que deseas salir del panel de administrador?"),
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

    if (confirmar != true) return;

    await AuthService.cerrarSesion();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  int get totalActivos => vinculaciones.where((v) => v["estado"] == "activo").length;

  int get totalPendientes => vinculaciones.where((v) => v["estado"] == "pendiente").length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: const Text(
                "Panel de Administrador",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_primaryDark, _primary],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: isLoading ? null : obtenerVinculaciones,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: "Actualizar",
              ),
              IconButton(
                onPressed: _cerrarSesion,
                icon: const Icon(Icons.logout_rounded),
                tooltip: "Cerrar sesión",
              ),
              const SizedBox(width: 8),
            ],
          ),
          if (isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: _primary)),
            )
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Row(
                  children: [
                    _StatCard(
                      icon: Icons.link_rounded,
                      color: _primary,
                      value: vinculaciones.length,
                      label: "Vinculaciones",
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      icon: Icons.check_circle_rounded,
                      color: const Color(0xFF16A34A),
                      value: totalActivos,
                      label: "Activas",
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      icon: Icons.schedule_rounded,
                      color: const Color(0xFFEA580C),
                      value: totalPendientes,
                      label: "Pendientes",
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Text(
                  "Vinculaciones familiar – adulto mayor",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
            if (vinculaciones.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          "No existen vinculaciones todavía",
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
                    (context, index) => _VinculacionCard(item: vinculaciones[index]),
                    childCount: vinculaciones.length,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              "$value",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _VinculacionCard extends StatelessWidget {
  final dynamic item;

  const _VinculacionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final estado = item["estado"].toString();
    final esActivo = estado == "activo";
    final statusColor = esActivo ? const Color(0xFF16A34A) : const Color(0xFFEA580C);
    final familiarNombre = item["familiar_nombre"].toString();
    final inicial = familiarNombre.isNotEmpty ? familiarNombre[0].toUpperCase() : "?";

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF4338CA).withValues(alpha: 0.1),
            child: Text(
              inicial,
              style: const TextStyle(color: Color(0xFF4338CA), fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  familiarNombre,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5, color: Color(0xFF1F2937)),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.elderly_rounded, size: 15, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item["adulto_nombre"].toString(),
                        style: TextStyle(fontSize: 13.5, color: Colors.grey.shade700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.pin_rounded, size: 15, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      item["codigo_vinculacion"].toString(),
                      style: TextStyle(fontSize: 13.5, color: Colors.grey.shade700, letterSpacing: 1),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  esActivo ? Icons.check_circle_rounded : Icons.schedule_rounded,
                  size: 13,
                  color: statusColor,
                ),
                const SizedBox(width: 4),
                Text(
                  esActivo ? "Activa" : "Pendiente",
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: statusColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
