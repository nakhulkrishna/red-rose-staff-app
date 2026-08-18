class AppUser {
  final String uid;
  final String email;
  final String name;
  final String region;
  final String phone;
  final String approvalStatus;
  final bool isActive;

  const AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.region,
    required this.phone,
    this.approvalStatus = 'approved',
    this.isActive = true,
  });

  bool get isApprovedActive =>
      isActive && approvalStatus.toLowerCase() == 'approved';
}
