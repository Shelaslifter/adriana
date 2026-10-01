<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");

include_once 'conexion.php';

$data = json_decode(file_get_contents("php://input"));

if (!empty($data->id)) {
    $id = intval($data->id);

    try {
        $query = "DELETE FROM medicamentos WHERE id = :id";
        $stmt = $conn->prepare($query);
        
        if ($stmt->execute([':id' => $id])) {
            echo json_encode(["success" => true, "message" => "Medicamento eliminado correctamente."]);
        } else {
            echo json_encode(["success" => false, "message" => "No se pudo eliminar el registro."]);
        }
    } catch (PDOException $e) {
        echo json_encode(["success" => false, "message" => "Error SQL: " . $e->getMessage()]);
    }
} else {
    echo json_encode(["success" => false, "message" => "ID no proporcionado."]);
}
?>