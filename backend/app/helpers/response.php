<?php

if (!function_exists('response')) {
    /**
     * Send an HTTP response and terminate script execution.
     *
     * @param string|array $content    The response body (string or array – will be JSON-encoded if array)
     * @param int          $status     HTTP status code (default: 200)
     * @param array        $headers    Additional headers to send
     *
     * @return never Returns nothing – calls exit after sending response
     */
    function response(mixed $content, int $status = 200, array $headers = []): void
    {
        // Set HTTP status code
        http_response_code($status);

        // Default JSON header if not provided
        if (!isset($headers['Content-Type'])) {
            $headers['Content-Type'] = 'application/json; charset=utf-8';
        }

        // Send custom headers
        foreach ($headers as $key => $value) {
            header("$key: $value");
        }

        // Handle different content types
        if (is_array($content) || is_object($content)) {
            $jsonOptions = JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES;
            if (getenv('APP_DEBUG') === 'true') {
                $jsonOptions |= JSON_PRETTY_PRINT;
            }
            echo json_encode($content, $jsonOptions);
        } else {
            echo $content;
        }

        // Prevent any further output
        exit;
    }
}
