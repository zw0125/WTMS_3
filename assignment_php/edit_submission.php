<?php
header('Content-Type: application/json');
include_once("db_config.php");

$response = array('success' => false);

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    if (isset($_POST['submission_id']) && isset($_POST['updated_text'])) {
        $submission_id = $_POST['submission_id'];
        $updated_text = $_POST['updated_text'];
        
        try {
            // Start transaction
            $conn->begin_transaction();
            
            // First verify submission exists and belongs to the worker
            $check_sql = "SELECT id FROM tbl_submissions WHERE id = ?";
            $check_stmt = $conn->prepare($check_sql);
            $check_stmt->bind_param("i", $submission_id);
            $check_stmt->execute();
            $check_result = $check_stmt->get_result();
            
            if ($check_result->num_rows == 0) {
                throw new Exception('Submission not found');
            }
            
            // Update submission text
            $update_sql = "UPDATE tbl_submissions SET submission_text = ? WHERE id = ?";
            $update_stmt = $conn->prepare($update_sql);
            $update_stmt->bind_param("si", $updated_text, $submission_id);
            
            if (!$update_stmt->execute()) {
                throw new Exception('Failed to update submission');
            }
            
            // Commit transaction
            $conn->commit();
            
            $response['success'] = true;
            $response['message'] = 'Submission updated successfully';
            
        } catch (Exception $e) {
            // Rollback transaction on error
            $conn->rollback();
            
            $response['success'] = false;
            $response['message'] = $e->getMessage();
        }
    } else {
        $response['success'] = false;
        $response['message'] = 'Missing required fields';
    }
} else {
    $response['success'] = false;
    $response['message'] = 'Invalid request method';
}

echo json_encode($response);
$conn->close();
?>