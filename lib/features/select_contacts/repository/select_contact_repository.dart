//import 'dart:nativewrappers/_internal/vm/lib/internal_patch.dart'; //<jo
//import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:whatsapp_ui/common/utils/utils.dart';
import 'package:whatsapp_ui/models/user_model.dart';
import 'package:whatsapp_ui/features/chat/screens/mobile_chat_screen.dart';

final selectContactsRepositoryProvider = Provider(
  (ref) => SelectContactRepository(
    firestore: FirebaseFirestore.instance,
  ),
);

class SelectContactRepository {
  final FirebaseFirestore firestore;

  SelectContactRepository({
    required this.firestore,
  });


  // to get all the contacts in the Phone
  Future<List<Contact>> getContacts() async {
    List<Contact> contacts = [];
    try {
      if (await FlutterContacts.requestPermission()) {
        contacts = await FlutterContacts.getContacts(withProperties: true);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    return contacts;
  }


// to check if a selected contact from phone exits in firebase firestore, i.e registered 
  void selectContact(Contact selectedContact, BuildContext context) async {
    try {
      var userCollection = await firestore.collection('users').get();
      bool isFound = false;
      bool isGroupChat = false;
      //to see selected number and number on firebase s and fb are used <<jo
      //String s="";
      //String fb ="";

      for (var document in userCollection.docs) {
        var userData = UserModel.fromMap(document.data());
        // phones[0] means if we saved multiple numbers for one contact e.g work, personal. 
        // remove empty space if it exists in the number, 
        String selectedPhoneNum = selectedContact.phones[0].number.
        replaceAll(RegExp(r'\D'), '');
          
         // s= selectedPhoneNum;
          //fb= userData.phoneNumber;

        if (selectedPhoneNum == userData.phoneNumber.replaceAll(RegExp(r'\D'), '')) {
          isFound = true;
           if (context.mounted) {
          Navigator.pushNamed(
            context,
            MobileChatScreen.routeName,
            arguments: {
              'name': userData.name,
              'uid': userData.uid,
              'isGroupChat': isGroupChat,
              'profilePic':'https://png.pngitem.com/pimgs/s/649-6490124_katie-notopoulos-katienotopoulos-i-write-about-tech-round.png',
//userData.profilePic
            },
          );
           }
        }
      
       
      
      }


     
      if (!isFound) {
         if (context.mounted) {
        showSnackBar(
          context: context,
          content: 'This number does not exist on this app ',
        );
        
        
         }
      }
    } catch (e) {
                    Fluttertoast.showToast(msg: e.toString());

      //showSnackBar(context: context, content: e.toString());
    }
  }
}
