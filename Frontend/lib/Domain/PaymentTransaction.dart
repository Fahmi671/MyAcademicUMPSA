class PaymentTransaction {
  final int transactionId;
  final int tuitionFeeId;
  final String studentId;
  final double amountPaid;
  final String paymentMethod;
  final String bankName;
  final String remarks;
  final String transactionStatus;
  final String transactionDate;

  PaymentTransaction({
    required this.transactionId,
    required this.tuitionFeeId,
    required this.studentId,
    required this.amountPaid,
    required this.paymentMethod,
    required this.bankName,
    required this.remarks,
    required this.transactionStatus,
    required this.transactionDate,
  });

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      transactionId: json['Transaction_ID'] ?? 0,
      tuitionFeeId: json['TuitionFee_ID'] ?? 0,
      studentId: json['Student_ID']?.toString() ?? '',
      amountPaid: double.tryParse(json['Amount_Paid']?.toString() ?? '0') ?? 0.0,
      paymentMethod: json['Payment_Method'] ?? '',
      bankName: json['Bank_Name'] ?? '',
      remarks: json['Remarks'] ?? '',
      transactionStatus: json['Transaction_Status'] ?? '',
      transactionDate: json['Transaction_Date'] ?? '',
    );
  }
}
