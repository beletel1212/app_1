//store a group

import 'package:cloud_firestore/cloud_firestore.dart';

class GroupContact {
  final String groupId;
  final String name;
  final String groupPhoto; // URL
  final String lastMessage;
  final DateTime lastMessageTime;

  GroupContact({
    required this.groupId,
    required this.name,
    required this.groupPhoto,
    required this.lastMessage,
    required this.lastMessageTime,
  });

  // Factory to create from Firestore document
  factory GroupContact.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupContact(
      groupId: doc.id,
      name: data['name'] ?? '',
      groupPhoto: data['groupPhoto'] ?? '',
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert to Map for uploading to Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'groupPhoto': groupPhoto,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
    };
  }
}
