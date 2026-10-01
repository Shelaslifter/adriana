<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: GET");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

include_once 'conexion.php';
include_once 'auth_middleware.php';

$usuario = requireAuth(['familiar']);

if (!isset($_GET['familiar_id']) || empty($_GET['familiar_id'])) {
    echo json_encode([
        "success" => false,
        "message" => "Falta el ID del familiar"
    ]);
    exit();
}

// Se ignora cualquier familiar_id enviado por el cliente: siempre se usa el del token verificado.
$familiar_id = (int)$usuario['id'];
$dias = isset($_GET['dias']) ? intval($_GET['dias']) : 7;

try {
    // 1. Obtener todos los adultos mayores vinculados a este familiar
    $queryVinculados = "SELECT adulto_mayor_id FROM vinculaciones WHERE familiar_id = ? AND estado = 'activo'";
    $stmtVinculados = $conn->prepare($queryVinculados);
    $stmtVinculados->execute([$familiar_id]);
    $vinculados = $stmtVinculados->fetchAll(PDO::FETCH_COLUMN);

    if (empty($vinculados)) {
        echo json_encode([
            "success" => true,
            "adultos" => [],
            "historial" => [],
            "estadisticas" => [
                "total_medicamentos" => 0,
                "tomados" => 0,
                "omitidos" => 0,
                "porcentaje_cumplimiento" => 0,
                "dias_analizados" => $dias
            ],
            "mensaje" => "No hay adultos mayores vinculados"
        ]);
        exit();
    }

    // 2. Obtener información de los adultos mayores
    $placeholders = implode(',', array_fill(0, count($vinculados), '?'));
    $queryAdultos = "SELECT id, nombre FROM usuarios WHERE id IN ($placeholders)";
    $stmtAdultos = $conn->prepare($queryAdultos);
    $stmtAdultos->execute($vinculados);
    $adultos = $stmtAdultos->fetchAll(PDO::FETCH_ASSOC);

    // 3. Obtener todos los medicamentos de los adultos vinculados
    $queryMeds = "SELECT m.id, m.nombre, m.dosis, m.horario, m.adulto_mayor_id, m.recurrencia_horas,
                         u.nombre as adulto_nombre
                  FROM medicamentos m
                  JOIN usuarios u ON m.adulto_mayor_id = u.id
                  WHERE m.adulto_mayor_id IN ($placeholders)
                  ORDER BY u.nombre, m.horario";
    $stmtMeds = $conn->prepare($queryMeds);
    $stmtMeds->execute($vinculados);
    $medicamentos = $stmtMeds->fetchAll(PDO::FETCH_ASSOC);

    // 4. Obtener historial de tomas de los últimos N días
    $fecha_inicio = date('Y-m-d', strtotime("-$dias days"));
    $queryHistorial = "SELECT 
                          h.fecha_toma,
                          h.hora_toma,
                          m.nombre as medicamento_nombre,
                          m.dosis,
                          m.adulto_mayor_id,
                          u.nombre as adulto_nombre
                       FROM historial_tomas h
                       JOIN medicamentos m ON h.medicamento_id = m.id
                       JOIN usuarios u ON m.adulto_mayor_id = u.id
                       WHERE m.adulto_mayor_id IN ($placeholders)
                       AND h.fecha_toma >= ?
                       ORDER BY h.fecha_toma DESC, h.hora_toma DESC";
    
    $params = array_merge($vinculados, [$fecha_inicio]);
    $stmtHistorial = $conn->prepare($queryHistorial);
    $stmtHistorial->execute($params);
    $historial = $stmtHistorial->fetchAll(PDO::FETCH_ASSOC);

    // 5. Calcular estadísticas
    $total_medicamentos = count($medicamentos);
    $total_tomados = 0;
    $total_omitidos = 0;
    $tomados_por_dia = [];
    $medicamentos_por_adulto = [];

    // Inicializar estructura por adulto
    foreach ($adultos as $adulto) {
        $medicamentos_por_adulto[$adulto['id']] = [
            'nombre' => $adulto['nombre'],
            'total' => 0,
            'tomados' => 0,
            'omitidos' => 0,
            'medicamentos' => []
        ];
    }

    // Procesar medicamentos
    foreach ($medicamentos as $med) {
        $adulto_id = $med['adulto_mayor_id'];
        $medicamentos_por_adulto[$adulto_id]['total']++;
        $medicamentos_por_adulto[$adulto_id]['medicamentos'][] = $med;
        $total_medicamentos++;
    }

    // Procesar historial y contar tomados por día
    $fechas_unicas = [];
    foreach ($historial as $toma) {
        $fecha = $toma['fecha_toma'];
        $adulto_id = $toma['adulto_mayor_id'];
        
        if (!isset($fechas_unicas[$fecha])) {
            $fechas_unicas[$fecha] = 0;
        }
        $fechas_unicas[$fecha]++;
        $total_tomados++;
        
        if (isset($medicamentos_por_adulto[$adulto_id])) {
            $medicamentos_por_adulto[$adulto_id]['tomados']++;
        }
    }

    // Calcular omitidos por adulto
    foreach ($medicamentos_por_adulto as $adulto_id => &$data) {
        $data['omitidos'] = $data['total'] - $data['tomados'];
        $total_omitidos += $data['omitidos'];
    }

    // Crear línea de tiempo (días)
    $linea_tiempo = [];
    $fecha_actual = new DateTime($fecha_inicio);
    $fecha_fin = new DateTime();

    while ($fecha_actual <= $fecha_fin) {
        $fecha_str = $fecha_actual->format('Y-m-d');
        $linea_tiempo[] = [
            'fecha' => $fecha_str,
            'fecha_formateada' => $fecha_actual->format('d/m/Y'),
            'tomados' => $fechas_unicas[$fecha_str] ?? 0,
            'pendientes' => $total_medicamentos - ($fechas_unicas[$fecha_str] ?? 0)
        ];
        $fecha_actual->modify('+1 day');
    }

    // Calcular porcentaje general
    $porcentaje = $total_medicamentos > 0 
        ? round(($total_tomados / ($total_tomados + $total_omitidos)) * 100, 1) 
        : 0;

    // Obtener detalles de medicamentos con su estado actual (para la tabla)
    $detalle_medicamentos = [];
    $hoy = date('Y-m-d');
    
    foreach ($medicamentos as $med) {
        // Verificar si se tomó hoy
        $queryCheck = "SELECT id FROM historial_tomas 
                       WHERE medicamento_id = ? AND fecha_toma = ?";
        $stmtCheck = $conn->prepare($queryCheck);
        $stmtCheck->execute([$med['id'], $hoy]);
        $tomado_hoy = $stmtCheck->rowCount() > 0;
        
        $detalle_medicamentos[] = [
            'id' => $med['id'],
            'nombre' => $med['nombre'],
            'dosis' => $med['dosis'],
            'horario' => $med['horario'],
            'adulto_nombre' => $med['adulto_nombre'],
            'adulto_id' => $med['adulto_mayor_id'],
            'tomado_hoy' => $tomado_hoy,
            'ultima_toma' => null // Se podría agregar la última toma
        ];
    }

    echo json_encode([
        "success" => true,
        "adultos" => $adultos,
        "medicamentos" => $detalle_medicamentos,
        "historial" => $historial,
        "linea_tiempo" => $linea_tiempo,
        "estadisticas" => [
            "total_medicamentos" => $total_medicamentos,
            "tomados" => $total_tomados,
            "omitidos" => $total_omitidos,
            "porcentaje_cumplimiento" => $porcentaje,
            "dias_analizados" => $dias,
            "por_adulto" => $medicamentos_por_adulto
        ]
    ]);

} catch (PDOException $e) {
    error_log("Error en obtener_bitacora_familiar: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "No se pudo obtener la bitácora."
    ]);
}
?>