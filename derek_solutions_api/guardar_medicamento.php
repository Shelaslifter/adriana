<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

include_once 'conexion.php';

$data = json_decode(file_get_contents("php://input"), true);

// Verificamos que los campos obligatorios existan
if (!empty($data['nombre']) && !empty($data['dosis']) && !empty($data['horario']) && !empty($data['adulto_mayor_id'])) {
    
    try {
        $nombre = $data['nombre'];
        $dosis = $data['dosis'];
        $horario = $data['horario'];
        $adulto_mayor_id = intval($data['adulto_mayor_id']); // Forzamos entero

        $query = "INSERT INTO medicamentos (nombre, dosis, horario, adulto_mayor_id) 
                  VALUES (:nombre, :dosis, :horario, :adulto_id)";
                  
        $stmt = $conn->prepare($query);
        $stmt->bindParam(":nombre", $nombre);
        $stmt->bindParam(":dosis", $dosis);
        $stmt->bindParam(":horario", $horario);
        $stmt->bindParam(":adulto_id", $adulto_mayor_id, PDO::PARAM_INT);

        if ($stmt->execute()) {
            http_response_code(200);
            echo json_encode(["success" => true, "message" => "Medicamento asignado correctamente."]);
        } else {
            http_response_code(200);
            echo json_encode(["success" => false, "message" => "No se pudo guardar el medicamento."]);
        }
    } catch(PDOException $e) {
        http_response_code(200);
        echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
    }
} else {
    http_response_code(200);
    echo json_encode(["success" => false, "message" => "Datos incompletos. Verifica el ID del adulto."]);
}
?>