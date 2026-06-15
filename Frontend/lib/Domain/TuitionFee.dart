class TuitionFee {
  final int tuitionFeeId;
  final String studentId;
  final double totalInvoice;
  final double balance;
  final String paymentStatus;
  final String academicAccess;
  final dynamic studentData; // Can hold user name later
  final String dateString;

  TuitionFee({
    required this.tuitionFeeId,
    required this.studentId,
    required this.totalInvoice,
    required this.balance,
    required this.paymentStatus,
    required this.academicAccess,
    required this.dateString,
    this.studentData,
  });

  factory TuitionFee.fromJson(Map<String, dynamic> json) {
    String parsedDate = '';
    if (json['Updated_At'] != null) {
      try {
        DateTime dt = DateTime.parse(json['Updated_At']);
        parsedDate = '${dt.day}/${dt.month}/${dt.year}';
      } catch (_) {}
    }

    return TuitionFee(
      tuitionFeeId: json['TuitionFee_ID'] ?? 0,
      studentId: json['Student_ID']?.toString() ?? '',
      totalInvoice: double.tryParse(json['Total_Invoice']?.toString() ?? '0') ?? 0.0,
      balance: double.tryParse(json['Balance']?.toString() ?? '0') ?? 0.0,
      paymentStatus: json['Payment_Status'] ?? 'Unpaid',
      academicAccess: json['Academic_Access'] ?? 'Active',
      dateString: parsedDate,
      studentData: json['student'],
    );
  }
}
