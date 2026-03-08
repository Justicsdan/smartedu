<?php
// api/login.php

header('Content-Type: application/json');
require_once __DIR__ . '/../vendor/autoload.php';

use App\Models\User;
use App\Core\Auth;

$input = json_decode(file_get_contents('php://input'), true);

if (empty($input['email']) || empty($input['password'])) {
    http_response_code(400);
    echo json_encode(['error' => 'Email and password required']);
    exit;
}

$userModel = new User();
$result = $userModel->attemptLogin($input['email'], $input['password']);

if (!$result['success']) {
    http_response_code(401);
    echo json_encode(['error' => $result['message']]);
    exit;
}

echo json_encode([
    'message' => $result['message'],
    'token'   => $result['token'],
    'user'    => $result['user']
]);
