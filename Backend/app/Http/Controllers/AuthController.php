<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class AuthController extends Controller
{
    // Handle user login and issue access token.
    public function login(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'email'    => 'required|email',
                'password' => 'required|string|min:6',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation error',
                    'errors'  => $validator->errors(),
                ], 422);
            }

            $user = User::where('User_Email', $request->email)->first();

            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Invalid email or password',
                ], 401);
            }

            $passwordMatched = Hash::check($request->password, $user->User_Password);
            $plainTextMatched = !$passwordMatched && hash_equals((string) $user->User_Password, (string) $request->password);

            if (!$passwordMatched && !$plainTextMatched) {
                return response()->json([
                    'success' => false,
                    'message' => 'Invalid email or password',
                ], 401);
            }

            if ($plainTextMatched) {
                $user->User_Password = Hash::make($request->password);
                $user->save();
            }

            $token = $user->createToken('auth_token')->plainTextToken;

            return response()->json([
                'success' => true,
                'message' => 'Login successful',
                'data'    => [
                    'user_id'   => $user->User_ID,
                    'full_name' => $user->User_FullName,
                    'email'     => $user->User_Email,
                    'role'      => $user->User_Role,
                    'token'     => $token,
                ],
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Login failed: ' . $e->getMessage(),
            ], 500);
        }
    }

    // Revoke current access token for authenticated user.
    public function logout(Request $request)
    {
        try {
            $user = $request->user();

            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthenticated user',
                ], 401);
            }

            $token = $user->currentAccessToken();
            if ($token) {
                $token->delete();
            }

            return response()->json([
                'success' => true,
                'message' => 'Logout successful',
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Logout failed: ' . $e->getMessage(),
            ], 500);
        }
    }

    // Return authenticated user profile data.
    public function currentUser(Request $request)
    {
        try {
            $user = $request->user();

            return response()->json([
                'success' => true,
                'data'    => [
                    'user_id'   => $user->User_ID,
                    'full_name' => $user->User_FullName,
                    'email'     => $user->User_Email,
                    'role'      => $user->User_Role,
                    'phone'     => $user->User_PhoneNumber,
                ],
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch user: ' . $e->getMessage(),
            ], 500);
        }
    }
}