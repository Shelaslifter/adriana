<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

include_once 'conexion.php';

$data = json_decode(file_get_contents("php://input"));

if (!empty($data->nombre) && !empty($data->email) && !empty($data->password)) {
    $nombre = trim($data->nombre);
    $email = trim($data->email);
    $password = trim($data->password); // Nota: Puedes usar password_hash() si deseas encriptarla más adelante

    try {
        // 1. Verificar si el correo ya existe para evitar duplicados
        $checkQuery = "SELECT id FROM usuarios WHERE email = :email LIMIT 1";
        $checkStmt = $conn->prepare($checkQuery);
        $checkStmt->execute([':email' => $email]);

        if ($checkStmt->rowCount() > 0) {
            http_response_code(200);
            echo json_encode(["success" => false, "message" => "El correo electrónico ya está registrado."]);
            exit();
        }

        // 2. Insertar el nuevo familiar con estado 'activo' o 'pendiente' según tu flujo
        $query = "INSERT INTO usuarios (nombre, email, password, rol, estado) 
                  VALUES (:nombre, :email, :password, 'familiar', 'activo')";
        
        $stmt = $conn->prepare($query);
        $exito = $stmt->execute([
            ':nombre'   => $nombre,
            ':email'    => $email,
            ':password' => $password
        ]);

        if ($exito) {
            http_response_code(200);
            echo json_encode([
                "success" => true,
                "message" => "¡Registro exitoso! Ya puedes iniciar sesión."
            ]);
        } else {
            http_response_code(200);
            echo json_encode(["success" => false, "message" => "No se pudo completar el registro."]);
        }

    } catch (PDOException $e) {
        http_response_code(200);
        echo json_encode(["success" => false, "message" => "Error en la base de datos: " . $e->getMessage()]);
    }
} else {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Por favor, completa todos los campos."]);
}
?>