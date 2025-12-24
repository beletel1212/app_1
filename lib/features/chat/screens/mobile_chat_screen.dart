import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_ui/common/utils/colors.dart';
import 'package:whatsapp_ui/features/auth/controller/auth_controller.dart';
import 'package:whatsapp_ui/features/call/controller/call_controller.dart';
import 'package:whatsapp_ui/features/chat/controller/chat_controller.dart';
import 'package:whatsapp_ui/features/chat/widgets/bottom_chat_field.dart';
import 'package:whatsapp_ui/features/chat/widgets/chat_list.dart';
import 'package:whatsapp_ui/models/user_model.dart';
import 'package:whatsapp_ui/features/call/screens/call_pickup_screen.dart';



/// The main screen for mobile chat (one-to-one or group chat)
/// 
/// This widget manages message display, sending, and the new
/// message selection system (for delete, reply, or forward).
class MobileChatScreen extends ConsumerStatefulWidget {

    static const String routeName = '/mobile-chat-screen';

  final String uid; // Receiver or group ID
  final String name; // Display name
  final bool isGroupChat; // Whether this is a group chat
  final String profilePic;

  const MobileChatScreen({
    super.key,
    required this.uid,
    required this.name,
    required this.isGroupChat,
    required this.profilePic,

  });

  @override
  ConsumerState<MobileChatScreen> createState() => _MobileChatScreenState();
}

class _MobileChatScreenState extends ConsumerState<MobileChatScreen> {
  /// Whether the screen is currently in "selection mode"
  bool isSelectionMode = false;

    // 🟦 Stores the receiver's user data from the real-time stream
  UserModel? receiverUser;


  /// The list of selected message IDs
  List<String> selectedMessageIds = [];

  /// Whether to delete selected messages for everyone
  bool deleteForEveryone = false;

  //
  bool isVideoCall = true ;

  @override
void initState() {
  super.initState();

  // 🟦 Listen to the receiver's online state in real-time
  if (!widget.isGroupChat) {
    ref.read(chatControllerProvider); // makes ref usable in initState

    // Delay to ensure ref is fully available
    Future.delayed(Duration.zero, () {
      ref
          .read(authControllerProvider)
          .userDataById(widget.uid)
          .listen((userModel) {
        setState(() {
          receiverUser = userModel;
        });
      });
    });
  }
}


void makeCall(WidgetRef ref, BuildContext context, bool isVideoCall) {
    ref.read(callControllerProvider).makeCall(
          context,
          widget.name,
          widget.uid,
          widget.profilePic,
          widget.isGroupChat,
          isVideoCall,
        );
  }


  /// Called when the user long-presses a message
  /// This activates selection mode and selects the first message.
  void onMessageLongPress(String messageId) {
    setState(() {
      isSelectionMode = true;
      if (!selectedMessageIds.contains(messageId)) {
        selectedMessageIds.add(messageId);
      }
    });
  }

  /// Called when the user taps a message
  /// If in selection mode, toggles selection/deselection of that message.
  void onMessageTap(String messageId) {
    if (!isSelectionMode) return;

    setState(() {
      if (selectedMessageIds.contains(messageId)) {
        selectedMessageIds.remove(messageId);
        // Exit selection mode if no messages are selected
        if (selectedMessageIds.isEmpty) isSelectionMode = false;
      } else {
        selectedMessageIds.add(messageId);
      }
    });
  }

  /// Cancels selection mode and clears the selected messages list.
  void cancelSelectionMode() {
    setState(() {
      isSelectionMode = false;
      selectedMessageIds.clear();
      deleteForEveryone = false;
    });
  }

  /// Deletes all selected messages.
  /// If "delete for everyone" is checked, messages will be removed for both users.
  void deleteSelectedMessages() {
    for (var messageId in selectedMessageIds) {
      ref.read(chatControllerProvider).deleteMessage(
            context,
            messageId: messageId,
            recieverUserId: widget.uid,
            deleteForEveryone: deleteForEveryone,
            isGroupChat: widget.isGroupChat,
          );
    }

    // Exit selection mode after deletion
    cancelSelectionMode();
  }

  /// Shows a confirmation dialog before deleting messages.
  /// Allows user to check "Delete for everyone".
  void showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete messages"),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Are you sure you want to delete the selected messages?"),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: deleteForEveryone,
                        onChanged: (val) {
                          setStateDialog(() {
                            deleteForEveryone = val ?? false;
                          });
                        },
                      ),
                      const Text("Delete for everyone"),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                deleteSelectedMessages();
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  /// Builds the app bar dynamically depending on whether we’re in selection mode.
  /// selection mode=> means user has long pressed message to delete, reply...
  PreferredSizeWidget _buildAppBar() {

    // 🟦 First Determine subtitle  based on showOnlineStatus,
    // i.e to show if recipent is online or not
    
  String subtitleText = "Offline"; // default

  if (widget.isGroupChat) {
    // Groups always show static text, i.e "Group Chat"
    subtitleText = "Group Chat";
  } else {
    // One-to-one chat
    final currentUser = ref.watch(userDataAuthProvider).asData?.value;

    if (currentUser != null) {
      if (!currentUser.showOnlineStatus) {
        // 🟥 User disabled online visibility → always show Offline
        subtitleText = "turn your own status first";
      } else {
        // 🟩 User allows online visibility → show actual state
        if (receiverUser != null) {
           if (receiverUser!.showOnlineStatus) {
                       subtitleText = receiverUser!.isOnline ? "Online" : "Offline";

           }
        else {  subtitleText ="-";}
        }
      }
    }
  }
    
    
    //check if the user has selected a message by long press and entered selection mode
    if (isSelectionMode) {
      return AppBar(
        backgroundColor: appBarColor,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: cancelSelectionMode,
        ),
        title: Text("${selectedMessageIds.length} selected"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: showDeleteConfirmationDialog,
          ),
        ],
      );
    } else {


      
      return AppBar(
        backgroundColor: appBarColor,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.name,
              style: const TextStyle(fontSize: 18),
            ),
       
       
            
            Text(
              widget.isGroupChat ? "Group Chat" : subtitleText,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),

          ],

          

        ),
      
      centerTitle: false,
          actions: [

             IconButton(
              onPressed:() => makeCall(ref, context, !isVideoCall),
              icon: const Icon(Icons.call),
            ),
            
            IconButton(
              onPressed: () => makeCall(ref, context, isVideoCall),
              icon: const Icon(Icons.video_call),
            ),
           
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.more_vert),
            ),
          ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CallPickupScreen(
      scaffold: Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: ChatList(
              recieverUserId: widget.uid,
              isGroupChat: widget.isGroupChat,
              isSelectionMode: isSelectionMode,
              selectedMessageIds: selectedMessageIds,
              onMessageLongPress: onMessageLongPress,
              onMessageTap: onMessageTap,
            ),
          ),

          // Chat input or forward/reply options
          BottomChatField(
            recieverUserId: widget.uid,
            isGroupChat: widget.isGroupChat,
            isSelectionMode: isSelectionMode,
            onForwardPressed: () {
            },
          ),
        ],
      ),
    ));
  }
}



/************************* *
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_ui/common/utils/colors.dart';
import 'package:whatsapp_ui/common/widgets/loader.dart';
import 'package:whatsapp_ui/features/auth/controller/auth_controller.dart';
import 'package:whatsapp_ui/features/call/controller/call_controller.dart';
import 'package:whatsapp_ui/features/call/screens/call_pickup_screen.dart';
import 'package:whatsapp_ui/features/chat/widgets/bottom_chat_field.dart';
import 'package:whatsapp_ui/models/user_model.dart';
import 'package:whatsapp_ui/features/chat/widgets/chat_list.dart';

class MobileChatScreen extends ConsumerWidget {
  static const String routeName = '/mobile-chat-screen';
  final String name;
  final String uid;
  final bool isGroupChat;
  final String profilePic;
  
  const MobileChatScreen({
    super.key,
    required this.name,
    required this.uid,
    required this.isGroupChat,
    required this.profilePic,
  });

 final bool isVideoCall= false ;


  void makeCall(WidgetRef ref, BuildContext context, bool isVideoCall) {
    ref.read(callControllerProvider).makeCall(
          context,
          name,
          uid,
          profilePic,
          isGroupChat,
          isVideoCall,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // callPickUpScreen returns a strean builde that listens 
    //if there is incoming call( call collection is updated ) then it shows the callpickupscreen 
    return CallPickupScreen(
      scaffold: Scaffold(
        appBar: AppBar(
          backgroundColor: appBarColor,
          //the StreamBuilder<UserModel> is used to display online or offline on appBar
          title: isGroupChat
              ? Text(name)
              : StreamBuilder<UserModel>(
                  stream: ref.read(authControllerProvider).userDataById(uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Loader();
                    }
                    return Column(
                      children: [
                        Text(name),
                        Text(
                          snapshot.data!.isOnline ? 'online' : 'offline',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    );
                  }),
          centerTitle: false,
          actions: [
            IconButton(
              onPressed: () => makeCall(ref, context, !isVideoCall),
              icon: const Icon(Icons.video_call),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.call),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.more_vert),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ChatList(
                recieverUserId: uid,
                isGroupChat: isGroupChat,
              ),
            ),
            BottomChatField(
              recieverUserId: uid,
              isGroupChat: isGroupChat,
            ),
          ],
        ),
      ),
    );
  }
}
**********************/