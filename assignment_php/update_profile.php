<?php
header('Content-Type: application/json');
include_once("db_config.php");

$response = array();

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    if (isset($_POST['worker_id'])) {
        $worker_id = $_POST['worker_id'];
        $full_name = $_POST['full_name'] ?? null;
        $phone = $_POST['phone'] ?? null;
        $address = $_POST['address'] ?? null;
        
        try {
            $sql = "UPDATE workers SET ";
            $params = array();
            $types = "";
            
            if ($full_name !== null) {
                $sql .= "full_name = ?, ";
                $params[] = $full_name;
                $types .= "s";
            }
            if ($phone !== null) {
                $sql .= "phone = ?, ";
                $params[] = $phone;
                $types .= "s";
            }
            if ($address !== null) {
                $sql .= "address = ?, ";
                $params[] = $address;
                $types .= "s";
            }
            
            $sql = rtrim($sql, ", ") . " WHERE id = ?";
            $params[] = $worker_id;
            $types .= "i";
            
            $stmt = $conn->prepare($sql);
            $stmt->bind_param($types, ...$params);
            
            if ($stmt->execute()) {
                $response['success'] = true;
                $response['message'] = 'Profile updated successfully';
            } else {
                throw new Exception('Failed to update profile');
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