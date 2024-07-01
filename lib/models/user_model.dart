class UserModel {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final int age;

  UserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.age,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'],
      firstName: data['first name'],
      lastName: data['last name'],
      age: data['age'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'first name': firstName,
      'last name': lastName,
      'age': age,
    };
  }
}
