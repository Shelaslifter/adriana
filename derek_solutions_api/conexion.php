<?php
// Carga de variables de entorno desde .env
function cargarEnv($ruta) {
    if (!file_exists($ruta)) {
        return false;
    }
    $lineas = file($ruta, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lineas as $linea) {
        $linea = trim($linea);
        if ($linea === '' || strpos($linea, '#') === 0) continue;
        if (strpos($linea, '=') !== false) {
            list($nombre, $valor) = explode('=', $linea, 2);
            $_ENV[trim($nombre)] = trim($valor);
        }
    }
    return true;
}

// Cargar el archivo .env de la raíz del proyecto
cargarEnv(__DIR__ . '/.env');

$host     = $_ENV['DB_HOST']    ?? 'localhost';
$db_name  = $_ENV['DB_NAME']    ?? 'derek_solutions_db';
$username = $_ENV['DB_USER']    ?? 'root';
$password = $_ENV['DB_PASS']    ?? '';
$charset  = $_ENV['DB_CHARSET'] ?? 'utf8mb4';

$dsn = "mysql:host={$host};dbname={$db_name};charset={$charset}";

$options = [
    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    PDO::ATTR_EMULATE_PREPARES   => false,
];

try {
    $conn = new PDO($dsn, $username, $password, $options);
} catch (PDOException $exception) {
    http_response_code(500);
    echo json_encode([
        "success" => false, 
        "message" => "Error de conexión a la base de datos."
    ]);
    exit();
}
?>