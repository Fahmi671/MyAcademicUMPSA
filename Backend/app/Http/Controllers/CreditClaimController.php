<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class CreditClaimController extends Controller
{
    public function myClaims()
    {
        return response()->json([
            'success' => true,
            'data' => []
        ], 200);
    }

    public function store(Request $request)
    {
        return response()->json([
            'success' => true,
            'message' => 'Credit claim submitted successfully'
        ], 201);
    }

    public function pendingClaims()
    {
        return response()->json([
            'success' => true,
            'data' => []
        ], 200);
    }

    public function review(Request $request, $claim_id)
    {
        return response()->json([
            'success' => true,
            'message' => 'Credit claim reviewed successfully'
        ], 200);
    }
}