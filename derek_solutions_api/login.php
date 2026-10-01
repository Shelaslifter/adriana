<?php
// Encabezados CORS
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

include_once 'conexion.php';
include_once 'JwtHandler.php';

$data = json_decode(file_get_contents("php://input"));

if (!empty($data->email) && !empty($data->password)) {
    
    $email    = trim($data->email);
    $password = $data->password;

    try {
        // Buscar el usuario por correo
        $query = "SELECT id, nombre, email, password, rol FROM usuarios WHERE email = :email LIMIT 1";
        $stmt  = $conn->prepare($query);
        $stmt->bindParam(":email", $email);
        $stmt->execute();

        if ($stmt->rowCount() > 0) {
            $row = $stmt->fetch(PDO::FETCH_ASSOC);

            // Todas las contraseñas de la BD ya están hasheadas con password_hash();
            // ya no se acepta comparación en texto plano.
            $esValido = $row['password'] !== null && password_verify($password, $row['password']);

            if ($esValido) {
                // Obtener la clave secreta desde .env (obligatoria, sin valor por defecto)
                $jwtSecret = $_ENV['JWT_SECRET'] ?? null;
                if (empty($jwtSecret)) {
                    http_response_code(500);
                    echo json_encode([
                        "success" => false,
                        "message" => "Error de configuración del servidor."
                    ]);
                    exit();
                }

                // Datos a incluir dentro del payload del token JWT
                $payloadData = [
                    "id"     => (int)$row['id'],
                    "nombre" => $row['nombre'],
                    "email"  => $row['email'],
                    "rol"    => $row['rol']
                ];

                // Generar el token firmado con 8 horas de vigencia
                $token = JwtHandler::generarToken($payloadData, $jwtSecret, 8);

                http_response_code(200);
                echo json_encode([
                    "success" => true,
                    "message" => "Inicio de sesión exitoso.",
                    "id"      => (int)$row['id'],
                    "nombre"  => $row['nombre'],
                    "email"   => $row['email'],
                    "rol"     => $row['rol'],
                    "token"   => $token
                ]);
                exit();
            }
        }

        // Si la verificación falla
        http_response_code(200);
        echo json_encode([
            "success" => false,
            "message" => "El correo o la contraseña son incorrectos."
        ]);

    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode([
            "success" => false,
            "message" => "Error interno en el servidor al procesar la solicitud."
        ]);
    }

} else {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "No se puede iniciar sesión. Faltan datos (correo o contraseña)."
    ]);
}
?>