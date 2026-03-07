<?php

namespace App\Controllers;

use App\Core\Controller;
use App\Models\User;
use App\Helpers\upload_file;
use App\Helpers\delete_file;

class ProfileController extends Controller
{
    private $userModel;

    public function __construct()
    {
        $this->userModel = new User();
    }

    /**
     * Update authenticated user's profile photo
     */
    public function updatePhoto()
    {
        $currentUser = $_SERVER['user'] ?? null;

        if (!$currentUser || !isset($currentUser['user_id'])) {
            return $this->error('Unauthorized', 401);
        }

        $userId = $currentUser['user_id'];

        // Check if file was actually uploaded
        if (!isset($_FILES['profile_photo']) || $_FILES['profile_photo']['error'] === UPLOAD_ERR_NO_FILE) {
            return $this->error('No file uploaded', 400);
        }

        if ($_FILES['profile_photo']['error'] !== UPLOAD_ERR_OK) {
            $uploadErrors = [
                UPLOAD_ERR_INI_SIZE   => 'File exceeds upload_max_filesize',
                UPLOAD_ERR_FORM_SIZE  => 'File exceeds MAX_FILE_SIZE',
                UPLOAD_ERR_PARTIAL    => 'File only partially uploaded',
                UPLOAD_ERR_NO_TMP_DIR => 'Missing temporary folder',
                UPLOAD_ERR_CANT_WRITE => 'Failed to write file to disk',
                UPLOAD_ERR_EXTENSION  => 'File upload stopped by extension',
            ];

            $message = $uploadErrors[$_FILES['profile_photo']['error']] ?? 'Unknown upload error';
            return $this->error($message, 400);
        }

        // Enforce allowed file types and size (adjust as needed)
        $allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp'];
        $maxSize = 5 * 1024 * 1024; // 5MB

        $fileType = $_FILES['profile_photo']['type'];
        $fileSize = $_FILES['profile_photo']['size'];

        if (!in_array($fileType, $allowedTypes)) {
            return $this->error('Invalid file type. Only JPG, PNG, GIF, WebP allowed.', 400);
        }

        if ($fileSize > $maxSize) {
            return $this->error('File too large. Maximum 5MB allowed.', 400);
        }

        // Use secure upload helper
        $upload = upload_file('profile_photo', 'profiles', $allowedTypes);

        if (!$upload['success']) {
            return $this->error($upload['error'] ?? 'Upload failed', 400);
        }

        // Get current user to delete old photo
        $user = $this->userModel->find($userId);

        if (!$user) {
            // If user not found, still delete uploaded file to avoid orphan
            delete_file($upload['path']);
            return $this->error('User not found', 404);
        }

        $oldPhoto = $user['profile_photo'] ?? null;

        // Update database with new photo path
        $updated = $this->userModel->update($userId, [
            'profile_photo' => $upload['path']
        ]);

        if (!$updated) {
            // Rollback: delete newly uploaded file if DB update failed
            delete_file($upload['path']);
            return $this->error('Failed to update profile photo in database', 500);
        }

        // Delete old photo only after successful update
        if ($oldPhoto && file_exists($_SERVER['DOCUMENT_ROOT'] . $oldPhoto)) {
            delete_file($oldPhoto);
        }

        // Return full URL for frontend use
        $fullUrl = get_base_url() . $upload['path'];

        return $this->json([
            'message'        => 'Profile photo updated successfully',
            'profile_photo'  => $upload['path'],     // relative path (for storage)
            'photo_url'      => $fullUrl             // full URL for display
        ]);
    }

    /**
     * Update basic profile info (name, phone, etc.)
     */
    public function updateProfile()
    {
        $currentUser = $_SERVER['user'] ?? null;

        if (!$currentUser || !isset($currentUser['user_id'])) {
            return $this->error('Unauthorized', 401);
        }

        $userId = $currentUser['user_id'];

        $input = json_decode(file_get_contents('php://input'), true);

        if (empty($input)) {
            return $this->error('No data provided', 400);
        }

        // Define allowed fields
        $allowedFields = ['name', 'phone', 'bio', 'address'];
        $updateData = [];

        foreach ($allowedFields as $field) {
            if (isset($input[$field])) {
                $updateData[$field] = trim($input[$field]);
            }
        }

        if (empty($updateData)) {
            return $this->error('No valid fields to update', 400);
        }

        // Optional: Add validation rules per field
        if (isset($updateData['phone']) && !empty($updateData['phone'])) {
            if (!preg_match('/^\+?[0-9\s\-\(\)]+$/', $updateData['phone'])) {
                return $this->error('Invalid phone number', 422);
            }
        }

        $updated = $this->userModel->update($userId, $updateData);

        if (!$updated) {
            return $this->error('Failed to update profile', 500);
        }

        $updatedUser = $this->userModel->find($userId);
        unset($updatedUser['password']);

        return $this->json([
            'message' => 'Profile updated successfully',
            'user'    => $updatedUser
        ]);
    }

    /**
     * Get current user's profile (for frontend display)
     */
    public function getProfile()
    {
        $currentUser = $_SERVER['user'] ?? null;

        if (!$currentUser || !isset($currentUser['user_id'])) {
            return $this->error('Unauthorized', 401);
        }

        $userId = $currentUser['user_id'];

        $user = $this->userModel->find($userId);

        if (!$user) {
            return $this->error('User not found', 404);
        }

        unset($user['password']);

        // Add full photo URL
        if (!empty($user['profile_photo'])) {
            $user['photo_url'] = get_base_url() . $user['profile_photo'];
        }

        return $this->json([
            'message' => 'Profile retrieved successfully',
            'user'    => $user
        ]);
    }
}
