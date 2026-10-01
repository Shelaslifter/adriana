<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

include_once 'conexion.php';
include_once 'auth_middleware.php';

$usuario = requireAuth(['familiar']);

$data = json_decode(file_get_contents("php://input"));

if (!empty($data->id)) {
    $id = intval($data->id);

    try {
        // Verificar que el medicamento pertenece a un adulto mayor vinculado a este familiar
        $chk = $conn->prepare("SELECT m.id FROM medicamentos m
                                JOIN vinculaciones v ON v.adulto_mayor_id = m.adulto_mayor_id
                                WHERE m.id = :id AND v.familiar_id = :fid AND v.estado = 'activo'");
        $chk->execute([':id' => $id, ':fid' => $usuario['id']]);
        if ($chk->rowCount() === 0) {
            http_response_code(403);
            echo json_encode(["success" => false, "message" => "No tienes permiso sobre este medicamento."]);
            exit();
        }

        $query = "DELETE FROM medicamentos WHERE id = :id";
        $stmt = $conn->prepare($query);

        if ($stmt->execute([':id' => $id])) {
            echo json_encode(["success" => true, "message" => "Medicamento eliminado correctamente."]);
        } else {
            echo json_encode(["success" => false, "message" => "No se pudo eliminar el registro."]);
        }
    } catch (PDOException $e) {
        error_log("Error en eliminar_medicamento: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(["success" => false, "message" => "No se pudo eliminar el medicamento."]);
    }
} else {
    echo json_encode(["success" => false, "message" => "ID no proporcionado."]);
}
?>