
// -----------------------------
// CALL PICKUP SCREEN (rewritten + commented)
// -----------------------------

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_ui/features/call/controller/call_controller.dart';
import 'package:whatsapp_ui/features/call/screens/call_screen.dart';
import 'package:whatsapp_ui/models/call.dart';

class CallPickupScreen extends ConsumerWidget {
  final Widget scaffold;
  const CallPickupScreen({
    super.key,
    required this.scaffold,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listens to a Firestore document stream exposed by your callController.
    return StreamBuilder<DocumentSnapshot>(
      stream: ref.watch(callControllerProvider).callStream,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.data() != null) {
          Call call = Call.fromMap(snapshot.data!.data() as Map<String, dynamic>);

          // If the current user is the receiver (hasDialled == false), show incoming UI
          if (!call.hasDialled) {
            return Scaffold(
              body: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Incoming Call',
                      style: TextStyle(
                        fontSize: 30,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 50),
                    CircleAvatar(
                      backgroundImage: NetworkImage(call.callerPic),
                      radius: 60,
                    ),
                    const SizedBox(height: 50),
                    Text(
                      call.callerName,
                      style: const TextStyle(
                        fontSize: 25,
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 75),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Reject call button
                        IconButton(
                          onPressed: () async {
                            // Keep naming and public api unchanged; call controller handles logic
                            ref.read(callControllerProvider).endCall(
                                  call.callerId,
                                  call.receiverId,
                                  context,
                                );
                          },
                          icon: const Icon(Icons.call_end, color: Colors.redAccent),
                        ),
                        const SizedBox(width: 25),
                        // Accept call button
                        IconButton(
                          onPressed: () async {
                            // 1) Mark the call as answered in backend/firestore so both
                            //    devices now know the call is active. We call the controller
                            //    method `updateCallAsAnswered` (you should implement this
                            //    in your callController if not present). We intentionally
                            //    *do not rename* the controller provider call here.
                            await ref.read(callControllerProvider).updateCallAsAnswered(call);

                            // 2) Navigate into the CallScreen which will now pick up
                            //    the updated `call.hasDialled` value and generate a
                            //    different UID (see CallScreen initState logic).
                            if(context.mounted){
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CallScreen(
                                  channelId: call.callId,
                                  call: call,
                                  isGroupChat: false,
                                  isVideoCall: call.isVideoCall,
                                ),
                              ),
                            );}
                          },
                          icon: const Icon(
                            Icons.call,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }
        }

        // Default: show the underlying scaffold (your normal app UI)
        return scaffold;
      },
    );
  }
}





/************************* *
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_ui/features/call/controller/call_controller.dart';
import 'package:whatsapp_ui/features/call/screens/call_screen.dart';
import 'package:whatsapp_ui/models/call.dart';

class CallPickupScreen extends ConsumerWidget {
  final Widget scaffold;
  const CallPickupScreen({
    super.key,
    required this.scaffold,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {

     // callPickUpScreen returns a strean builde that listens 
    //if there is incoming call( call collection is updated ) then it shows the callpickupscreen 
    return StreamBuilder<DocumentSnapshot>(
      stream: ref.watch(callControllerProvider).callStream,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.data() != null) {
          Call call =
              Call.fromMap(snapshot.data!.data() as Map<String, dynamic>);

         // check if user is call receiver, i.e hasDialled will be false 
          if (!call.hasDialled) {
            return Scaffold(
              body: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Incoming Call',
                      style: TextStyle(
                        fontSize: 30,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 50),
                    CircleAvatar(
                      backgroundImage: NetworkImage(call.callerPic),
                      radius: 60,
                    ),
                    const SizedBox(height: 50),
                    Text(
                      call.callerName,
                      style: const TextStyle(
                        fontSize: 25,
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 75),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.call_end,
                              color: Colors.redAccent),
                        ),
                        const SizedBox(width: 25),
                      IconButton(
                  onPressed: () {
                    ref.read(callControllerProvider).updateCallAsAnswered(call); // new
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CallScreen(
                          channelId: call.callId,
                          call: call,
                          isGroupChat: false,
                          isVideoCall: call.isVideoCall,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.call, color: Colors.green),
                ),
                  
                      ],
                    ),
                    
                  ],
                ),
              ),
            );
          }
        }

        // this is the mobileChatScreen scaffold, it is always diplyed untill call incomes
        return scaffold;
      },
    );
  }
}
*******************************************************/