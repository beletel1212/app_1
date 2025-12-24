      import 'dart:io';
      import 'package:cloud_firestore/cloud_firestore.dart';
      import 'package:firebase_auth/firebase_auth.dart';
      import 'package:flutter/material.dart';
      import 'package:flutter_riverpod/flutter_riverpod.dart';
      import 'package:uuid/uuid.dart';
      import 'package:whatsapp_ui/common/enums/message_enum.dart';
      import 'package:whatsapp_ui/common/providers/message_reply_provider.dart';
      import 'package:whatsapp_ui/common/repositories/common_firebase_storage_repository.dart';
      import 'package:whatsapp_ui/common/utils/utils.dart';
      import 'package:whatsapp_ui/models/chat_contact.dart';
      import 'package:whatsapp_ui/models/group.dart';
      import 'package:whatsapp_ui/models/message.dart';
      import 'package:whatsapp_ui/models/user_model.dart';

      final chatRepositoryProvider = Provider(
        (ref) => ChatRepository(
          firestore: FirebaseFirestore.instance,
          auth: FirebaseAuth.instance,
        ),
      );

      class ChatRepository {
        final FirebaseFirestore firestore;
        final FirebaseAuth auth;
        ChatRepository({
          required this.firestore,
          required this.auth,
        });

        Stream<List<ChatContact>> getChatContacts() {
          return firestore
              .collection('users')
              .doc(auth.currentUser!.uid)
              .collection('chats')
              .snapshots()
              .asyncMap((event) async {
            List<ChatContact> contacts = [];
            for (var document in event.docs) {
              var chatContact = ChatContact.fromMap(document.data());
              var userData = await firestore
                  .collection('users')
                  .doc(chatContact.contactId)
                  .get();
              var user = UserModel.fromMap(userData.data()!);

              contacts.add(
                ChatContact(
                  name: user.name,
                  profilePic: user.profilePic,
                  contactId: chatContact.contactId,
                  timeSent: chatContact.timeSent,
                  lastMessage: chatContact.lastMessage,
                  sentUnread: chatContact.sentUnread,
                  receivedUnread: chatContact.receivedUnread,
                ),
              );
            }
            return contacts;
          });
        }

        Stream<List<Group>> getChatGroups() {
          return firestore.collection('groups').snapshots().map((event) {
            List<Group> groups = [];
            for (var document in event.docs) {
              var group = Group.fromMap(document.data());
              if (group.membersUid.contains(auth.currentUser!.uid)) {
                groups.add(group);
              }
            }
            return groups;
          });
        }

      //to display one to one chat messages list in message_chat_screen
        Stream<List<Message>> getChatStream(String recieverUserId) {
          return firestore
              .collection('users')
              .doc(auth.currentUser!.uid)
              .collection('chats')
              .doc(recieverUserId)
              .collection('messages')
              .orderBy('timeSent')
              .snapshots()
              .map((event) {
            List<Message> messages = [];
            for (var document in event.docs) {
              messages.add(Message.fromMap(document.data()));
            }
            return messages;
          });
        }


        //to display group chat messages list in message_chat_screen
        //stream continiously listens the firebase database  
        Stream<List<Message>> getGroupChatStream(String groudId) {
          return firestore
              .collection('groups')
              .doc(groudId)
              .collection('chats')
              .orderBy('timeSent')
              .snapshots()
              .map((event) {
            List<Message> messages = [];
            for (var document in event.docs) {
              messages.add(Message.fromMap(document.data()));
            }
            return messages;
          });
        } 

      /// Resets the receivedUnread message count when user opens a chat
      Future<void> resetUnreadCount(String contactId) async {
        try {
          await firestore
              .collection('users')
              .doc(auth.currentUser!.uid)
              .collection('chats')
              .doc(contactId)
              .update({'receivedUnread': 0});

      await firestore
              .collection('users')
              .doc(contactId)
              .collection('chats')
              .doc(auth.currentUser!.uid)
              .update({'sentUnread': 0});

        } catch (e) {
          debugPrint('Error resetting unread count: $e');
        }
      }


    // Inside ChatRepository
Future<void> resetGroupUnreadCount(String groupId) async {
  try {
    await firestore
        .collection('groups')
        .doc(groupId)
        .collection('groupMembers')
        .doc(auth.currentUser!.uid)
        .update({'unreadCount': 0});
  } catch (e) {
    debugPrint('Error resetting group unread count in repository: $e');
  }
}




      //to store the count of messages thar are unread
          int senderSentUnread = 0;
          int receiverReceivedUnread = 0;

      // to save last message on user--->chat collection, or
      // if it is group message group collection , refered here as method contactsSubCollection
        void _saveDataToContactsSubcollection(
        UserModel senderUserData,
        UserModel? recieverUserData,
        String text,
        DateTime timeSent,
        String recieverUserId,
        bool isGroupChat,
      ) async {
       if (isGroupChat) {
  // 🔹 Step 1: Update the group document with the last message and timestamp.
  // This ensures that when we show the list of groups, the last message
  // and time appear correctly for all members.
  await firestore.collection('groups').doc(recieverUserId).update({
    'lastMessage': text,
    'timeSent': DateTime.now().millisecondsSinceEpoch,
  });

  // 🔹 Step 2: Update unread counts for all group members except the sender.
  // We fetch the 'groupMembers' subcollection from the group document.
  final membersSnapshot = await firestore
      .collection('groups')
      .doc(recieverUserId)
      .collection('groupMembers')
      .get();

  for (var memberDoc in membersSnapshot.docs) {
    final memberData = memberDoc.data();
    final memberId = memberData['userId'] as String;

    // Skip the sender; they shouldn't have their unread count incremented
    if (memberId == auth.currentUser!.uid) continue;

    await firestore
        .collection('groups')
        .doc(recieverUserId)
        .collection('groupMembers')
        .doc(memberId)
        .update({
      'unreadCount': FieldValue.increment(1),
    });
  }
}

        
        else {
          // 🔹 Step 1: Fetch existing chat documents to get old unread counts
          final senderChatDoc = await firestore
              .collection('users')
              .doc(auth.currentUser!.uid)
              .collection('chats')
              .doc(recieverUserId)
              .get();

          final receiverChatDoc = await firestore
              .collection('users')
              .doc(recieverUserId)
              .collection('chats')
              .doc(auth.currentUser!.uid)
              .get();

          

          // 🔹 Step 2: Read existing counts if available
          if (senderChatDoc.exists) {
            senderSentUnread = senderChatDoc.data()?['sentUnread'] ?? 0;
          }
          if (receiverChatDoc.exists) {
            receiverReceivedUnread = receiverChatDoc.data()?['receivedUnread'] ?? 0;
          }

          // 🔹 Step 3: Increment unread counters
          senderSentUnread++;
          receiverReceivedUnread++;

          // 🔹 Step 4: Save updated data for RECEIVER
          var recieverChatContact = ChatContact(
            name: senderUserData.name,
            profilePic: senderUserData.profilePic,
            contactId: senderUserData.uid,
            timeSent: timeSent,
            lastMessage: text,
            sentUnread: 0,
            receivedUnread: receiverReceivedUnread,
          );

          await firestore
              .collection('users')
              .doc(recieverUserId)
              .collection('chats')
              .doc(auth.currentUser!.uid)
              .set(recieverChatContact.toMap());

          // 🔹 Step 5: Save updated data for SENDER
          var senderChatContact = ChatContact(
            name: recieverUserData!.name,
            profilePic: recieverUserData.profilePic,
            contactId: recieverUserData.uid,
            timeSent: timeSent,
            lastMessage: text,
            sentUnread: senderSentUnread,
            receivedUnread: 0,
          );

          await firestore
              .collection('users')
              .doc(auth.currentUser!.uid)
              .collection('chats')
              .doc(recieverUserId)
              .set(senderChatContact.toMap());
        }
      }



        void _saveMessageToMessageSubcollection({
          required String recieverUserId,
          required String text,
          required DateTime timeSent,
          required String messageId,
          required String username,
          required MessageEnum messageType,
          required MessageReply? messageReply,
          required String senderUsername,
          required String? recieverUserName,
          required bool isGroupChat,
        }) async {
          final message = Message(
            senderId: auth.currentUser!.uid,
            recieverid: recieverUserId,
            text: text,
            type: messageType,
            timeSent: timeSent,
            messageId: messageId,
            isSeen: false,
            repliedMessage: messageReply == null ? '' : messageReply.message,
            repliedTo: messageReply == null
                ? ''
                : messageReply.isMe
                    ? senderUsername
                    : recieverUserName ?? '',
            repliedMessageType:
                messageReply == null ? MessageEnum.text : messageReply.messageEnum,
          );


                if (isGroupChat) {
          // 🔹 Step 1: Store the message in the group's 'chats' subcollection.
          await firestore
              .collection('groups')
              .doc(recieverUserId)
              .collection('chats')
              .doc(messageId)
              .set(message.toMap());

          // 🔹 Step 2: Update the unread count for each member in the 'groupMembers' subcollection
          // except the sender. Using FieldValue.increment(1) allows safe concurrent writes.
          final membersSnapshot = await firestore
              .collection('groups')
              .doc(recieverUserId)
              .collection('groupMembers')
              .get();

          for (var memberDoc in membersSnapshot.docs) {
            final memberData = memberDoc.data();
            final memberId = memberData['userId'] as String;

            if (memberId == auth.currentUser!.uid) continue; // skip sender

            await firestore
                .collection('groups')
                .doc(recieverUserId)
                .collection('groupMembers')
                .doc(memberId)
                .update({
              'unreadCount': FieldValue.increment(1),
            });
          }
        }

          
          else {
            // users -> sender id -> reciever id -> messages -> message id -> store message
            await firestore
                .collection('users')
                .doc(auth.currentUser!.uid)
                .collection('chats')
                .doc(recieverUserId)
                .collection('messages')
                .doc(messageId)
                .set(
                  message.toMap(),
                );
            // users -> reciever id  -> sender id -> messages -> message id -> store message
            await firestore
                .collection('users')
                .doc(recieverUserId)
                .collection('chats')
                .doc(auth.currentUser!.uid)
                .collection('messages')
                .doc(messageId)
                .set(
                  message.toMap(),
                );
          }
        }

        void sendTextMessage({
          required BuildContext context,
          required String text,
          required String recieverUserId,
          required UserModel senderUser,
          required MessageReply? messageReply,
          required bool isGroupChat,
        }) async {
          try {
            var timeSent = DateTime.now();
            UserModel? recieverUserData;

            if (!isGroupChat) {
              var userDataMap =
                  await firestore.collection('users').doc(recieverUserId).get();
              recieverUserData = UserModel.fromMap(userDataMap.data()!);
            }

            var messageId = const Uuid().v1();

            _saveDataToContactsSubcollection(
              senderUser,
              recieverUserData,
              text,
              timeSent,
              recieverUserId,
              isGroupChat,
            );

            _saveMessageToMessageSubcollection(
              recieverUserId: recieverUserId,
              text: text,
              timeSent: timeSent,
              messageType: MessageEnum.text,
              messageId: messageId,
              username: senderUser.name,
              messageReply: messageReply,
              recieverUserName: recieverUserData?.name,
              senderUsername: senderUser.name,
              isGroupChat: isGroupChat,
            );
          } catch (e) {
            if (context.mounted) {
            showSnackBar(context: context, content: e.toString());
            }
          }
        }

        void sendFileMessage({
          required BuildContext context,
          required File file,
          required String recieverUserId,
          required UserModel senderUserData,
          required Ref ref,
          required MessageEnum messageEnum,
          required MessageReply? messageReply,
          required bool isGroupChat,
        }) async {
          try {
            var timeSent = DateTime.now();
            var messageId = const Uuid().v1();

            String imageUrl = await ref
                .read(commonFirebaseStorageRepositoryProvider)
                .storeFileToFirebase(
                  'chat/${messageEnum.type}/${senderUserData.uid}/$recieverUserId/$messageId',
                  file,
                );

            UserModel? recieverUserData;
            if (!isGroupChat) {
              var userDataMap =
                  await firestore.collection('users').doc(recieverUserId).get();
              recieverUserData = UserModel.fromMap(userDataMap.data()!);
            }

            String contactMsg;

            switch (messageEnum) {
              case MessageEnum.image:
                contactMsg = '📷 Photo';
                break;
              case MessageEnum.video:
                contactMsg = '📸 Video';
                break;
              case MessageEnum.audio:
                contactMsg = '🎵 Audio';
                break;
              case MessageEnum.gif:
                contactMsg = 'GIF';
                break;
              default:
                contactMsg = 'GIF';
            }
            _saveDataToContactsSubcollection(
              senderUserData,
              recieverUserData,
              contactMsg,
              timeSent,
              recieverUserId,
              isGroupChat,
            );

            _saveMessageToMessageSubcollection(
              recieverUserId: recieverUserId,
              text: imageUrl,
              timeSent: timeSent,
              messageId: messageId,
              username: senderUserData.name,
              messageType: messageEnum,
              messageReply: messageReply,
              recieverUserName: recieverUserData?.name,
              senderUsername: senderUserData.name,
              isGroupChat: isGroupChat,
            );
          } catch (e) {
              if (context.mounted) {
            showSnackBar(context: context, content: e.toString());
              }
          }
        }


      // unlike imge or video, only the gif url is saved in fire base
      // i.e we don't save it to firebase storage to save space
        void sendGIFMessage({
          required BuildContext context,
          required String gifUrl,
          required String recieverUserId,
          required UserModel senderUser,
          required MessageReply? messageReply,
          required bool isGroupChat,
        }) async {
          try {
            var timeSent = DateTime.now();
            UserModel? recieverUserData;

            if (!isGroupChat) {
              var userDataMap =
                  await firestore.collection('users').doc(recieverUserId).get();
              recieverUserData = UserModel.fromMap(userDataMap.data()!);
            }

            var messageId = const Uuid().v1();

            _saveDataToContactsSubcollection(
              senderUser,
              recieverUserData,
              'GIF',
              timeSent,
              recieverUserId,
              isGroupChat,
            );

            _saveMessageToMessageSubcollection(
              recieverUserId: recieverUserId,
              text: gifUrl,
              timeSent: timeSent,
              messageType: MessageEnum.gif,
              messageId: messageId,
              username: senderUser.name,
              messageReply: messageReply,
              recieverUserName: recieverUserData?.name,
              senderUsername: senderUser.name,
              isGroupChat: isGroupChat,
            );
          } catch (e) {
            if (context.mounted) {
            showSnackBar(context: context, content: e.toString());
            }
          }
        }

        void setChatMessageSeen(
          BuildContext context,
          String recieverUserId,
          String messageId,
        ) async {
          try {
            await firestore
                .collection('users')
                .doc(auth.currentUser!.uid)
                .collection('chats')
                .doc(recieverUserId)
                .collection('messages')
                .doc(messageId)
                .update({'isSeen': true});

            await firestore
                .collection('users')
                .doc(recieverUserId)
                .collection('chats')
                .doc(auth.currentUser!.uid)
                .collection('messages')
                .doc(messageId)
                .update({'isSeen': true});
          } catch (e) {
            if (context.mounted) {
            showSnackBar(context: context, content: e.toString());
            }
          }
        }

        /// Deletes a message from Firestore.
        /// 
        /// [deleteForEveryone] - if true, deletes message from both sender and receiver.
        /// [isGroupChat] - if true, deletes from group chat path.
        Future<void> deleteMessage({
          required BuildContext context,
          required String recieverUserId,
          required String messageId,
          required bool deleteForEveryone,
          required bool isGroupChat,
        }) async {
          try {
            // For group chat
            if (isGroupChat) {
              await firestore
                  .collection('groups')
                  .doc(recieverUserId)
                  .collection('chats')
                  .doc(messageId)
                  .delete();
              return;
            }

            final currentUserId = auth.currentUser!.uid;

            // Always delete for the current user
            await firestore
                .collection('users')
                .doc(currentUserId)
                .collection('chats')
                .doc(recieverUserId)
                .collection('messages')
                .doc(messageId)
                .delete();

            // If the user selected "Delete for everyone"
            if (deleteForEveryone) {
              await firestore
                  .collection('users')
                  .doc(recieverUserId)
                  .collection('chats')
                  .doc(currentUserId)
                  .collection('messages')
                  .doc(messageId)
                  .delete();
            }
          } catch (e) {
            if (context.mounted) {
              showSnackBar(
                context: context,
                content: 'Failed to delete message: $e',
              );
            }
          }
        }



      }
