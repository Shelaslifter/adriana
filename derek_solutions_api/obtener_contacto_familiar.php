<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: GET");

include_once 'conexion.php';

if (isset($_GET['adulto_mayor_id'])) {
    $adulto_id = intval($_GET['adulto_mayor_id']);

    try {
        // Vincula al abuelo con su familiar asignado y extrae su teléfono
        $query = "SELECT u.telefono FROM usuarios u 
                  INNER JOIN vinculaciones v ON u.id = v.familiar_id 
                  WHERE v.adulto_mayor_id = :adulto_id LIMIT 1";
                  
        $stmt = $conn->prepare($query);
        $stmt->execute([':adulto_id' => $adulto_id]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($row) {
            echo json_encode(["success" => true, "telefono" => $row['telefono']]);
        } else {
            echo json_encode(["success" => false, "message" => "No se encontró familiar vinculado."]);
        }
    } catch (PDOException $e) {
        echo json_encode(["success" => false, "message" => $e->getMessage()]);
    }
}
?>