// group_member.dart
// This model represents a single member of a group chat. 
// It stores essential information about the member for a specific group,
// such as user ID, role, unread message count, and the timestamp when they joined the group.

import 'package:cloud_firestore/cloud_firestore.dart';

class GroupMember {
  // 🔹 The unique user ID of the member. Matches the user's 'uid' in the 'users' collection.
  final String userId;

  // 🔹 The role of the member in the group.
  // For now, we can use 'member' or 'admin'. This allows future role-based permissions.
  final String role;

  // 🔹 Number of unread messages for this member in this group.
  // Useful for showing badges or notifications in the group chat list.
  final int unreadCount;

  // 🔹 The timestamp of when the user was added to the group.
  // Helps to sort members by join date if needed.
  final DateTime joinedAt;

  GroupMember({
    required this.userId,
    required this.role,
    required this.unreadCount,
    required this.joinedAt,
  });

  // 🔹 Converts the GroupMember object into a Map for Firestore storage.
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'role': role,
      'unreadCount': unreadCount,
      'joinedAt': joinedAt.millisecondsSinceEpoch,
    };
  }

  // 🔹 Factory constructor to create a GroupMember object from Firestore data.
  factory GroupMember.fromMap(Map<String, dynamic> map) {
    return GroupMember(
      userId: map['userId'] ?? '',
      role: map['role'] ?? 'member', // default to 'member' if not set
      unreadCount: map['unreadCount'] ?? 0,
      joinedAt: map['joinedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['joinedAt'])
          : DateTime.now(), // default to current time if missing
    );
  }

  // 🔹 Optional: Factory constructor to create from Firestore DocumentSnapshot
  factory GroupMember.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupMember.fromMap(data);
  }
}
