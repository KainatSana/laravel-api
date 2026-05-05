<?php
header('Content-Type: application/json');
echo json_encode([
    'status' => 'healthy',
    'environment' => getenv('APP_ENV') ?: 'unknown',
    'timestamp' => date('c'),
]);
