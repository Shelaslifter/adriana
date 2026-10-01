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

$usuario = requireAuth(); // 401 automático si el token falta/expiró/es inválido

try {
    $stmt = $conn->prepare("SELECT id, nombre, email, telefono, rol, estado FROM usuarios WHERE id = :id LIMIT 1");
    $stmt->execute([':id' => $usuario['id']]);
    $perfil = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$perfil) {
        http_response_code(404);
        echo json_encode(["success" => false, "message" => "Usuario no encontrado."]);
        exit();
    }

    http_response_code(200);
    echo json_encode(["success" => true, "perfil" => $perfil]);
} catch (PDOException $e) {
    error_log("Error en obtener_perfil: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Error al obtener el perfil."]);
}
?>
