<?php

use CodeIgniter\Router\RouteCollection;

/** @var RouteCollection $routes */

// CORS pre-flight
$routes->options('(:any)', static function () {
    return service('response')
        ->setStatusCode(200)
        ->setHeader('Access-Control-Allow-Origin', '*')
        ->setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With')
        ->setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
});

// ── Public image serving (no auth needed, CORS applied via CorsFilter) ────────
$routes->get('api/v1/image/(:segment)', 'UploadController::serve/$1');

// ── Auth (public) ──────────────────────────────────────────────────────────────
$routes->group('api/v1/auth', function ($routes) {
    $routes->post('register', 'AuthController::register');
    $routes->post('login',    'AuthController::login');
    $routes->post('refresh',  'AuthController::refresh');
});

// ── Protected routes ───────────────────────────────────────────────────────────
$routes->group('api/v1', ['filter' => 'jwt'], function ($routes) {

    // Auth
    $routes->post('auth/logout', 'AuthController::logout');

    // Upload
    $routes->post('upload/image', 'UploadController::image');

    // Users
    $routes->get('users/me',        'UserController::me');
    $routes->put('users/me',        'UserController::updateProfile');
    $routes->put('users/me/status', 'UserController::updateStatus');
    $routes->get('users/search',    'UserController::search');
    $routes->get('users/(:num)',    'UserController::show/$1');

    // Contacts
    $routes->get('contacts',                 'ContactController::index');
    $routes->get('contacts/requests',        'ContactController::requests');
    $routes->post('contacts',                'ContactController::sendRequest');
    $routes->put('contacts/(:num)/accept',   'ContactController::accept/$1');
    $routes->delete('contacts/(:num)',       'ContactController::destroy/$1');
    $routes->put('contacts/(:num)/block',    'ContactController::block/$1');

    // Conversations
    $routes->get('conversations',              'ConversationController::index');
    $routes->post('conversations',             'ConversationController::create');
    $routes->get('conversations/(:num)',       'ConversationController::show/$1');
    $routes->put('conversations/(:num)',       'ConversationController::update/$1');
    $routes->delete('conversations/(:num)',    'ConversationController::destroy/$1');
    $routes->post('conversations/direct',     'ConversationController::getOrCreateDirect');

    // Messages
    $routes->get('conversations/(:num)/messages',  'MessageController::index/$1');
    $routes->post('conversations/(:num)/messages', 'MessageController::send/$1');
    $routes->put('messages/(:num)',                'MessageController::update/$1');
    $routes->delete('messages/(:num)',             'MessageController::destroy/$1');
    $routes->post('messages/(:num)/read',          'MessageController::markRead/$1');
    $routes->post('conversations/(:num)/read-all', 'MessageController::markAllRead/$1');

    // Stories
    $routes->get('stories',              'StoryController::index');
    $routes->post('stories',             'StoryController::create');
    $routes->delete('stories/(:num)',    'StoryController::destroy/$1');
    $routes->post('stories/(:num)/view', 'StoryController::markViewed/$1');
});
