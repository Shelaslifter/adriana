<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

include_once 'conexion.php';
include_once 'auth_middleware.php';

$usuario = requireAuth(['familiar']);

$data = json_decode(file_get_contents("php://input"));

if (!empty($data->nombre)) {
    $nombre = trim($data->nombre);
    // El familiar_id SIEMPRE es el del usuario autenticado; nunca se confía en el valor enviado por el cliente.
    $familiar_id = (int)$usuario['id'];

    // Generamos el código de 6 dígitos
    $codigo_generated = str_pad(rand(0, 999999), 6, '0', STR_PAD_LEFT);

    try {
        $conn->beginTransaction();

        // 1. Insertar en la tabla usuarios
        $queryUsuario = "INSERT INTO usuarios (nombre, rol, estado) VALUES (:nombre, 'adulto_mayor', 'pendiente')";
        $stmtUser = $conn->prepare($queryUsuario);
        $stmtUser->execute([':nombre' => $nombre]);

        $adulto_mayor_id = $conn->lastInsertId();

        // 2. Insertar en vinculaciones coincidiendo exactamente con la columna limpia
        $queryVinculacion = "INSERT INTO vinculaciones (familiar_id, adulto_mayor_id, codigo_vinculacion) 
                             VALUES (:familiar_id, :adulto_id, :codigo)";
        
        $stmtVinc = $conn->prepare($queryVinculacion);
        $exito = $stmtVinc->execute([
            ':familiar_id' => $familiar_id,
            ':adulto_id'   => $adulto_mayor_id,
            ':codigo'      => $codigo_generated
        ]);
        
        if ($exito) {
            $conn->commit();
            http_response_code(200);
            echo json_encode([
                "success" => true,
                "message" => "Código de vinculación generado con éxito.",
                "codigo" => $codigo_generated
            ]);
        } else {
            $conn->rollBack();
            http_response_code(200);
            echo json_encode(["success" => false, "message" => "No se pudo insertar en vinculaciones."]);
        }

    } catch (PDOException $e) {
        if ($conn->inTransaction()) {
            $conn->rollBack();
        }
        error_log("Error en crear_vinculacion: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(["success" => false, "message" => "Error al generar la vinculación."]);
    }
} else {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Datos incompletos."]);
}
?>