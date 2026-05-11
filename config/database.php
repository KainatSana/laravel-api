<?php

return [
    'default' => env('DB_CONNECTION', 'pgsql'),
    'connections' => [
        'pgsql' => [
            'driver' => 'pgsql',
            'host' => env('DB_HOST', '/cloudsql/watchful-force-495414-t4:us-east4:pitcrew-db-dev'),
            'port' => env('DB_PORT', 5432),
            'database' => env('DB_DATABASE', 'pitcrew_db'),
            'username' => env('DB_USERNAME', 'postgres'),
            'password' => env('DB_PASSWORD', ''),
            'charset' => 'utf8',
            'prefix' => '',
            'schema' => 'public',
            'sslmode' => env('DB_SSLMODE', 'prefer'),
        ],
    ],
    'migrations' => 'migrations',
];
