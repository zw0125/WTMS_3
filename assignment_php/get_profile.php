<?php
header('Content-Type: application/json');
include_once("db_config.php");

$response = array();

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    if (isset($_POST['worker_id'])) {
        $worker_id = $_POST['worker_id'];
        
        try {
            $sql = "SELECT id, full_name, email, phone, address FROM workers WHERE id = ?";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param("i", $worker_id);
            $stmt->execute();
            $result = $stmt->get_result();
            
            if ($result->num_rows === 1) {
                $worker = $result->fetch_assoc();
                $response['success'] = true;
                $response['worker'] = $worker;
            } else {
                throw new Exception('Worker not found');
            }
            
        } catch (Exception $e) {
            $response['success'] = false;
            $response['message'] = 'Database error: ' . $e->getMessage();
        }
    } else {
        $response['success'] = false;
        $response['message'] = 'Worker ID is required';
    }
} else {
    $response['success'] = false;
    $response['message'] = 'Invalid request method';
}

echo json_encode($response);
$conn->close();
?>