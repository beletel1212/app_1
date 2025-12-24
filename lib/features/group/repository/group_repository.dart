import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
//import 'package:whatsapp_ui/common/repositories/common_firebase_storage_repository.dart';
import 'package:whatsapp_ui/common/utils/utils.dart';
import 'package:whatsapp_ui/models/group.dart' as model;

final groupRepositoryProvider = Provider(
  (ref) => GroupRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
    ref: ref,
  ),
);

class GroupRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final Ref ref;
  GroupRepository({
    required this.firestore,
    required this.auth,
    required this.ref,
  });

  void createGroup(BuildContext context, String name, File profilePic,
      List<Contact> selectedContact) async {
      


    try {

      List<String> uids = [];
      var groupId = const Uuid().v1();
      
      
      for (int i = 0; i < selectedContact.length; i++) {

              String plus ="+";
              String phone =plus+selectedContact[i].phones[0].number.replaceAll(RegExp(r'\D'), ''); 

        var userCollection = await firestore
            .collection('users')
            .where(
              'phoneNumber',
              isEqualTo: phone,
            )
            .get();

        if (userCollection.docs.isNotEmpty && userCollection.docs[0].exists) {
          uids.add(userCollection.docs[0].data()['uid']);
        }
      }

      
     
      String profileUrl; 
      // commented out until we get firebase storage access,
      // when accessible uncomment the import of the common_firebase_storage_repository
     /*  profileUrl= await ref
          .read(commonFirebaseStorageRepositoryProvider)
          .storeFileToFirebase(
            'group/$groupId',
            profilePic,
          );*/
////////
///until you enable firebase storage use photoUrl
     String photoUrl = 'https://png.pngitem.com/pimgs/s/649-6490124_katie-notopoulos-katienotopoulos-i-write-about-tech-round.png';

    profileUrl = photoUrl;
////////////////
      model.Group group = model.Group(
        senderId: auth.currentUser!.uid,
        name: name,
        groupId: groupId,
        lastMessage: '',
        groupPic: profileUrl,
        membersUid: [auth.currentUser!.uid, ...uids],
        timeSent: DateTime.now(),
      );

      await firestore.collection('groups').doc(groupId).set(group.toMap());


          // 🔹 Add groupId to creator's groupId array
      await firestore.collection('users').doc(auth.currentUser!.uid).update({
        'groupId': FieldValue.arrayUnion([groupId]),
      });

      // 🔹 Add groupId to each member's groupId array
      for (final uid in uids) {
        await firestore.collection('users').doc(uid).update({
          'groupId': FieldValue.arrayUnion([groupId]),
        });
      }




                  // 🔹 Create groupMembers subcollection entries, 
                  //for stooring unread message count for each group member
            final allMembers = [auth.currentUser!.uid, ...uids];

            for (final memberId in allMembers) {
              await firestore
                  .collection('groups')
                  .doc(groupId)
                  .collection('groupMembers')
                  .doc(memberId) // userId as docId = fast access
                  .set({
                'userId': memberId,
                'groupId': groupId,
                'unreadCount': 0, // starts clean
                'isAdmin': memberId == auth.currentUser!.uid, // creator is admin
                'joinedAt': FieldValue.serverTimestamp(),
              });
            }



    } catch (e) {
       if (context.mounted) {
      showSnackBar(context: context, content: e.toString());
    }
    }



  }
}
