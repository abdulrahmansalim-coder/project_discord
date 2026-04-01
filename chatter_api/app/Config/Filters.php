<?php

namespace Config;

use App\Filters\CorsFilter;
use App\Filters\JwtFilter;
use CodeIgniter\Config\BaseConfig;

class Filters extends BaseConfig
{
    public array $aliases = [
        'csrf'          => \CodeIgniter\Filters\CSRF::class,
        'toolbar'       => \CodeIgniter\Filters\DebugToolbar::class,
        'honeypot'      => \CodeIgniter\Filters\Honeypot::class,
        'invalidchars'  => \CodeIgniter\Filters\InvalidChars::class,
        'secureheaders' => \CodeIgniter\Filters\SecureHeaders::class,
        'jwt'           => JwtFilter::class,
        'cors'          => CorsFilter::class,
    ];

    // cors runs GLOBALLY on every single request (including public auth routes)
    public array $globals = [
        'before' => ['cors'],
        'after'  => ['cors'],
    ];

    public array $methods = [];
    public array $filters = [];
}
