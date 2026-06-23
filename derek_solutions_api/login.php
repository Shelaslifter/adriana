<?php
// Permitir conexiones desde cualquier origen (necesario para que Flutter se conecte en desarrollo)
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// Incluimos la conexión que creamos anteriormente
include_once 'conexion.php';

// Leer los datos que Flutter envía en el cuerpo de la petición (body)
$data = json_decode(file_get_contents("php://input"));

// Validar que los datos no estén vacíos
if (!empty($data->email) && !empty($data->password)) {
    
    $email = $data->email;
    // Encriptamos la contraseña recibida en MD5 para compararla con la base de datos
    //$password = md5($data->password); 
    $password = $data->password;

    try {
        // Buscamos al usuario por su correo y contraseña
        $query = "SELECT id, nombre, email, rol FROM usuarios WHERE email = :email AND password = :password LIMIT 1";
        $stmt = $conn->prepare($query);
        
        $stmt->bindParam(":email", $email);
        $stmt->bindParam(":password", $password);
        $stmt->execute();

        // Si se encuentra el usuario
        if ($stmt->rowCount() > 0) {
            $row = $stmt->fetch(PDO::FETCH_ASSOC);

            // Respondemos con éxito y mandamos los datos del usuario para que Flutter sepa su rol
            http_response_code(200);
            echo json_encode([
                "success" => true,
                "message" => "Inicio de sesión exitoso.",
                "id" => $row['id'],
                "nombre" => $row['nombre'],
                "email" => $row['email'],
                "rol" => $row['rol'],
                "token" => "token_ficticio_jwt_derek_solutions" // Aquí simularías un token de sesión seguro
            ]);
        } else {
            // Credenciales incorrectas
            http_response_code(200); // Mantenemos 200 en desarrollo para facilitar el manejo en Flutter
            echo json_encode([
                "success" => false,
                "message" => "El correo o la contraseña son incorrectos."
            ]);
        }

    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode([
            "success" => false,
            "message" => "Error en el servidor al procesar la solicitud: " . $e->getMessage()
        ]);
    }

} else {
    // Datos incompletos
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "No se puede iniciar sesión. Faltan datos (correo o contraseña)."
    ]);
}
?>