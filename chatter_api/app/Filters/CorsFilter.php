<?php

namespace App\Filters;

use CodeIgniter\Filters\FilterInterface;
use CodeIgniter\HTTP\RequestInterface;
use CodeIgniter\HTTP\ResponseInterface;

/**
 * CorsFilter — must run on EVERY route including public ones.
 * Handles OPTIONS pre-flight and adds CORS headers to all responses.
 */
class CorsFilter implements FilterInterface
{
    private array $allowedOrigins = ['*']; // Change to specific origins in production

    public function before(RequestInterface $request, $arguments = null)
    {
        // Handle OPTIONS pre-flight immediately — no further processing needed
        if ($request->getMethod() === 'options') {
            return service('response')
                ->setStatusCode(200)
                ->setHeader('Access-Control-Allow-Origin', '*')
                ->setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With, Accept')
                ->setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS')
                ->setHeader('Access-Control-Max-Age', '86400')
                ->setHeader('Content-Length', '0')
                ->setBody('');
        }
    }

    public function after(RequestInterface $request, ResponseInterface $response, $arguments = null)
    {
        $response
            ->setHeader('Access-Control-Allow-Origin', '*')
            ->setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With, Accept')
            ->setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS')
            ->setHeader('Access-Control-Expose-Headers', 'Authorization');
    }
}
