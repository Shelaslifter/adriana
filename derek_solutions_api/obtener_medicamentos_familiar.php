<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: GET");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Cache-Control: no-cache, must-revalidate");

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
        "message" => "Falta el ID del familiar."
    ]);
    exit();
}

// Se ignora cualquier familiar_id enviado por el cliente: siempre se usa el del token verificado.
$familiar_id = (int)$usuario['id'];
$fecha_hoy = date('Y-m-d');
$hora_actual = date('H:i:s');

try {
    // OBTENER TODOS los adultos vinculados
    $queryVinc = "SELECT adulto_mayor_id, estado 
                  FROM vinculaciones 
                  WHERE familiar_id = :familiar_id";
    $stmtVinc = $conn->prepare($queryVinc);
    $stmtVinc->execute([':familiar_id' => $familiar_id]);
    $vinculados = $stmtVinc->fetchAll(PDO::FETCH_ASSOC);

    if (empty($vinculados)) {
        echo json_encode([
            "success" => true,
            "medicamentos" => [],
            "mensaje" => "No tienes adultos vinculados"
        ]);
        exit();
    }

    // Extraer todos los IDs
    $adultos_ids = array_column($vinculados, 'adulto_mayor_id');
    $placeholders = implode(',', array_fill(0, count($adultos_ids), '?'));
    
    // ✅ CONSULTA CORREGIDA - Sin u.apellido
    $query = "SELECT
                m.id,
                m.nombre,
                m.dosis,
                m.horario,
                m.adulto_mayor_id,
                m.recurrencia_horas,
                m.nota,
                u.nombre AS nombre_adulto
              FROM medicamentos m
              INNER JOIN usuarios u ON m.adulto_mayor_id = u.id
              WHERE m.adulto_mayor_id IN ($placeholders)
              ORDER BY u.nombre ASC, m.horario ASC";

    $stmt = $conn->prepare($query);
    $stmt->execute($adultos_ids);
    $medicamentos = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $resultado = [];

    foreach ($medicamentos as $med) {
        $med_id = intval($med['id']);
        $recurrencia = intval($med['recurrencia_horas']);

        // Verificar si ya se tomó hoy
        $query_toma = "SELECT hora_toma FROM historial_tomas 
                       WHERE medicamento_id = ? 
                       AND fecha_toma = ? 
                       ORDER BY hora_toma DESC LIMIT 1";
        
        $stmt_toma = $conn->prepare($query_toma);
        $stmt_toma->execute([$med_id, $fecha_hoy]);
        $ultima_toma = $stmt_toma->fetch(PDO::FETCH_ASSOC);

        // ✅ NOMBRE COMPLETO CORREGIDO - Solo usamos el nombre
        $nombre_completo = $med['nombre_adulto'] ?? 'Adulto Mayor';

        // Mostrar el medicamento
        $resultado[] = [
            "id" => $med_id,
            "nombre" => $med['nombre'] ?? 'Sin nombre',
            "dosis" => $med['dosis'] ?? 'Sin dosis',
            "horario" => $med['horario'] ?? '00:00:00',
            "adulto_mayor_id" => intval($med['adulto_mayor_id']),
            "recurrencia_horas" => $recurrencia,
            "nota" => $med['nota'] ?? null,
            "nombre_adulto" => $nombre_completo,
            "estado" => $ultima_toma ? "tomado" : "pendiente",
            "hora_toma_real" => $ultima_toma['hora_toma'] ?? null
        ];
    }

    echo json_encode([
        "success" => true,
        "medicamentos" => $resultado,
        "total_vinculados" => count($adultos_ids),
        "total_medicamentos" => count($resultado)
    ]);

} catch (PDOException $e) {
    error_log("Error en obtener_medicamentos_familiar: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "No se pudieron obtener los medicamentos."
    ]);
}
?>