<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: GET");

include_once 'conexion.php';

if(!empty($_GET['familiar_id'])){
    $familiar_id = $_GET['familiar_id'];

    try {
        $query = "SELECT nombre, dosis, TIME_FORMAT(horario, '%r') as horario FROM medicamentos WHERE familiar_id = :id";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(":id", $familiar_id);
        $stmt->execute();

        $medicamentos = $stmt->fetchAll(PDO::FETCH_ASSOC);

        http_response_code(200);
        echo json_encode([
            "success" => true,
            "medicamentos" => $medicamentos
        ]);
    } catch(PDOException $e) {
        http_response_code(500);
        echo json_encode(["success" => false, "message" => $e->getMessage()]);
    }
}
?>
