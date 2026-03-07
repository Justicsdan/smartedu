<?php

namespace App\Core;

use Firebase\JWT\JWT;
use Firebase\JWT\Key;
use Firebase\JWT\ExpiredException;
use Firebase\JWT\SignatureInvalidException;
use Firebase\JWT\BeforeValidException;

class Auth
{
    private static $secret;
    private static $algo;
    private static $issuer;
    private static $expire;

    /**
     * Initialize config once
     */
    public static function init()
    {
        if (self::$secret !== null) {
            return; // Already initialized
        }

        $config = require __DIR__ . '/../../config/app.php';

        self::$secret = $config['jwt_secret'] ?? 'fallback-secret-change-in-production';
        self::$algo   = $config['jwt_algo'] ?? 'HS256';
        self::$issuer = $config['url'] ?? 'https://yourdomain.com';
        self::$expire = $config['jwt_expire'] ?? 3600; // 1 hour default
    }

    /**
     * Issue a new JWT token for a user
     */
    public static function issue(array $user): string
    {
        self::init();

        $now = time();

        $payload = [
            'iss' => self::$issuer,
            'iat' => $now,
            'exp' => $now + self::$expire,
            'sub' => $user['id'],
            'user_id' => $user['id'],
            'role'    => $user['role'],
            'name'    => $user['name'] ?? '',
            'email'   => $user['email'] ?? ''
        ];

        // Add school_id only if not super_admin
        if ($user['role'] !== 'super_admin' && !empty($user['school_id'])) {
            $payload['school_id'] = (int)$user['school_id'];
        }

        return JWT::encode($payload, self::$secret, self::$algo);
    }

    /**
     * Validate token from Authorization header and return decoded payload
     */
    public static function validate(): ?array
    {
        self::init();

        $headers = function_exists('apache_request_headers')
            ? apache_request_headers()
            : self::getHeadersFallback();

        $authHeader = $headers['Authorization'] ?? $headers['authorization'] ?? null;

        if (!$authHeader || !str_starts_with($authHeader, 'Bearer ')) {
            return null;
        }

        $token = substr($authHeader, 7); // Remove "Bearer "

        try {
            $decoded = JWT::decode($token, new Key(self::$secret, self::$algo));
            return (array) $decoded;
        } catch (ExpiredException $e) {
            error_log('JWT Expired: ' . $e->getMessage());
        } catch (SignatureInvalidException $e) {
            error_log('Invalid JWT Signature: ' . $e->getMessage());
        } catch (BeforeValidException $e) {
            error_log('JWT Used Before Valid: ' . $e->getMessage());
        } catch (\Exception $e) {
            error_log('JWT Validation Error: ' . $e->getMessage());
        }

        return null;
    }

    /**
     * Get current authenticated user payload (cached in request)
     */
    public static function user(): ?array
    {
        static $user = null;

        if ($user === null) {
            $user = self::validate();
        }

        return $user;
    }

    /**
     * Convenience helpers
     */
    public static function id(): ?int
    {
        $user = self::user();
        return $user['user_id'] ?? null;
    }

    public static function role(): ?string
    {
        $user = self::user();
        return $user['role'] ?? null;
    }

    public static function schoolId(): ?int
    {
        $user = self::user();
        return $user['school_id'] ?? null;
    }

    public static function isSuperAdmin(): bool
    {
        return self::role() === 'super_admin';
    }

    public static function isAdmin(): bool
    {
        return self::role() === 'admin';
    }

    public static function isTeacher(): bool
    {
        return self::role() === 'teacher';
    }

    public static function isStudent(): bool
    {
        return self::role() === 'student';
    }

    /**
     * Fallback for getallheaders() when not available
     */
    private static function getHeadersFallback(): array
    {
        $headers = [];
        foreach ($_SERVER as $name => $value) {
            if (str_starts_with($name, 'HTTP_')) {
                $headers[str_replace(' ', '-', ucwords(strtolower(str_replace('_', ' ', substr($name, 5)))))] = $value;
            } elseif (in_array($name, ['CONTENT_TYPE', 'CONTENT_LENGTH'])) {
                $headers[ucwords(strtolower($name), '-')] = $value;
            }
        }
        return $headers;
    }
}
