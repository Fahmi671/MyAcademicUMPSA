class Treasury {
  final int treasuryId;
  final int userId;

  Treasury({
    required this.treasuryId,
    required this.userId,
  });

  factory Treasury.fromJson(Map<String, dynamic> json) {
    return Treasury(
      treasuryId: json['Treasury_ID'] ?? 0,
      userId: json['User_ID'] ?? 0,
    );
  }
}
