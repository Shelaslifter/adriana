<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: GET");

include_once 'conexion.php';

if(!empty($_GET['familiar_id'])){
    // Forzamos que sea un entero limpio
    $familiar_id = intval($_GET['familiar_id']);

    try {
        // Mantenemos la lógica de traer activos y pendientes, asegurando los alias de las tablas
        $query = "SELECT u.id, u.nombre FROM vinculaciones v 
                  INNER JOIN usuarios u ON v.adulto_mayor_id = u.id 
                  WHERE v.familiar_id = :familiar_id 
                  AND (v.estado = 'activo' OR v.estado = 'pendiente')";
                  
        $stmt = $conn->prepare($query);
        $stmt->bindParam(":familiar_id", $familiar_id, PDO::PARAM_INT);
        $stmt->execute();

        $lista = $stmt->fetchAll(PDO::FETCH_ASSOC);

        http_response_code(200);
        echo json_encode([
            "success" => true,
            "adultos" => $lista
        ]);
    } catch(PDOException $e) {
        http_response_code(500);
        echo json_encode(["success" => false, "message" => "Error en la consulta: " . $e->getMessage()]);
    }
} else {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Falta el parámetro familiar_id."]);
}
?>