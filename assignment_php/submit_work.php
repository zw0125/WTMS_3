<?php
header('Content-Type: application/json');
include_once("db_config.php");

$response = array();

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    if (isset($_POST['work_id']) && isset($_POST['worker_id']) && isset($_POST['submission_text'])) {
        $work_id = $_POST['work_id'];
        $worker_id = $_POST['worker_id'];
        $submission_text = $_POST['submission_text'];
        
        try {
            // Start transaction
            $conn->begin_transaction();
            
            // First verify that this work is assigned to this worker
            $check_sql = "SELECT id FROM tbl_works WHERE id = ? AND assigned_to = ?";
            $check_stmt = $conn->prepare($check_sql);
            $check_stmt->bind_param("ii", $work_id, $worker_id);
            $check_stmt->execute();
            $check_result = $check_stmt->get_result();
            
            if ($check_result->num_rows == 0) {
                throw new Exception('This task is not assigned to you');
            }
            
            // Insert submission
            $sql = "INSERT INTO tbl_submissions (work_id, worker_id, submission_text) 
                    VALUES (?, ?, ?)";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param("iis", $work_id, $worker_id, $submission_text);
            
            if (!$stmt->execute()) {
                throw new Exception('Failed to submit work');
            }
            
            // Update work status
            $completion_date = date('Y-m-d H:i:s'); // Get current datetime
            $update_sql = "UPDATE tbl_works SET status = 'completed', completion_date = ? WHERE id = ?";
            $update_stmt = $conn->prepare($update_sql);
            $update_stmt->bind_param("si", $completion_date, $work_id);
            
            if (!$update_stmt->execute()) {
                throw new Exception('Failed to update work status');
            }
            
            // Commit transaction
            $conn->commit();
            
            $response['success'] = true;
            $response['message'] = 'Work submitted successfully';
            
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