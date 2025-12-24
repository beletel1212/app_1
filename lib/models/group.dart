class Group {
  final String senderId;
  final String name;
  final String groupId;
  final String lastMessage;
  final String groupPic;
  final List<String> membersUid;
  final DateTime timeSent;
  Group({
    required this.senderId,
    required this.name,
    required this.groupId,
    required this.lastMessage,
    required this.groupPic,
    required this.membersUid,
    required this.timeSent,
  });


   
// 🔹 Allows updating specific fields (e.g. unreadCount later)
// Keeps Group immutable and UI-friendly
Group copyWith({
  String? senderId,
  String? name,
  String? groupId,
  String? lastMessage,
  String? groupPic,
  List<String>? membersUid,
  DateTime? timeSent,
}) {
  return Group(
    senderId: senderId ?? this.senderId,
    name: name ?? this.name,
    groupId: groupId ?? this.groupId,
    lastMessage: lastMessage ?? this.lastMessage,
    groupPic: groupPic ?? this.groupPic,
    membersUid: membersUid ?? this.membersUid,
    timeSent: timeSent ?? this.timeSent,
  );
}


  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'name': name,
      'groupId': groupId,
      'lastMessage': lastMessage,
      'groupPic': groupPic,
      'membersUid': membersUid,
      'timeSent': timeSent.millisecondsSinceEpoch,
    };
  }

  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
      senderId: map['senderId'] ?? '',
      name: map['name'] ?? '',
      groupId: map['groupId'] ?? '',
      lastMessage: map['lastMessage'] ?? '',
      groupPic: map['groupPic'] ?? '',
      membersUid: List<String>.from(map['membersUid']),
      timeSent: DateTime.fromMillisecondsSinceEpoch(map['timeSent']),
    );
  }
}
