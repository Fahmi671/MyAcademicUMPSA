import 'package:flutter/material.dart';
import '../../Config/api.dart';
import '../../Domain/TuitionFee.dart';
import '../Homepage/StudentHomepage.dart'; // For AppColors and AppTextStyles

class StudentTuitionFees extends StatefulWidget {
  const StudentTuitionFees({super.key});

  @override
  State<StudentTuitionFees> createState() => _StudentTuitionFeesState();
}

class _StudentTuitionFeesState extends State<StudentTuitionFees> {
  bool _isLoading = true;
  TuitionFee? _tuitionFee;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchTuitionFee();
  }

  Future<void> _fetchTuitionFee() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final result = await ApiService.getStudentTuitionFee();
    if (result['success'] && result['data'] != null) {
      setState(() {
        _tuitionFee = TuitionFee.fromJson(result['data']);
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'Failed to load tuition fee details.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.appBarBackground,
        iconTheme: const IconThemeData(color: AppColors.appBarIcon),
        title: const Text('Tuition Fees', style: AppTextStyles.appBarTitle),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.appBarBackground))
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSummaryCard(),
                      const SizedBox(height: 24),
                      _buildActionButtons(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryCard() {
    final bool isPaid = _tuitionFee?.paymentStatus.toLowerCase() == 'paid';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C4EA3), Color(0xFF1F3E8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Current Balance',
                style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isPaid ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isPaid ? Colors.greenAccent : Colors.redAccent),
                ),
                child: Text(
                  _tuitionFee?.paymentStatus.toUpperCase() ?? 'UNPAID',
                  style: TextStyle(
                    color: isPaid ? Colors.greenAccent : Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'RM ${_tuitionFee?.balance.toStringAsFixed(2) ?? "0.00"}',
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Invoice:', style: TextStyle(color: Colors.white70, fontSize: 14)),
              Text(
                'RM ${_tuitionFee?.totalInvoice.toStringAsFixed(2) ?? "0.00"}',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Academic Access:', style: TextStyle(color: Colors.white70, fontSize: 14)),
              Row(
                children: [
                  Icon(
                    _tuitionFee?.academicAccess == 'Active' ? Icons.check_circle : Icons.lock,
                    color: _tuitionFee?.academicAccess == 'Active' ? Colors.greenAccent : Colors.orangeAccent,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _tuitionFee?.academicAccess ?? 'Active',
                    style: TextStyle(
                      color: _tuitionFee?.academicAccess == 'Active' ? Colors.greenAccent : Colors.orangeAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final bool isPaid = _tuitionFee?.paymentStatus.toLowerCase() == 'paid';

    return Column(
      children: [
        if (!isPaid)
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/student-pay-tuition').then((_) => _fetchTuitionFee());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
            child: const Text(
              'PAY TUITION FEE (FPX)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.pushNamed(context, '/student-notifications');
          },
          icon: const Icon(Icons.notifications_active, color: AppColors.appBarBackground),
          label: const Text('View Notifications', style: TextStyle(color: AppColors.appBarBackground)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.appBarBackground),
            padding: const EdgeInsets.symmetric(vertical: 16),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}
