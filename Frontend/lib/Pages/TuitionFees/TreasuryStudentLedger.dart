import 'package:flutter/material.dart';
import '../../Config/api.dart';
import '../../Domain/TuitionFee.dart';
import '../Homepage/StudentHomepage.dart'; // For AppColors and AppTextStyles

class TreasuryStudentLedger extends StatefulWidget {
  const TreasuryStudentLedger({super.key});

  @override
  State<TreasuryStudentLedger> createState() => _TreasuryStudentLedgerState();
}

class _TreasuryStudentLedgerState extends State<TreasuryStudentLedger> {
  bool _isLoading = true;
  List<TuitionFee> _ledgers = [];
  String _selectedFilter = 'All Students';
  final _searchController = TextEditingController();

  final List<String> _filters = ['All Students', 'Paid', 'Blocked'];

  @override
  void initState() {
    super.initState();
    _fetchLedger();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchLedger() async {
    setState(() => _isLoading = true);
    final result = await ApiService.getTreasuryLedger();
    _processResult(result);
  }

  Future<void> _filterLedger(String filter) async {
    if (filter == 'All Students') {
      _fetchLedger();
      return;
    }
    setState(() => _isLoading = true);
    final result = await ApiService.filterTreasuryLedger(filter);
    _processResult(result);
  }

  Future<void> _searchLedger(String studentId) async {
    if (studentId.isEmpty) {
      _fetchLedger();
      return;
    }
    setState(() => _isLoading = true);
    final result = await ApiService.searchTreasuryLedger(studentId);
    _processResult(result);
  }

  void _processResult(Map<String, dynamic> result) {
    if (result['success'] && result['data'] != null) {
      final List<dynamic> data = result['data'];
      setState(() {
        _ledgers = data.map((json) => TuitionFee.fromJson(json)).toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _ledgers = [];
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Failed to load ledger')),
      );
    }
  }

  Future<void> _sendAlert(String studentId) async {
    final result = await ApiService.sendTuitionAlert(studentId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Alert sent')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: const Color(0xFF6A2D87), // Purple background
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Student Ledger', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.appBarBackground))
                : _ledgers.isEmpty
                    ? Center(
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          margin: const EdgeInsets.symmetric(horizontal: 32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                            ],
                          ),
                          child: const Text(
                            'No record found for this Student ID',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _ledgers.length,
                        itemBuilder: (context, index) {
                          return _buildLedgerCard(_ledgers[index], index + 1);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 60, child: Text('Search', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    isDense: true,
                  ),
                  onSubmitted: _searchLedger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const SizedBox(width: 60, child: Text('Filter', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    isDense: true,
                  ),
                  value: _selectedFilter,
                  items: _filters.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedFilter = val);
                      _filterLedger(val);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerCard(TuitionFee ledger, int index) {
    final bool isPaid = ledger.paymentStatus.toLowerCase() == 'paid';
    final bool isBlocked = ledger.academicAccess == 'Restricted' || ledger.academicAccess == 'Blocked';
    
    String studentName = 'Unknown';
    if (ledger.studentData != null && ledger.studentData['user'] != null) {
      studentName = ledger.studentData['user']['User_FullName'] ?? 'Unknown';
    }

    // Capitalize each word for name
    studentName = studentName.split(' ').map((str) => str.isNotEmpty ? '${str[0].toUpperCase()}${str.substring(1).toLowerCase()}' : '').join(' ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: isPaid 
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$index. ', style: const TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(ledger.studentId, style: const TextStyle(color: Colors.black87)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(ledger.dateString.isNotEmpty ? ledger.dateString : 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)), // Dynamic date from DB
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text('Status: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Paid', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('RM${ledger.totalInvoice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$index. ', style: const TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(ledger.studentId, style: const TextStyle(color: Colors.black87)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end, // Align to end to put button nicely
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 80, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                      const Text(': '),
                      Text('Blocked', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const SizedBox(width: 80, child: Text('Outstanding', style: TextStyle(fontWeight: FontWeight.bold))),
                      const Text(': '),
                      Text('RM${ledger.balance.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _sendAlert(ledger.studentId),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.notifications_active, color: Colors.orange, size: 14),
                          SizedBox(width: 4),
                          Text('Send Alert', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
    );
  }
}
