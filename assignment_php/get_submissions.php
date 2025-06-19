<?php
header('Content-Type: application/json');
include_once("db_config.php");

$response = array('success' => false);

if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_POST['worker_id'])) {
    try {
        $stmt = $conn->prepare(
            "SELECT 
                s.id, 
                w.title as work_title,
                w.description as work_description, 
                s.submission_text, 
                s.created_at as submission_date,
                w.due_date,
                w.completion_date,
                w.status
            FROM tbl_submissions s 
            JOIN tbl_works w ON s.work_id = w.id 
            WHERE s.worker_id = ? 
            ORDER BY s.created_at DESC"
        );
        
        $stmt->bind_param("i", $_POST['worker_id']);
        $stmt->execute();
        $result = $stmt->get_result();
        
        $submissions = array();
        while ($row = $result->fetch_assoc()) {
            $submissions[] = $row;
        }
        
        $response['success'] = true;
        $response['submissions'] = $submissions;
        
    } catch (Exception $e) {
        $response['message'] = $e->getMessage();
    }
} else {
    $response['message'] = 'Invalid request';
}

echo json_encode($response);
$conn->close();