import 'package:hive/hive.dart';

part 'user_model_hive.g.dart'; // Hive code generation file

@HiveType(typeId: 0) // Unique typeId for Hive adapter
class UserModel extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String uid;

  @HiveField(2)
  final String profilePic;

  @HiveField(3)
  final bool isOnline;

  @HiveField(4)
  final String phoneNumber;

  @HiveField(5)
  final List<String> groupId;

  UserModel({
    required this.name,
    required this.uid,
    required this.profilePic,
    required this.isOnline,
    required this.phoneNumber,
    required this.groupId,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'uid': uid,
      'profilePic': profilePic,
      'isOnline': isOnline,
      'phoneNumber': phoneNumber,
      'groupId': groupId,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      name: map['name'] ?? '',
      uid: map['uid'] ?? '',
      profilePic: map['profilePic'] ?? '',
      isOnline: map['isOnline'] ?? false,
      phoneNumber: map['phoneNumber'] ?? '',
      groupId: List<String>.from(map['groupId']),
    );
  }
}
