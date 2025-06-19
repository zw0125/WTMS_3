<?php
header('Content-Type: application/json');
include_once("db_config.php");

$response = array();

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    if (isset($_POST['worker_id'])) {
        $worker_id = $_POST['worker_id'];
        
        try {
            // Get total tasks
            $total_sql = "SELECT COUNT(*) as total FROM tbl_works WHERE assigned_to = ?";
            $total_stmt = $conn->prepare($total_sql);
            $total_stmt->bind_param("i", $worker_id);
            $total_stmt->execute();
            $total_result = $total_stmt->get_result()->fetch_assoc();
            
            // Get completed tasks
            $completed_sql = "SELECT COUNT(*) as completed FROM tbl_works WHERE assigned_to = ? AND status = 'completed'";
            $completed_stmt = $conn->prepare($completed_sql);
            $completed_stmt->bind_param("i", $worker_id);
            $completed_stmt->execute();
            $completed_result = $completed_stmt->get_result()->fetch_assoc();
            
            // Get overdue tasks (not completed and past due date)
            $current_date = date('Y-m-d H:i:s');
            $overdue_sql = "SELECT COUNT(*) as overdue FROM tbl_works 
                           WHERE assigned_to = ? 
                           AND status != 'completed' 
                           AND due_date < ?";
            $overdue_stmt = $conn->prepare($overdue_sql);
            $overdue_stmt->bind_param("is", $worker_id, $current_date);
            $overdue_stmt->execute();
            $overdue_result = $overdue_stmt->get_result()->fetch_assoc();
            
            // Calculate values
            $total = $total_result['total'];
            $completed = $completed_result['completed'];
            $overdue = $overdue_result['overdue'];
            $pending = $total - $completed;
            
            $response['success'] = true;
            $response['overview'] = array(
                'total' => strval($total),
                'completed' => strval($completed),
                'pending' => strval($pending),
                'overdue' => strval($overdue)
            );
            
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