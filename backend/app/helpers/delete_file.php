<?php

if (!function_exists('delete_file')) {
    /**
     * Delete an old file when updating profile/logo
     */
    function delete_file(string $filePath): bool
    {
        if (empty($filePath) || !str_starts_with($filePath, '/uploads/')) {
            return false;
        }

        $fullPath = __DIR__ . '/../public' . $filePath;

        if (file_exists($fullPath) && is_file($fullPath)) {
            return unlink($fullPath);
        }

        return false;
    }
}
