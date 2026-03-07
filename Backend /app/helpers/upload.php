<?php

if (!function_exists('upload_file')) {
    /**
     * Secure file upload helper
     */
    function upload_file(
        string $fieldName,
        string $targetDir = 'profiles',
        array $allowedTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'],
        int $maxSize = 5 * 1024 * 1024 // 5MB
    ): array {
        if (!isset($_FILES[$fieldName]) || $_FILES[$fieldName]['error'] === UPLOAD_ERR_NO_FILE) {
            return ['success' => false, 'error' => 'No file uploaded'];
        }

        $file = $_FILES[$fieldName];

        if ($file['error'] !== UPLOAD_ERR_OK) {
            $errors = [
                UPLOAD_ERR_INI_SIZE   => 'File exceeds upload_max_filesize',
                UPLOAD_ERR_FORM_SIZE  => 'File exceeds form MAX_FILE_SIZE',
                UPLOAD_ERR_PARTIAL    => 'File only partially uploaded',
                UPLOAD_ERR_NO_TMP_DIR => 'Missing temporary folder',
                UPLOAD_ERR_CANT_WRITE => 'Failed to write file',
                UPLOAD_ERR_EXTENSION  => 'File upload stopped by extension',
            ];
            return ['success' => false, 'error' => $errors[$file['error']] ?? 'Upload error'];
        }

        if ($file['size'] > $maxSize) {
            return ['success' => false, 'error' => 'File too large (max ' . ($maxSize / 1024 / 1024) . 'MB)'];
        }

        // Check fileinfo extension exists
        if (!function_exists('finfo_open')) {
            return ['success' => false, 'error' => 'Server does not support fileinfo extension'];
        }

        $finfo = finfo_open(FILEINFO_MIME_TYPE);
        $mime = finfo_file($finfo, $file['tmp_name']);
        finfo_close($finfo);

        if (!in_array($mime, $allowedTypes, true)) {
            return ['success' => false, 'error' => 'Invalid file type. Allowed: JPEG, PNG, GIF, WebP'];
        }

        // Map MIME type to secure extension (Prevents extension spoofing)
        $mimeExtensionMap = [
            'image/jpeg' => 'jpg',
            'image/png'  => 'png',
            'image/gif'  => 'gif',
            'image/webp' => 'webp'
        ];

        $ext = '.' . ($mimeExtensionMap[$mime] ?? 'bin'); 

        // Define target directory
        $baseDir = __DIR__ . '/../public/uploads/' . $targetDir;
        if (!is_dir($baseDir)) {
            mkdir($baseDir, 0755, true);
        }

        $filename = uniqid('upload_', true) . $ext;
        $filepath = $baseDir . '/' . $filename;

        if (!move_uploaded_file($file['tmp_name'], $filepath)) {
            return ['success' => false, 'error' => 'Failed to save file'];
        }

        return ['success' => true, 'path' => '/uploads/' . $targetDir . '/' . $filename];
    }
}
