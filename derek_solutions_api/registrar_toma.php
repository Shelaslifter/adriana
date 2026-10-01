<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");

include_once 'conexion.php';

$data = json_decode(file_get_contents("php://input"), true);

if (!isset($data['adulto_mayor_id']) || !isset($data['medicamento_id'])) {
    echo json_encode([
        "success" => false,
        "message" => "Faltan datos requeridos"
    ]);
    exit();
}

$adulto_mayor_id = intval($data['adulto_mayor_id']);
$medicamento_id = intval($data['medicamento_id']);
$fecha_hoy = date('Y-m-d');
$hora_actual = date('H:i:s');

try {
    // Verificar que el medicamento existe y pertenece al adulto mayor
    $query_med = "SELECT id, nombre, recurrencia_horas FROM medicamentos WHERE id = ? AND adulto_mayor_id = ?";
    $stmt_med = $conn->prepare($query_med);
    $stmt_med->execute([$medicamento_id, $adulto_mayor_id]);
    $medicamento = $stmt_med->fetch(PDO::FETCH_ASSOC);
    
    if (!$medicamento) {
        echo json_encode([
            "success" => false,
            "message" => "El medicamento no existe o no pertenece a este adulto mayor"
        ]);
        exit();
    }

    $recurrencia = intval($medicamento['recurrencia_horas']);

    // Para no recurrentes, verificar si ya se tomó hoy
    if ($recurrencia === 0) {
        $query_check = "SELECT id FROM historial_tomas WHERE medicamento_id = ? AND fecha_toma = ?";
        $stmt_check = $conn->prepare($query_check);
        $stmt_check->execute([$medicamento_id, $fecha_hoy]);
        
        if ($stmt_check->rowCount() > 0) {
            echo json_encode([
                "success" => false,
                "message" => "Este medicamento ya fue tomado hoy"
            ]);
            exit();
        }
    }

    // Registrar la toma
    $query_insert = "INSERT INTO historial_tomas (medicamento_id, fecha_toma, hora_toma) VALUES (?, ?, ?)";
    $stmt_insert = $conn->prepare($query_insert);
    $resultado = $stmt_insert->execute([$medicamento_id, $fecha_hoy, $hora_actual]);

    if (!$resultado) {
        echo json_encode([
            "success" => false,
            "message" => "Error al registrar la toma"
        ]);
        exit();
    }

    // Calcular siguiente toma si es recurrente
    $siguiente_hora = null;
    $es_recurrente = false;
    
    if ($recurrencia > 0) {
        $es_recurrente = true;
        $siguiente_hora = date('H:i:s', strtotime($hora_actual . " + $recurrencia hours"));
    }

    echo json_encode([
        "success" => true,
        "message" => "✅ Toma registrada",
        "recurrente" => $es_recurrente,
        "siguiente_horario" => $siguiente_hora,
        "nombre_medicamento" => $medicamento['nombre']
    ]);

} catch (PDOException $e) {
    echo json_encode([
        "success" => false,
        "message" => "Error: " . $e->getMessage()
    ]);
}
?>