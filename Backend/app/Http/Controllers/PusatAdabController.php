<?php

namespace App\Http\Controllers;

class PusatAdabController extends Controller
{
    public function profile()
    {
        return response()->json([
            'success' => true,
            'data' => null
        ], 200);
    }
}