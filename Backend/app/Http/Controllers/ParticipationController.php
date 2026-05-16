<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class ParticipationController extends Controller
{
    public function myParticipations()
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
            'message' => 'Participation registered successfully'
        ], 201);
    }

    public function destroy($participation_id)
    {
        return response()->json([
            'success' => true,
            'message' => 'Participation removed successfully'
        ], 200);
    }
}