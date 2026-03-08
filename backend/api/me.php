<?php
// api/me.php

header('Content-Type: application/json');
require_once __DIR__ . '/../vendor/autoload.php';

use App\Core\Auth;
use App\Models\User;

$currentUser = Auth::user();
if (!$currentUser) {
    http_response_code(401);
    echo json_encode(['error' => 'Unauthorized']);
    exit;
}

$userModel = new User();
$user = $userModel->find($currentUser['user_id']);
unset($user['password']);

echo json_encode([
    'user' => $user
]);
