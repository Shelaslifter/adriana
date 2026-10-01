<?php
include_once 'conexion.php';
include_once 'JwtHandler.php';

// Obtener encabezados de la petición
$headers = getallheaders();
$authHeader = $headers['Authorization'] ?? $headers['authorization'] ?? '';

if (preg_match('/Bearer\s(\S+)/', $authHeader, $matches)) {
    $jwt = $matches[1];
    $jwtSecret = $_ENV['JWT_SECRET'] ?? 'ClaveSecretaPorDefecto123!';
    
    // Verificar token y caducidad
    $usuario = JwtHandler::verificarToken($jwt, $jwtSecret);

    if ($usuario) {
        // Token válido y no ha expirado
        // $usuario contiene ['id', 'nombre', 'email', 'rol']
    } else {
        http_response_code(401);
        echo json_encode(["success" => false, "message" => "Token inválido o expirado."]);
        exit();
    }
} else {
    http_response_code(401);
    echo json_encode(["success" => false, "message" => "Acceso no autorizado. Token faltante."]);
    exit();
}
?>