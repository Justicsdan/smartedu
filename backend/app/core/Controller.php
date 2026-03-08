<?php

namespace App\Core;

use App\Helpers\response;

class Controller
{
    /**
     * Return a JSON response
     */
    protected function json(mixed $data, int $status = 200, array $headers = []): void
    {
        $defaultHeaders = ['Content-Type' => 'application/json; charset=utf-8'];

        $responseData = $data;

        // Always wrap non-array responses in a standard structure for consistency
        if (!is_array($data) || (!isset($data['data']) && !isset($data['message']) && !isset($data['error']))) {
            $responseData = ['data' => $data];
        }

        // Add timestamp and status for better API debugging
        if (getenv('APP_DEBUG') === 'true') {
            $responseData['_meta'] = [
                'timestamp' => date('c'),
                'status_code' => $status
            ];
        }

        response(
            json_encode($responseData, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES),
            $status,
            array_merge($defaultHeaders, $headers)
        );
    }

    /**
     * Return a standardized error response
     */
    protected function error(string|array $message, int $status = 400, array $headers = []): void
    {
        $errorPayload = [
            'error' => true,
            'message' => is_array($message) ? $message : (string) $message,
            'status_code' => $status
        ];

        // Include validation errors in structured format
        if (is_array($message) && isset($message['errors'])) {
            $errorPayload['errors'] = $message['errors'];
            unset($errorPayload['message']);
        }

        if (getenv('APP_DEBUG') === 'true') {
            $errorPayload['_meta'] = [
                'timestamp' => date('c'),
                'trace' => debug_backtrace(DEBUG_BACKTRACE_IGNORE_ARGS, 5)
            ];
        }

        response(
            json_encode($errorPayload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES),
            $status,
            array_merge(['Content-Type' => 'application/json; charset=utf-8'], $headers)
        );
    }

    /**
     * Return success response with message (common pattern)
     */
    protected function success(string $message = 'Success', mixed $data = null, int $status = 200): void
    {
        $payload = ['message' => $message];

        if ($data !== null) {
            $payload['data'] = $data;
        }

        $this->json($payload, $status);
    }

    /**
     * Return paginated response (standardized format)
     */
    protected function paginated(array $items, int $total, int $page, int $limit, mixed $extra = null): void
    {
        $payload = [
            'data' => $items,
            'pagination' => [
                'page' => $page,
                'limit' => $limit,
                'total' => $total,
                'pages' => (int) ceil($total / $limit),
                'has_more' => $page < ceil($total / $limit)
            ]
        ];

        if ($extra) {
            $payload['summary'] = $extra;
        }

        $this->json($payload);
    }

    /**
     * Return created resource (201) with location header (REST best practice)
     */
    protected function created(mixed $data, string $location = null): void
    {
        $headers = [];

        if ($location) {
            $headers['Location'] = $location;
        }

        $this->json(['message' => 'Resource created successfully', 'data' => $data], 201, $headers);
    }

    /**
     * Return no content (204) - useful for DELETE endpoints
     */
    protected function noContent(): void
    {
        response('', 204);
    }
}
