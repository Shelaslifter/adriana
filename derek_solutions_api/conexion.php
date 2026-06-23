<?php
$host = "localhost";
$db_name = "derek_solutions_db";
$username = "root"; // Usuario por defecto de XAMPP
$password = "";     // Contraseña por defecto vacía en XAMPP

try {
    // Creamos la conexión usando PDO y forzamos el formato de caracteres UTF-8 para evitar problemas con acentos o eñes
    $conn = new PDO("mysql:host=" . $host . ";dbname=" . $db_name . ";charset=utf8", $username, $password);
    
    // Configuramos PDO para que lance excepciones en caso de errores de SQL
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
} catch(PDOException $exception) {
    // Si la conexión falla, devolvemos un JSON informando el error a Flutter
    http_response_code(500);
    echo json_encode([
        "success" => false, 
        "message" => "Error de conexión a la base de datos: " . $exception->getMessage()
    ]);
    exit();
}
?>