<?php
error_reporting(0);
ini_set('display_errors', 0);

ob_start();

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

include_once 'conexion.php'; 

$data = json_decode(file_get_contents("php://input"), true);

if (
    !$data ||
    !array_key_exists('id', $data) || 
    !array_key_exists('nombre', $data) || 
    !array_key_exists('dosis', $data) || 
    !array_key_exists('horario', $data) ||
    !array_key_exists('adulto_mayor_id', $data) ||
    !array_key_exists('recurrencia_horas', $data)
) {
    ob_clean();
    http_response_code(200);
    echo json_encode(["success" => false, "message" => "Datos incompletos para actualizar."]);
    exit();
}

$id = intval($data['id']);
$adulto_mayor_id = intval($data['adulto_mayor_id']);
$nombre = trim($data['nombre']);
$dosis = trim($data['dosis']);
$horario = trim($data['horario']);
$recurrencia_horas = intval($data['recurrencia_horas']);

try {
    $query = "UPDATE medicamentos 
              SET adulto_mayor_id = :adulto_mayor_id, 
                  nombre = :nombre, 
                  dosis = :dosis, 
                  horario = :horario, 
                  recurrencia_horas = :recurrencia 
              WHERE id = :id";
              
    $stmt = $conn->prepare($query);
    
    $stmt->bindParam(':adulto_mayor_id', $adulto_mayor_id, PDO::PARAM_INT);
    $stmt->bindParam(':nombre', $nombre, PDO::PARAM_STR);
    $stmt->bindParam(':dosis', $dosis, PDO::PARAM_STR);
    $stmt->bindParam(':horario', $horario, PDO::PARAM_STR);
    $stmt->bindParam(':recurrencia', $recurrencia_horas, PDO::PARAM_INT);
    $stmt->bindParam(':id', $id, PDO::PARAM_INT);
    
    if ($stmt->execute()) {
        ob_clean();
        http_response_code(200);
        echo json_encode(["success" => true, "message" => "Medicamento actualizado correctamente."]);
    } else {
        ob_clean();
        http_response_code(200);
        echo json_encode(["success" => false, "message" => "No se pudieron guardar los cambios en la fila."]);
    }
} catch (PDOException $e) {
    ob_clean();
    http_response_code(200);
    echo json_encode(["success" => false, "message" => "Error de BD: " . $e->getMessage()]);
}

ob_end_flush();
?>