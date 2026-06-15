<?php

namespace App\Http\Controllers;

use App\Models\Student;
use App\Models\TuitionFee;
use App\Models\PaymentTransaction;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class TuitionFeesController extends Controller
{
    // Retrieve the tuition fee record for the currently authenticated student
    public function show()
    {
        try {
            $user = Auth::user();
            if (!$user) {
                return response()->json(['success' => false, 'message' => 'Unauthenticated'], 401);
            }

            $student = Student::where('User_ID', $user->User_ID)->first();
            if (!$student) {
                return response()->json(['success' => false, 'message' => 'Student profile not found'], 404);
            }

            $tuitionFee = TuitionFee::where('Student_ID', $student->Student_ID)->first();
            if (!$tuitionFee) {
                // If not found, create a default one for the prototype
                $tuitionFee = TuitionFee::create([
                    'Student_ID' => $student->Student_ID,
                    'Total_Invoice' => 1500.00,
                    'Balance' => 1500.00,
                    'Payment_Status' => 'Unpaid',
                    'Academic_Access' => 'Active',
                ]);
            }

            return response()->json(['success' => true, 'data' => $tuitionFee], 200);

        } catch (\Exception $e) {
            return response()->json(['success' => false, 'message' => 'Failed to load tuition fee data: ' . $e->getMessage()], 500);
        }
    }

    // Process the FPX payment via ToyyibPay
    public function pay(Request $request)
    {
        try {
            $request->validate([
                'TuitionFee_ID' => 'required|integer',
                'Student_ID' => 'required|string|max:10',
                'Amount_Paid' => 'required|numeric|min:0.01',
                'Bank_Name' => 'required|string|max:100',
                'Remarks' => 'nullable|string'
            ]);

            $tuitionFee = TuitionFee::findOrFail($request->TuitionFee_ID);

            if ($tuitionFee->Student_ID !== $request->Student_ID) {
                return response()->json(['success' => false, 'message' => 'Invalid Student ID for this fee record'], 403);
            }

            // ToyyibPay Configuration
            $secretKey = config('services.toyyibpay.secret_key');
            $categoryCode = config('services.toyyibpay.category_code');
            $url = config('services.toyyibpay.url');

            // Amount must be in cents (RM 1 = 100)
            $amountInCents = intval(round($request->Amount_Paid * 100));

            // Create Bill on ToyyibPay
            $response = \Illuminate\Support\Facades\Http::asForm()->post($url . '/index.php/api/createBill', [
                'userSecretKey' => $secretKey,
                'categoryCode' => $categoryCode,
                'billName' => 'Tuition Fee Payment',
                'billDescription' => 'Payment for Student ID: ' . $request->Student_ID,
                'billPriceSetting' => 1,
                'billPayorInfo' => 0,
                'billAmount' => $amountInCents,
                'billReturnUrl' => 'http://10.0.2.2:8000/api/toyyibpay-return', // Redirects emulator browser to Laravel
                'billCallbackUrl' => url('/api/toyyibpay-callback'),
                'billExternalReferenceNo' => $request->TuitionFee_ID, // Use this to track which fee
                'billTo' => $request->Student_ID,
                'billEmail' => 'student@umpsa.edu.my',
                'billPhone' => '0123456789',
            ]);

            $result = $response->json();

            if (isset($result[0]['BillCode'])) {
                $billCode = $result[0]['BillCode'];

                // Create a pending transaction record
                $transaction = PaymentTransaction::create([
                    'TuitionFee_ID' => $tuitionFee->TuitionFee_ID,
                    'Student_ID' => $request->Student_ID,
                    'Amount_Paid' => $request->Amount_Paid,
                    'Payment_Method' => 'FPX (ToyyibPay)',
                    'Bank_Name' => $request->Bank_Name,
                    'Remarks' => $billCode, // Store BillCode here for tracking
                    'Transaction_Status' => 'Pending'
                ]);

                // Return the payment URL to the Flutter app
                $paymentUrl = $url . '/' . $billCode;

                return response()->json([
                    'success' => true, 
                    'message' => 'Bill Created Successfully!', 
                    'data' => [
                        'payment_url' => $paymentUrl,
                        'bill_code' => $billCode,
                        'transaction_id' => $transaction->Transaction_ID
                    ]
                ], 201);
            } else {
                return response()->json(['success' => false, 'message' => 'Failed to create ToyyibPay bill.'], 500);
            }

        } catch (\Exception $e) {
            return response()->json(['success' => false, 'message' => 'ToyyibPay Server Unavailable: ' . $e->getMessage()], 500);
        }
    }

    // ToyyibPay Browser Return URL (Works on Emulator Localhost!)
    public function paymentReturn(Request $request)
    {
        if ($request->status_id == 1) {
            $billCode = $request->billcode;

            DB::beginTransaction();
            try {
                $transaction = PaymentTransaction::where('Remarks', $billCode)->first();
                if ($transaction && $transaction->Transaction_Status === 'Pending') {
                    $transaction->Transaction_Status = 'Success';
                    $transaction->save();

                    $tuitionFee = TuitionFee::findOrFail($transaction->TuitionFee_ID);
                    $newBalance = max(0, $tuitionFee->Balance - $transaction->Amount_Paid);
                    
                    $tuitionFee->Balance = $newBalance;
                    if ($newBalance == 0) {
                        $tuitionFee->Payment_Status = 'Paid';
                        $tuitionFee->Academic_Access = 'Active';
                    }
                    $tuitionFee->save();
                    DB::commit();
                }
            } catch (\Exception $e) {
                DB::rollBack();
                return response('<h1 style="color:red; text-align:center; margin-top:50px;">Database Error!</h1>', 500);
            }

            return response('
                <div style="text-align: center; margin-top: 50px; font-family: sans-serif;">
                    <h1 style="color: green;">Payment Successful! ✅</h1>
                    <p>Your payment has been successfully recorded in the database.</p>
                    <p style="font-weight: bold; font-size: 18px;">You can now close this browser and return to the Flutter app!</p>
                </div>
            ', 200)->header('Content-Type', 'text/html');
        }

        return response('<h1 style="color:red; text-align:center; margin-top:50px;">Payment Failed or Canceled ❌</h1>', 400);
    }

    // Verify Payment Manually from Flutter App
    public function verifyPayment(Request $request)
    {
        $request->validate(['billCode' => 'required|string']);
        $billCode = $request->billCode;

        $transaction = PaymentTransaction::where('Remarks', $billCode)->first();
        if (!$transaction) return response()->json(['success' => false, 'message' => 'Transaction not found']);

        if ($transaction->Transaction_Status === 'Success') {
            return response()->json(['success' => true, 'message' => 'Already Paid']);
        }

        $url = config('services.toyyibpay.url');
        $response = \Illuminate\Support\Facades\Http::asForm()->post($url . '/index.php/api/getBillTransactions', [
            'billCode' => $billCode
        ]);

        $result = $response->json();
        $isPaid = false;
        if (is_array($result)) {
            foreach ($result as $txn) {
                if ($txn['billpaymentStatus'] == '1') {
                    $isPaid = true;
                    break;
                }
            }
        }

        if ($isPaid) {
            DB::beginTransaction();
            try {
                $transaction->Transaction_Status = 'Success';
                $transaction->save();

                $tuitionFee = TuitionFee::findOrFail($transaction->TuitionFee_ID);
                $newBalance = max(0, $tuitionFee->Balance - $transaction->Amount_Paid);
                $tuitionFee->Balance = $newBalance;
                if ($newBalance == 0) {
                    $tuitionFee->Payment_Status = 'Paid';
                    $tuitionFee->Academic_Access = 'Active';
                }
                $tuitionFee->save();
                DB::commit();

                return response()->json(['success' => true, 'message' => 'Payment Verified Successfully!']);
            } catch (\Exception $e) {
                DB::rollBack();
                return response()->json(['success' => false, 'message' => 'Database error']);
            }
        }

        return response()->json(['success' => false, 'message' => 'Payment not yet completed']);
    }

    // ToyyibPay Webhook Callback (For Production)
    public function paymentCallback(Request $request)
    {
        // ToyyibPay sends status=1 for success
        if ($request->status_id == 1) {
            $billCode = $request->billcode;

            DB::beginTransaction();
            try {
                // Find the pending transaction
                $transaction = PaymentTransaction::where('Remarks', $billCode)->first();
                if ($transaction && $transaction->Transaction_Status === 'Pending') {
                    $transaction->Transaction_Status = 'Success';
                    $transaction->save();

                    // Update Tuition Fee Balance
                    $tuitionFee = TuitionFee::findOrFail($transaction->TuitionFee_ID);
                    $newBalance = max(0, $tuitionFee->Balance - $transaction->Amount_Paid);
                    
                    $tuitionFee->Balance = $newBalance;
                    if ($newBalance == 0) {
                        $tuitionFee->Payment_Status = 'Paid';
                        $tuitionFee->Academic_Access = 'Active';
                    }
                    $tuitionFee->save();

                    DB::commit();
                    return response('OK', 200);
                }
            } catch (\Exception $e) {
                DB::rollBack();
                return response('Error', 500);
            }
        }
        return response('Failed', 400);
    }
}
