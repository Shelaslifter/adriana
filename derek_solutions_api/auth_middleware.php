<?php
// Debe incluirse DESPUÉS de 'conexion.php' (que carga .env) y requiere 'JwtHandler.php'.
// Valida el header Authorization: Bearer <jwt> y corta la petición con 401/403/500 si no es válido.
// Devuelve el payload del usuario autenticado: ['id', 'nombre', 'email', 'rol'].

include_once __DIR__ . '/JwtHandler.php';

function requireAuth($allowedRoles = null) {
    $jwtSecret = $_ENV['JWT_SECRET'] ?? null;
    if (empty($jwtSecret)) {
        http_response_code(500);
        echo json_encode(["success" => false, "message" => "Error de configuración del servidor."]);
        exit();
    }

    $headers = getallheaders();
    $authHeader = $headers['Authorization'] ?? $headers['authorization'] ?? '';

    if (!preg_match('/Bearer\s(\S+)/', $authHeader, $matches)) {
        http_response_code(401);
        echo json_encode(["success" => false, "message" => "Acceso no autorizado. Token faltante."]);
        exit();
    }

    $usuario = JwtHandler::verificarToken($matches[1], $jwtSecret);
    if (!$usuario) {
        http_response_code(401);
        echo json_encode(["success" => false, "message" => "Token inválido o expirado."]);
        exit();
    }

    if ($allowedRoles !== null && !in_array($usuario['rol'], (array)$allowedRoles, true)) {
        http_response_code(403);
        echo json_encode(["success" => false, "message" => "No tienes permiso para realizar esta acción."]);
        exit();
    }

    return $usuario;
}
?>
