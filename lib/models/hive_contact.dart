import 'package:hive/hive.dart';

part 'hive_contact.g.dart'; 
// 🟩 This part directive is needed for code generation. 
// Hive will generate the adapter in a file named `hive_contact.g.dart` after running the build_runner command.

@HiveType(typeId: 0) 
// 🟩 typeId must be unique for each Hive object type. Use 0 if it's your first Hive object.
// Change this if you add more Hive models to avoid conflicts.

class HiveContact extends HiveObject {
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

  HiveContact({
    required this.name,
    required this.uid,
    required this.profilePic,
    required this.isOnline,
    required this.phoneNumber,
    required this.groupId,
  });

  /// Convert HiveContact to a Map (optional, useful for Firebase or other serialization)
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

  /// Factory to create HiveContact from a Map (optional)
  factory HiveContact.fromMap(Map<String, dynamic> map) {
    return HiveContact(
      name: map['name'] ?? '',
      uid: map['uid'] ?? '',
      profilePic: map['profilePic'] ?? '',
      isOnline: map['isOnline'] ?? false,
      phoneNumber: map['phoneNumber'] ?? '',
      groupId: List<String>.from(map['groupId'] ?? []),
    );
  }
}
