<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: GET");

include_once 'conexion.php';

$adulto_mayor_id = isset($_GET['adulto_mayor_id']) ? intval($_GET['adulto_mayor_id']) : 0;

if ($adulto_mayor_id <= 0) {
    echo json_encode([
        "success" => false,
        "message" => "Falta el ID del adulto mayor"
    ]);
    exit();
}

try {
    // 1. Verificar adulto mayor
    $check = $conn->prepare("SELECT id, nombre FROM usuarios WHERE id = ?");
    $check->execute([$adulto_mayor_id]);
    if ($check->rowCount() === 0) {
        echo json_encode([
            "success" => false,
            "message" => "El adulto mayor no existe"
        ]);
        exit();
    }

    // 2. Obtener todos los medicamentos del adulto mayor
    $queryMeds = "SELECT id, nombre, dosis, recurrencia_horas FROM medicamentos WHERE adulto_mayor_id = ?";
    $stmtMeds = $conn->prepare($queryMeds);
    $stmtMeds->execute([$adulto_mayor_id]);
    $medicamentos = $stmtMeds->fetchAll(PDO::FETCH_ASSOC);
    $total_medicamentos = count($medicamentos);

    // 3. Obtener el historial de tomas
    $queryHistorial = "SELECT 
                        h.fecha_toma,
                        h.hora_toma,
                        m.nombre AS nombre_medicamento,
                        m.dosis,
                        'tomado' AS estado
                       FROM historial_tomas h
                       INNER JOIN medicamentos m ON h.medicamento_id = m.id
                       WHERE m.adulto_mayor_id = ?
                       ORDER BY h.fecha_toma DESC, h.hora_toma DESC
                       LIMIT 30";
    
    $stmt = $conn->prepare($queryHistorial);
    $stmt->execute([$adulto_mayor_id]);
    $tomas = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // 4. Si no hay medicamentos
    if ($total_medicamentos === 0) {
        echo json_encode([
            "success" => true,
            "historial" => [],
            "estadisticas" => [
                "total" => 0,
                "tomados" => 0,
                "omitidos" => 0,
                "porcentaje_cumplimiento" => 100.0,
                "mensaje" => "No hay medicamentos registrados"
            ]
        ]);
        exit();
    }

    // 5. Calcular estadísticas del día de hoy
    $fecha_hoy = date('Y-m-d');
    
    // Contar medicamentos tomados hoy
    $queryTomadosHoy = "SELECT COUNT(DISTINCT medicamento_id) as tomados 
                        FROM historial_tomas 
                        WHERE fecha_toma = ? 
                        AND medicamento_id IN (SELECT id FROM medicamentos WHERE adulto_mayor_id = ?)";
    $stmtTom = $conn->prepare($queryTomadosHoy);
    $stmtTom->execute([$fecha_hoy, $adulto_mayor_id]);
    $tomadosHoy = $stmtTom->fetch(PDO::FETCH_ASSOC);
    $total_tomados_hoy = intval($tomadosHoy['tomados']);

    // Calcular omitidos (medicamentos no tomados hoy)
    $total_omitidos = $total_medicamentos - $total_tomados_hoy;

    // Calcular porcentaje
    $porcentaje = $total_medicamentos > 0 
        ? round(($total_tomados_hoy / $total_medicamentos) * 100, 1) 
        : 0.0;

    // 6. Si no hay tomas registradas, mostrar medicamentos como pendientes
    if (empty($tomas)) {
        $historialPendiente = [];
        foreach ($medicamentos as $med) {
            $historialPendiente[] = [
                "fecha_toma" => $fecha_hoy,
                "hora_toma" => "00:00:00",
                "nombre_medicamento" => $med['nombre'],
                "dosis" => $med['dosis'],
                "estado" => "pendiente"
            ];
        }
        
        echo json_encode([
            "success" => true,
            "historial" => $historialPendiente,
            "estadisticas" => [
                "total" => $total_medicamentos,
                "tomados" => $total_tomados_hoy,
                "omitidos" => $total_omitidos,
                "porcentaje_cumplimiento" => $porcentaje
            ]
        ]);
        exit();
    }

    // 7. Retornar datos completos
    echo json_encode([
        "success" => true,
        "historial" => $tomas,
        "estadisticas" => [
            "total" => $total_medicamentos,
            "tomados" => $total_tomados_hoy,
            "omitidos" => $total_omitidos,
            "porcentaje_cumplimiento" => $porcentaje
        ]
    ]);

} catch (PDOException $e) {
    echo json_encode([
        "success" => false,
        "message" => "Error: " . $e->getMessage()
    ]);
}
?>