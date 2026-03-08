<?php

namespace App\Core;

use Closure;

class Router
{
    private array $routes = [];
    private array $globalMiddlewares = [];

    /**
     * Add a route
     */
    public function add(string $method, string $path, callable|array $handler, array $middlewares = []): void
    {
        $this->routes[] = [
            'method'      => strtoupper($method),
            'path'        => $path,
            'handler'     => $handler,
            'middlewares' => $middlewares
        ];
    }

    /**
     * Convenience methods
     */
    public function get(string $path, callable|array $handler, array $middlewares = []): void
    {
        $this->add('GET', $path, $handler, $middlewares);
    }

    public function post(string $path, callable|array $handler, array $middlewares = []): void
    {
        $this->add('POST', $path, $handler, $middlewares);
    }

    public function put(string $path, callable|array $handler, array $middlewares = []): void
    {
        $this->add('PUT', $path, $handler, $middlewares);
    }

    public function patch(string $path, callable|array $handler, array $middlewares = []): void
    {
        $this->add('PATCH', $path, $handler, $middlewares);
    }

    public function delete(string $path, callable|array $handler, array $middlewares = []): void
    {
        $this->add('DELETE', $path, $handler, $middlewares);
    }

    /**
     * Group routes with common prefix and/or middlewares
     */
    public function group(array $options, Closure $callback): void
    {
        $previousPrefix = $this->currentPrefix ?? '';
        $previousMiddlewares = $this->globalMiddlewares;

        $this->currentPrefix = ($options['prefix'] ?? '') ? rtrim($previousPrefix . '/' . trim($options['prefix'], '/'), '/') : $previousPrefix;
        $this->globalMiddlewares = array_merge($this->globalMiddlewares, $options['middleware'] ?? []);

        $callback($this);

        // Restore state
        $this->currentPrefix = $previousPrefix;
        $this->globalMiddlewares = $previousMiddlewares;
    }

    /**
     * Dispatch the request
     */
    public function dispatch(): void
    {
        $uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
        $uri = '/' . trim($uri, '/');
        $method = $_SERVER['REQUEST_METHOD'];

        foreach ($this->routes as $route) {
            // Build pattern with prefix support
            $path = $this->currentPrefix ?? '';
            $fullPath = $path . $route['path'];
            $fullPath = '/' . trim($fullPath, '/');

            // Convert :param to regex
            $pattern = preg_replace('#/:([^/]+)#', '/(?P<$1>[^/]+)', $fullPath);
            $pattern = '@^' . $pattern . '$@';

            if ($route['method'] === $method && preg_match($pattern, $uri, $matches)) {
                // Extract named parameters
                $params = [];
                foreach ($matches as $key => $value) {
                    if (is_string($key)) {
                        $params[] = $value;
                    }
                }

                // Apply route-specific + global middlewares
                $allMiddlewares = array_merge($this->globalMiddlewares, $route['middlewares']);

                foreach ($allMiddlewares as $middleware) {
                    $mwInstance = is_string($middleware) ? new $middleware() : $middleware;
                    if (is_callable($mwInstance)) {
                        $result = $mwInstance();
                    } else {
                        $result = $mwInstance->handle();
                    }

                    if ($result !== true) {
                        echo $result;
                        return;
                    }
                }

                // Call handler
                $handler = $route['handler'];

                if (is_callable($handler)) {
                    call_user_func_array($handler, $params);
                } elseif (is_array($handler) && count($handler) === 2) {
                    [$controllerClass, $method] = $handler;
                    $controller = new $controllerClass();
                    call_user_func_array([$controller, $method], $params);
                } else {
                    http_response_code(500);
                    echo json_encode(['error' => 'Invalid handler']);
                }

                return;
            }
        }

        // 404 Not Found
        http_response_code(404);
        echo json_encode(['error' => 'Route not found', 'uri' => $uri, 'method' => $method]);
    }
}
