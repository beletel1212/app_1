import 'package:hive/hive.dart';

part 'user_model.g.dart'; // Required for code generation
@HiveType(typeId: 0)
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

  @HiveField(6)
  final bool showOnlineStatus;   // 🟩 ADDED FIELD

  UserModel({
    required this.name,
    required this.uid,
    required this.profilePic,
    required this.isOnline,
    required this.phoneNumber,
    required this.groupId,
    required this.showOnlineStatus,   // 🟩 REQUIRED
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'uid': uid,
      'profilePic': profilePic,
      'isOnline': isOnline,
      'phoneNumber': phoneNumber,
      'groupId': groupId,
      'showOnlineStatus': showOnlineStatus,   // 🟩 ADDED
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
      showOnlineStatus: map['showOnlineStatus'] ?? true, // 🟩 DEFAULT true
    );
  }
}

