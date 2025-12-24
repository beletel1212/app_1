import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:whatsapp_ui/common/widgets/loader.dart';
import 'package:whatsapp_ui/features/chat/controller/chat_controller.dart';
import 'package:whatsapp_ui/common/enums/message_enum.dart';
import 'package:whatsapp_ui/common/providers/message_reply_provider.dart';
import 'package:whatsapp_ui/features/chat/widgets/my_message_card.dart';
import 'package:whatsapp_ui/features/chat/widgets/sender_message_card.dart';
import 'package:whatsapp_ui/models/message.dart';
import 'package:firebase_auth/firebase_auth.dart';


/// ChatList displays all messages between the current user and the receiver.
/// It decides which card (sender or my message) to use based on the sender ID.
/// 
/// Now supports selection mode — tapping or long-pressing messages to select/deselect them.
/// Selected messages are visually highlighted with a translucent color.
class ChatList extends ConsumerWidget {
  final String recieverUserId;
  final bool isGroupChat;

  /// Whether the chat is currently in selection mode
  final bool isSelectionMode;

  /// List of selected message IDs
  final List<String> selectedMessageIds;

  /// Triggered when the user long-presses a message (to enter selection mode)
  final Function(String messageId) onMessageLongPress;

  /// Triggered when the user taps a message (to select/deselect)
  final Function(String messageId) onMessageTap;

  const ChatList({
    super.key,
    required this.recieverUserId,
    required this.isGroupChat,
    required this.isSelectionMode,
    required this.selectedMessageIds,
    required this.onMessageLongPress,
    required this.onMessageTap,
  });


  //to reply to a message when the user swipes left on a message
  void onMessageSwipe(
    Ref ref,
    String message,
    bool isMe,
    MessageEnum messageEnum,
  ) {
   
    // jojo migrated from StateProvider to Notifier, ChatGPT can help you 
    /*ref.read(messageReplyProvider.notifier).update(
          (state) => MessageReply(
            message,
            isMe,
            messageEnum,
          ),
        );*/
      ref.read(messageReplyProvider.notifier).setReply(
  MessageReply(message, isMe, messageEnum),
);


  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<Message>>(
      stream: ref
          .watch(chatControllerProvider)
          .chatStream(recieverUserId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Loader();
        }


    ///  reset Group Unread message Count 
        if (isGroupChat) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await ref
                .read(chatControllerProvider)
                .resetGroupUnreadCount(recieverUserId); // groupId
          });
        }

        final messageList = snapshot.data!;

        return ListView.builder(
          itemCount: messageList.length,
          itemBuilder: (context, index) {
            final message = messageList[index];
            var timeSent = DateFormat.Hm().format(message.timeSent);


            // Check if this message is selected
            final isSelected = selectedMessageIds.contains(message.messageId);

            // Background highlight color for selected messages
            final backgroundColor = isSelected
                ? const Color.fromARGB(255, 0, 150, 136)
                : Colors.transparent;

            // Gesture detection for tap & long press actions
            return GestureDetector(
              onLongPress: () => onMessageLongPress(message.messageId),
              onTap: () => onMessageTap(message.messageId),
              child: Container(
                color: backgroundColor,
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Builder(
                  builder: (context) {
         
          if (!message.isSeen &&
                  message.recieverid ==
                      FirebaseAuth.instance.currentUser!.uid) {
                ref.read(chatControllerProvider).setChatMessageSeen(
                      context,
                      recieverUserId,
                      message.messageId,
                    );
              }

                    // Determine if message was sent by current user
                    final isMe =
                        FirebaseAuth.instance.currentUser!.uid==
                            message.senderId;

                    if (isMe) {
                      return MyMessageCard(
                        message: message.text,
                        date: timeSent,
                        type: message.type,
                        repliedText: message.repliedMessage,
                        username: message.repliedTo,
                        repliedMessageType: message.repliedMessageType,
                        isSeen: message.isSeen,
                        onLeftSwipe: () => onMessageSwipe(
                    ref as Ref,      
                    message.text,
                    true,
                    message.type,
                  ),
                      );
                    } else {
                      return SenderMessageCard(
                        message: message.text,
                        date: message.timeSent.toString(),
                        type: message.type,
                        repliedText: message.repliedMessage,
                        username: message.repliedTo,
                        repliedMessageType: message.repliedMessageType, 
                        onRightSwipe:(details) => onMessageSwipe(
                  ref as Ref,
                  message.text,
                  false,
                  message.type,
                ), 
                      );
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}





/***** ************************************** Old one before delete, reply and  
 // forward were includded 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:whatsapp_ui/common/enums/message_enum.dart';
import 'package:whatsapp_ui/common/providers/message_reply_provider.dart';
import 'package:whatsapp_ui/common/widgets/loader.dart';

import 'package:whatsapp_ui/features/chat/controller/chat_controller.dart';
import 'package:whatsapp_ui/features/chat/widgets/my_message_card.dart';
import 'package:whatsapp_ui/features/chat/widgets/sender_message_card.dart';
import 'package:whatsapp_ui/models/message.dart';

      //this class is to display message chat list

class ChatList extends ConsumerStatefulWidget {
  final String recieverUserId;
  final bool isGroupChat;
  const ChatList({
    super.key,
    required this.recieverUserId,
    required this.isGroupChat,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ChatListState();
}

class _ChatListState extends ConsumerState<ChatList> {
  final ScrollController messageController = ScrollController();

  @override
  void dispose() {
    super.dispose();
    messageController.dispose();
  }

//to reply to a message when the user swipes left on a message
  void onMessageSwipe(
    String message,
    bool isMe,
    MessageEnum messageEnum,
  ) {
   
    // jojo migrated from StateProvider to Notifier, ChatGPT can help you 
    /*ref.read(messageReplyProvider.notifier).update(
          (state) => MessageReply(
            message,
            isMe,
            messageEnum,
          ),
        );*/
      ref.read(messageReplyProvider.notifier).setReply(
  MessageReply(message, isMe, messageEnum),
);


  }

  @override
  Widget build(BuildContext context) {
    // since it is a stateful widget we use widget.isGroupChat, i.e to access the widget properties
    // if it was a stateless widget we would use just isGroupChat
    return StreamBuilder<List<Message>>(
        stream: widget.isGroupChat
            ? ref
                .read(chatControllerProvider)
                .groupChatStream(widget.recieverUserId)
            : ref
                .read(chatControllerProvider)
                .chatStream(widget.recieverUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Loader();
          }

          // automatixally scroll to the latest message
          SchedulerBinding.instance.addPostFrameCallback((_) {
            messageController
                .jumpTo(messageController.position.maxScrollExtent);
          });

      //to display message chat list
          return ListView.builder(
            controller: messageController,
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final messageData = snapshot.data![index];
              var timeSent = DateFormat.Hm().format(messageData.timeSent);


              //when the user comes to the messsage_chat screen(i.e current screen),
              // then, since there is auto scroll the latest message will be displayed
              // therefore update database isSeen to true 
              if (!messageData.isSeen &&
                  messageData.recieverid ==
                      FirebaseAuth.instance.currentUser!.uid) {
                ref.read(chatControllerProvider).setChatMessageSeen(
                      context,
                      widget.recieverUserId,
                      messageData.messageId,
                    );
              }
              if (messageData.senderId ==
                  FirebaseAuth.instance.currentUser!.uid) {
                return MyMessageCard(
                  message: messageData.text,
                  date: timeSent,
                  type: messageData.type,
                  repliedText: messageData.repliedMessage,
                  username: messageData.repliedTo,
                  repliedMessageType: messageData.repliedMessageType,
                  onLeftSwipe: () => onMessageSwipe(
                    messageData.text,
                    true,
                    messageData.type,
                  ),
                  isSeen: messageData.isSeen,
                );
              }
              return SenderMessageCard(
                message: messageData.text,
                date: timeSent,
                type: messageData.type,
                username: messageData.repliedTo,
                repliedMessageType: messageData.repliedMessageType,
                onRightSwipe: (details) => onMessageSwipe(
                  messageData.text,
                  false,
                  messageData.type,
                ),
                repliedText: messageData.repliedMessage,
              );
            },
          );
        });
  }
}
*********/