class User {
  final int id;
  final String email;
  final String fullName;
  final String role;
  final double creditScore;
  final String verificationStatus;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.creditScore,
    required this.verificationStatus,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'] ?? '',
      role: json['role'],
      creditScore: (json['credit_score'] ?? 0.0).toDouble(),
      verificationStatus: json['verification_status'] ?? 'unverified',
    );
  }
}
