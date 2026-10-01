<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

include_once 'conexion.php';

$data = json_decode(file_get_contents("php://input"));

if (!empty($data->codigo_vinculacion)) {

    $codigo = trim($data->codigo_vinculacion);

    try {

        $query = "
            SELECT
                u.id,
                u.nombre,
                v.id AS vinculacion_id
            FROM vinculaciones v
            INNER JOIN usuarios u
                ON v.adulto_mayor_id = u.id
            WHERE v.codigo_vinculacion = :codigo
            LIMIT 1
        ";

        $stmt = $conn->prepare($query);
        $stmt->bindParam(":codigo", $codigo, PDO::PARAM_STR);
        $stmt->execute();

        if ($stmt->rowCount() > 0) {

            $row = $stmt->fetch(PDO::FETCH_ASSOC);

            $adulto_mayor_id = $row['id'];
            $nombre = $row['nombre'];
            $vinculacion_id = $row['vinculacion_id'];

            // Activar la vinculación
            $update = "
                UPDATE vinculaciones
                SET estado = 'activo'
                WHERE id = :id
            ";

            $stmtUpdate = $conn->prepare($update);
            $stmtUpdate->bindParam(":id", $vinculacion_id, PDO::PARAM_INT);
            $stmtUpdate->execute();

            http_response_code(200);

            echo json_encode([
                "success" => true,
                "message" => "Dispositivo vinculado correctamente.",
                "adulto_mayor_id" => $adulto_mayor_id,
                "nombre" => $nombre
            ]);

        } else {

            http_response_code(200);

            echo json_encode([
                "success" => false,
                "message" => "Código de vinculación inválido."
            ]);
        }

    } catch(PDOException $e) {

        error_log("Error en vincular_codigo: " . $e->getMessage());
        http_response_code(500);

        echo json_encode([
            "success" => false,
            "message" => "No se pudo vincular el código."
        ]);
    }

} else {

    http_response_code(400);

    echo json_encode([
        "success" => false,
        "message" => "No se recibió el código."
    ]);
}
?>