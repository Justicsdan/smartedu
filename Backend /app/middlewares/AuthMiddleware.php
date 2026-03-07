<?php

namespace App\Middlewares;

use App\Core\Auth;
// Assuming 'response' is a helper function (like json_response) or a class. 
// If using the helper function from 'functions.php', no 'use' statement is needed for it.

class AuthMiddleware
{
    public function handle()
    {
        // Validate the token (Assumes Auth::validate returns array or false)
        $payload = Auth::validate();

        if (!$payload) {
            return response(
                json_encode(['error' => 'Unauthorized: Invalid or missing token']),
                401,
                ['Content-Type' => 'application/json']
            );
        }

        // Ensure payload has necessary data
        if (!isset($payload['user_id']) || !isset($payload['role'])) {
            return response(
                json_encode(['error' => 'Unauthorized: Malformed token payload']),
                401,
                ['Content-Type' => 'application/json']
            );
        }

        // Inject authenticated user payload into server globals for controllers
        // This allows controllers to access user data via $_SERVER['user_id']
        $_SERVER['user'] = (array) $payload;
        $_SERVER['user_id'] = $payload['user_id'];

        // Inject school_id only if the user is NOT a superadmin
        // Superadmins likely access/manage data across all schools
        if ($payload['role'] !== 'superadmin') {
            $_SERVER['school_id'] = $payload['school_id'] ?? null;
        }

        return true; // Allow request to continue to the controller
    }
}
