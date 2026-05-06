<?php

use Illuminate\Support\Facades\DB;
use Illuminate\Http\Request;

// Health check endpoint
Route::get('/health', function () {
    try {
        DB::connection()->getPdo();
        return response()->json([
            'status' => 'healthy',
            'environment' => env('APP_ENV'),
            'timestamp' => now()->toIso8601String(),
        ]);
    } catch (\Exception $e) {
        return response()->json([
            'status' => 'unhealthy',
            'error' => $e->getMessage(),
        ], 503);
    }
});

// Readiness check
Route::get('/ready', function () {
    try {
        DB::connection()->getPdo();
        return response()->json(['ready' => true]);
    } catch (\Exception $e) {
        return response()->json(['ready' => false], 503);
    }
});

// Simple API endpoints
Route::get('/v1/status', function () {
    return response()->json([
        'api' => 'running',
        'version' => '1.0.0',
        'environment' => env('APP_ENV'),
    ]);
});
