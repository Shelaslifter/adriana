<?php
error_reporting(0);
ini_set('display_errors', 0);

// Iniciar el almacenamiento en búfer para evitar espacios basura
ob_start();

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

include_once 'conexion.php';
include_once 'auth_middleware.php';

$usuario = requireAuth(['familiar']);

$data = json_decode(file_get_contents("php://input"), true);

// Verificamos todos los campos obligatorios que envía Flutter
if (
    !empty($data['nombre']) && 
    !empty($data['dosis']) && 
    !empty($data['horario']) && 
    isset($data['adulto_mayor_id']) && 
    isset($data['recurrencia_horas'])
) {
    
    try {
        $nombre = trim($data['nombre']);
        $dosis = trim($data['dosis']);
        $horario = trim($data['horario']);
        $adulto_mayor_id = intval($data['adulto_mayor_id']);
        $recurrencia_horas = intval($data['recurrencia_horas']);
        $nota = !empty($data['nota']) ? trim($data['nota']) : null;

        // Verificar que el adulto mayor esté vinculado activamente a este familiar
        $chkVinc = $conn->prepare("SELECT id FROM vinculaciones WHERE adulto_mayor_id = :aid AND familiar_id = :fid AND estado = 'activo'");
        $chkVinc->execute([':aid' => $adulto_mayor_id, ':fid' => $usuario['id']]);
        if ($chkVinc->rowCount() === 0) {
            ob_clean();
            http_response_code(403);
            echo json_encode(["success" => false, "message" => "No tienes permiso sobre este adulto mayor."]);
            exit();
        }

        // Incluimos de forma explícita la columna obligatoria de la BD
        $query = "INSERT INTO medicamentos (nombre, dosis, horario, adulto_mayor_id, recurrencia_horas, nota)
                  VALUES (:nombre, :dosis, :horario, :adulto_id, :recurrencia, :nota)";

        $stmt = $conn->prepare($query);
        $stmt->bindParam(":nombre", $nombre, PDO::PARAM_STR);
        $stmt->bindParam(":dosis", $dosis, PDO::PARAM_STR);
        $stmt->bindParam(":horario", $horario, PDO::PARAM_STR);
        $stmt->bindParam(":adulto_id", $adulto_mayor_id, PDO::PARAM_INT);
        $stmt->bindParam(":recurrencia", $recurrencia_horas, PDO::PARAM_INT);
        $stmt->bindParam(":nota", $nota, PDO::PARAM_STR);

        if ($stmt->execute()) {
            $nuevoId = $conn->lastInsertId();
            ob_clean();
            http_response_code(200);
            echo json_encode([
                "success" => true, 
                "medicamento_id" => intval($nuevoId), 
                "message" => "Medicamento asignado correctamente."
            ]);
        } else {
            ob_clean();
            http_response_code(200);
            echo json_encode(["success" => false, "message" => "No se pudo insertar el registro."]);
        }
    } catch(PDOException $e) {
        ob_clean();
        error_log("Error en guardar_medicamento: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(["success" => false, "message" => "No se pudo guardar el medicamento."]);
    }
} else {
    ob_clean();
    http_response_code(200);
    echo json_encode(["success" => false, "message" => "Datos incompletos enviados por la aplicación."]);
}

ob_end_flush();
?>