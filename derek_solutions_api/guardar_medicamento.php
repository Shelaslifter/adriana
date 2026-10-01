<?php
error_reporting(0);
ini_set('display_errors', 0);

// Iniciar el almacenamiento en búfer para evitar espacios basura
ob_start();

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

include_once 'conexion.php';

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

        // Incluimos de forma explícita la columna obligatoria de la BD
        $query = "INSERT INTO medicamentos (nombre, dosis, horario, adulto_mayor_id, recurrencia_horas) 
                  VALUES (:nombre, :dosis, :horario, :adulto_id, :recurrencia)";
                  
        $stmt = $conn->prepare($query);
        $stmt->bindParam(":nombre", $nombre, PDO::PARAM_STR);
        $stmt->bindParam(":dosis", $dosis, PDO::PARAM_STR);
        $stmt->bindParam(":horario", $horario, PDO::PARAM_STR);
        $stmt->bindParam(":adulto_id", $adulto_mayor_id, PDO::PARAM_INT);
        $stmt->bindParam(":recurrencia", $recurrencia_horas, PDO::PARAM_INT);

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
        http_response_code(200);
        echo json_encode(["success" => false, "message" => "Error de BD: " . $e->getMessage()]);
    }
} else {
    ob_clean();
    http_response_code(200);
    echo json_encode(["success" => false, "message" => "Datos incompletos enviados por la aplicación."]);
}

ob_end_flush();
?>