<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\DB;

// Health check - root level (not under /api prefix)
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
