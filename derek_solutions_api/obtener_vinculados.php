<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: GET");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

include_once 'conexion.php';
include_once 'auth_middleware.php';

$usuario = requireAuth(['familiar']);

if(!empty($_GET['familiar_id'])){
    // Se ignora cualquier familiar_id enviado por el cliente: siempre se usa el del token verificado.
    $familiar_id = (int)$usuario['id'];

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
        error_log("Error en obtener_vinculados: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(["success" => false, "message" => "No se pudieron obtener los vinculados."]);
    }
} else {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Falta el parámetro familiar_id."]);
}
?>