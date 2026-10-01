<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: GET");
header("Cache-Control: no-cache, must-revalidate");

include_once 'conexion.php';

if (!isset($_GET['adulto_mayor_id']) || empty($_GET['adulto_mayor_id'])) {
    echo json_encode([
        "success" => false, 
        "message" => "Falta el ID del adulto mayor."
    ]);
    exit();
}

$adulto_mayor_id = intval($_GET['adulto_mayor_id']);
$fecha_hoy = date('Y-m-d');
$hora_actual = date('H:i:s');

try {
    // Verificar si el adulto mayor existe
    $check_user = $conn->prepare("SELECT id FROM usuarios WHERE id = :adulto_id");
    $check_user->execute([':adulto_id' => $adulto_mayor_id]);
    if ($check_user->rowCount() === 0) {
        echo json_encode([
            "success" => false,
            "message" => "El adulto mayor no existe"
        ]);
        exit();
    }

    // Obtener todos los medicamentos del adulto mayor
    $query = "SELECT id, nombre, dosis, horario, adulto_mayor_id, recurrencia_horas 
              FROM medicamentos 
              WHERE adulto_mayor_id = :adulto_mayor_id 
              ORDER BY horario ASC";

    $stmt = $conn->prepare($query);
    $stmt->execute([':adulto_mayor_id' => $adulto_mayor_id]);
    $medicamentos = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $resultado = [];

    foreach ($medicamentos as $med) {
        $med_id = intval($med['id']);
        $recurrencia = intval($med['recurrencia_horas']);

        // Verificar si ya se tomó hoy
        $query_toma = "SELECT hora_toma FROM historial_tomas 
                       WHERE medicamento_id = :med_id 
                       AND fecha_toma = :fecha_hoy 
                       ORDER BY hora_toma DESC LIMIT 1";
        
        $stmt_toma = $conn->prepare($query_toma);
        $stmt_toma->execute([
            ':med_id' => $med_id,
            ':fecha_hoy' => $fecha_hoy
        ]);
        $ultima_toma = $stmt_toma->fetch(PDO::FETCH_ASSOC);

        if ($ultima_toma) {
            // Ya se tomó hoy
            if ($recurrencia === 0) {
                // Toma única: no se muestra
                continue;
            } else {
                // Es recurrente: calcular siguiente toma
                $hora_ultima_toma = $ultima_toma['hora_toma'];
                $siguiente_toma = date('H:i:s', strtotime($hora_ultima_toma . " + $recurrencia hours"));
                
                if ($hora_actual >= $siguiente_toma) {
                    // Ya es hora de la siguiente toma
                    $resultado[] = [
                        "id" => $med_id,
                        "nombre" => $med['nombre'] ?? '',
                        "dosis" => $med['dosis'] ?? '',
                        "horario" => $siguiente_toma,
                        "adulto_mayor_id" => intval($med['adulto_mayor_id']),
                        "recurrencia_horas" => $recurrencia,
                        "estado" => "pendiente"
                    ];
                } else {
                    // Aún no es hora, mostrar con el horario de la siguiente toma
                    $resultado[] = [
                        "id" => $med_id,
                        "nombre" => $med['nombre'] ?? '',
                        "dosis" => $med['dosis'] ?? '',
                        "horario" => $siguiente_toma,
                        "adulto_mayor_id" => intval($med['adulto_mayor_id']),
                        "recurrencia_horas" => $recurrencia,
                        "estado" => "esperando"
                    ];
                }
            }
        } else {
            // No se ha tomado hoy
            $resultado[] = [
                "id" => $med_id,
                "nombre" => $med['nombre'] ?? '',
                "dosis" => $med['dosis'] ?? '',
                "horario" => $med['horario'] ?? '', 
                "adulto_mayor_id" => intval($med['adulto_mayor_id']),
                "recurrencia_horas" => $recurrencia,
                "estado" => "pendiente"
            ];
        }
    }

    echo json_encode([
        "success" => true,
        "medicamentos" => $resultado,
        "total" => count($resultado)
    ]);

} catch (PDOException $e) {
    error_log("Error en obtener_medicamentos_adulto: " . $e->getMessage());
    echo json_encode([
        "success" => false,
        "message" => "Error SQL: " . $e->getMessage()
    ]);
}
?>