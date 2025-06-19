<?php
header('Content-Type: application/json');
error_reporting(E_ALL);
ini_set('display_errors', 0);
include_once("db_config.php");

$response = array('success' => false);

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    if (isset($_POST['worker_id']) && isset($_FILES['image'])) {
        $worker_id = $_POST['worker_id'];
        $file = $_FILES['image'];
        
        try {
            // Create uploads directory if it doesn't exist
            $upload_dir = 'uploads/';
            if (!file_exists($upload_dir)) {
                mkdir($upload_dir, 0777, true);
            }
            
            // Generate unique filename
            $file_ext = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
            $file_name = 'profile_' . $worker_id . '_' . time() . '.' . $file_ext;
            $file_path = $upload_dir . $file_name;
            
            // Check file type
            $allowed_types = array('jpg', 'jpeg', 'png');
            if (!in_array($file_ext, $allowed_types)) {
                throw new Exception('Invalid file type. Only JPG, JPEG and PNG allowed.');
            }
            
            // Start transaction
            $conn->begin_transaction();
            
            if (move_uploaded_file($file['tmp_name'], $file_path)) {
                // Delete old profile image if exists
                $sql = "SELECT profile_image FROM workers WHERE id = ?";
                $stmt = $conn->prepare($sql);
                $stmt->bind_param("i", $worker_id);
                $stmt->execute();
                $result = $stmt->get_result();
                if ($row = $result->fetch_assoc()) {
                    if ($row['profile_image'] && file_exists($row['profile_image'])) {
                        unlink($row['profile_image']);
                    }
                }
                
                // Update database with new image path
                $sql = "UPDATE workers SET profile_image = ? WHERE id = ?";
                $stmt = $conn->prepare($sql);
                $stmt->bind_param("si", $file_path, $worker_id);
                
                if ($stmt->execute()) {
                    $conn->commit();
                    $response['success'] = true;
                    $response['message'] = 'Profile image uploaded successfully';
                    $response['image_url'] = $file_path;
                } else {
                    throw new Exception('Failed to update database');
                }
            } else {
                throw new Exception('Failed to upload image');
            }
            
        } catch (Exception $e) {
            // Rollback transaction on error
            if ($conn->connect_error === false) {
                $conn->rollback();
            }
            $response['message'] = $e->getMessage();
        }
    } else {
        $response['message'] = 'Missing required fields';
    }
} else {
    $response['message'] = 'Invalid request method';
}

echo json_encode($response);
$conn->close();
?>