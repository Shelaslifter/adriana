<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: GET");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

include_once 'conexion.php';

// Validamos que el ID no venga vacío
if (!empty($_GET['adulto_mayor_id'])) {
    // Forzamos que sea un valor entero para evitar inconsistencias de tipos
    $adulto_mayor_id = intval($_GET['adulto_mayor_id']);

    try {
        // Consulta exacta usando tu columna 'adulto_mayor_id'
        $query = "SELECT nombre, dosis, TIME_FORMAT(horario, '%h:%i %p') as horario 
                  FROM medicamentos 
                  WHERE adulto_mayor_id = :id 
                  ORDER BY horario ASC";
                  
        $stmt = $conn->prepare($query);
        $stmt->bindParam(":id", $adulto_mayor_id, PDO::PARAM_INT);
        $stmt->execute();

        $medicamentos = $stmt->fetchAll(PDO::FETCH_ASSOC);

        http_response_code(200);
        echo json_encode([
            "success" => true,
            "medicamentos" => $medicamentos
        ]);
    } catch(PDOException $e) {
        http_response_code(200); 
        echo json_encode([
            "success" => false, 
            "message" => "Error SQL: " . $e->getMessage(),
            "medicamentos" => []
        ]);
    }
} else {
    http_response_code(200);
    echo json_encode([
        "success" => false, 
        "message" => "No se proporcionó el parámetro adulto_mayor_id",
        "medicamentos" => []
    ]);
}
?>