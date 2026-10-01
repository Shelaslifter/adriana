<?php
include_once 'conexion.php';
include_once 'JwtHandler.php';

$secret = $_ENV['JWT_SECRET'] ?? 'DerekSolutions_SuperSecretKey_2026_Key!';

// 1. Generar token de prueba con expiración corta (2 segundos)
$usuario = ["id" => 1, "nombre" => "José Luis", "rol" => "familiar"];
$token = JwtHandler::generarToken($usuario, $secret, 0.0005); // ~2 segundos

echo "<b>1. Token Generado:</b><br>" . $token . "<br><br>";

// 2. Validar token recién creado
$validacion1 = JwtHandler::verificarToken($token, $secret);
echo "<b>2. Validación Inmediata:</b> " . ($validacion1 ? "ÉXITO (Token Válido)" : "FALLO") . "<br><br>";

// 3. Simular espera para expiración
echo "<b>3. Esperando 3 segundos para probar caducidad...</b><br>";
sleep(3);

// 4. Validar token caducado
$validacion2 = JwtHandler::verificarToken($token, $secret);
echo "<b>4. Validación tras expiración:</b> " . ($validacion2 ? "FALLO (Sigue válido)" : "ÉXITO (Rechazado por expiración)") . "<br>";
?>