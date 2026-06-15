import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../Config/api.dart';
import '../../Domain/TuitionFee.dart';
import '../Homepage/StudentHomepage.dart'; // For AppColors and AppTextStyles

class StudentPayTuitionFees extends StatefulWidget {
  const StudentPayTuitionFees({super.key});

  @override
  State<StudentPayTuitionFees> createState() => _StudentPayTuitionFeesState();
}

class _StudentPayTuitionFeesState extends State<StudentPayTuitionFees> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  TuitionFee? _tuitionFee;
  
  final _remarksController = TextEditingController();
  String? _selectedBank;
  
  final List<String> _fpxBanks = [
    'Maybank2U',
    'CIMB Clicks',
    'Bank Islam',
    'RHB Now',
    'Public Bank',
    'AmBank'
  ];

  @override
  void initState() {
    super.initState();
    _fetchTuitionFee();
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _fetchTuitionFee() async {
    final result = await ApiService.getStudentTuitionFee();
    if (result['success'] && result['data'] != null) {
      setState(() {
        _tuitionFee = TuitionFee.fromJson(result['data']);
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to load details')),
        );
      }
    }
  }

  Future<void> _submitPayment() async {
    if (_selectedBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an FPX Bank first')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final payload = {
      'TuitionFee_ID': _tuitionFee?.tuitionFeeId,
      'Student_ID': _tuitionFee?.studentId,
      'Amount_Paid': _tuitionFee?.balance,
      'Payment_Method': 'FPX',
      'Bank_Name': _selectedBank,
      'Remarks': _remarksController.text,
    };

    final result = await ApiService.submitPayment(payload);

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (result['success']) {
        final paymentUrl = result['data']['payment_url'];
        final billCode = result['data']['bill_code'];
        if (paymentUrl != null) {
          final uri = Uri.parse(paymentUrl);
          try {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            _showSuccessDialog(billCode);
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not open payment gateway.')),
            );
          }
        } else {
          _showSuccessDialog(billCode); // Fallback
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Payment failed.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSuccessDialog(String billCode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Column(
          children: [
            Icon(Icons.open_in_browser, color: Colors.blue, size: 48),
            SizedBox(height: 16),
            Text('Browser Opened!', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Please complete your payment securely in the opened ToyyibPay browser tab. Once finished, you can return here and click verify.',
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () async {
                // Show a loading indicator
                showDialog(
                  context: ctx,
                  barrierDismissible: false,
                  builder: (loadingCtx) => const Center(child: CircularProgressIndicator()),
                );

                final verifyResult = await ApiService.verifyPayment(billCode);
                
                Navigator.pop(ctx); // pop loading dialog
                Navigator.pop(ctx); // pop browser dialog
                Navigator.pop(context); // pop screen to return to dashboard
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.appBarBackground,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Verify & Return to Dashboard'),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _showCancelDialog() async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.red, width: 2),
              ),
              child: const Icon(Icons.priority_high, color: Colors.red, size: 48),
            ),
            const SizedBox(height: 24),
            const Text(
              'Are you sure you want to\ncancel this transaction?',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.black87,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Yes'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.black87,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('No'),
                ),
              ],
            )
          ],
        ),
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _showCancelDialog,
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        appBar: AppBar(
          backgroundColor: AppColors.appBarBackground,
          iconTheme: const IconThemeData(color: AppColors.appBarIcon),
          title: const Text('Pay Tuition Fee', style: AppTextStyles.appBarTitle),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _showCancelDialog()) {
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.network(
                'https://myacademic.umpsa.edu.my/assets/images/logo_uitm.png', // Fallback
                width: 40,
                errorBuilder: (ctx, err, _) => const Icon(Icons.shield, color: Colors.white),
              ),
            )
          ],
        ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.appBarBackground))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPaymentSummaryCard(),
                  const SizedBox(height: 24),
                  _buildPaymentForm(),
                  const SizedBox(height: 32),
                  _isSubmitting
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ElevatedButton(
                              onPressed: _submitPayment,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1F3E8A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 4,
                              ),
                              child: const Text(
                                'CONFIRM PAYMENT',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () async {
                                if (await _showCancelDialog()) {
                                  if (context.mounted) Navigator.pop(context);
                                }
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text(
                                'CANCEL',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildPaymentSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text('Amount to Pay', style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            'RM ${_tuitionFee?.balance.toStringAsFixed(2) ?? "0.00"}',
            style: const TextStyle(color: Colors.black87, fontSize: 32, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Student ID', style: TextStyle(color: Colors.grey)),
              Text(_tuitionFee?.studentId ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select FPX Bank', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          hint: const Text('Choose your bank'),
          value: _selectedBank,
          items: _fpxBanks.map((bank) {
            return DropdownMenuItem(value: bank, child: Text(bank));
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedBank = val;
            });
          },
        ),
        const SizedBox(height: 24),
        const Text('Remarks (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        TextField(
          controller: _remarksController,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: 'e.g. Semester 2 payment',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          maxLines: 2,
        ),
      ],
    );
  }
}
