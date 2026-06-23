<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

include_once 'conexion.php';

try {

    $query = "
        SELECT
            f.id AS familiar_id,
            f.nombre AS familiar_nombre,

            a.id AS adulto_id,
            a.nombre AS adulto_nombre,

            v.estado,
            v.codigo_vinculacion

        FROM vinculaciones v

        INNER JOIN usuarios f
            ON v.familiar_id = f.id

        INNER JOIN usuarios a
            ON v.adulto_mayor_id = a.id

        ORDER BY v.id DESC
    ";

    $stmt = $conn->prepare($query);
    $stmt->execute();

    $datos = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        "success" => true,
        "vinculaciones" => $datos
    ]);

} catch(PDOException $e){

    echo json_encode([
        "success" => false,
        "message" => $e->getMessage()
    ]);
}
?>