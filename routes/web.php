<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

// Add this test route
Route::get('/test', function () {
    return response()->json([
        'status' => 'success',
        'message' => 'Laravel is working!',
        'version' => app()->version(),
        'environment' => app()->environment(),
        'timestamp' => now()->toDateTimeString(),
    ]);
});

// Health check route for ALB
Route::get('/health', function () {
    return response()->json(['status' => 'healthy'], 200);
});