class User {
  final String userID;
  final String username;
  final String email;
  final String password;
  final String? profilePicture;
  final DateTime dateOfBirth;
  final String diabetesType;

  User({
    required this.userID,
    required this.username,
    required this.email,
    required this.password,
    this.profilePicture,
    required this.dateOfBirth,
    required this.diabetesType,
  });
}
