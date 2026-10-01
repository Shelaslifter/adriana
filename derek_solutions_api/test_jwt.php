<?php
include_once 'conexion.php';
include_once 'JwtHandler.php';

$secret = $_ENV['JWT_SECRET'] ?? null;
if (empty($secret)) {
    die("JWT_SECRET no está configurado en .env");
}

// 1. Generar token de prueba con expiración corta (2 segundos)
$usuario = ["id" => 1, "nombre" => "José Luis", "rol" => "familiar"];
$token = JwtHandler::generarToken($usuario, $secret, 0.0005); // ~2 segundos

echo "<b>1. Token Generado:</b><br>" . $token . "<br><br>";

// 2. Validar token recién creado
$validacion1 = JwtHandler::verificarToken($token, $secret);
echo "<b>2. Validación Inmediata:</b> " . ($validacion1 ? "ÉXITO (Token Válido)" : "FALLO") . "<br><br>";

// 3. Validar con secreto incorrecto (firma no debe coincidir)
$validacion3 = JwtHandler::verificarToken($token, $secret . "_incorrecto");
echo "<b>3. Validación con secreto incorrecto:</b> " . (!$validacion3 ? "ÉXITO (Rechazado)" : "FALLO (Acepto firma inválida)") . "<br><br>";

// 4. Validar con payload alterado manteniendo la firma original
$parts = explode('.', $token);
$payloadFalso = rtrim(strtr(base64_encode(json_encode([
    "iat" => time(), "exp" => time() + 28800, "data" => ["id" => 1, "rol" => "administrador"]
])), '+/', '-_'), '=');
$tokenAlterado = $parts[0] . "." . $payloadFalso . "." . $parts[2];
$validacion4 = JwtHandler::verificarToken($tokenAlterado, $secret);
echo "<b>4. Validación con payload alterado:</b> " . (!$validacion4 ? "ÉXITO (Rechazado)" : "FALLO (Acepto token alterado)") . "<br><br>";

// 5. Simular espera para expiración
echo "<b>5. Esperando 3 segundos para probar caducidad...</b><br>";
sleep(3);

// 6. Validar token caducado
$validacion2 = JwtHandler::verificarToken($token, $secret);
echo "<b>6. Validación tras expiración:</b> " . ($validacion2 ? "FALLO (Sigue válido)" : "ÉXITO (Rechazado por expiración)") . "<br>";
?>
