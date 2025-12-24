import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:whatsapp_ui/models/user_model.dart';
import 'package:whatsapp_ui/common/utils/utils.dart';
import 'package:whatsapp_ui/features/chat/screens/mobile_chat_screen.dart';

/// 🟩 Provider to access this repository anywhere using Riverpod
final selectContactsRepositoryProvider = Provider(
  (ref) => SelectContactRepository(firestore: FirebaseFirestore.instance),
);

class SelectContactRepository {
  final FirebaseFirestore firestore;

  SelectContactRepository({required this.firestore});

  // ---------------------------------------------------------------------------
  // 🟩 Convert a flutter_contacts.Contact -> Map<String, dynamic> for Hive storage
  Map<String, dynamic> contactToMap(Contact contact) {
    return {
      'id': contact.id,
      'displayName': contact.displayName,
      'firstName': contact.name.first,
      'lastName': contact.name.last,
      'phones': contact.phones.map((p) => p.number).toList(),
    };
  }

  // 🟩 Convert back a stored map -> flutter_contacts.Contact
  Contact contactFromMap(Map<String, dynamic> map) {
    return Contact(
      id: map['id'] ?? '',
      displayName: map['displayName'] ?? '',
      name: Name(
        first: map['firstName'] ?? '',
        last: map['lastName'] ?? '',
      ),
      phones: (map['phones'] as List<dynamic>? ?? [])
          .map((number) => Phone(number.toString()))
          .toList(),
    );
  }

  // ---------------------------------------------------------------------------
  /// 🟩 Called at app start to initialize Hive and update local cache
  Future<void> initializeRegisteredContactsOnAppStart() async {
    try {
      final box = await Hive.openBox('registered_contacts');
      final updatedContacts = await getRegisteredContactsFromFirestore();

      // Store as a list of maps
      await box.put('contacts', updatedContacts.map(contactToMap).toList());
      debugPrint('✅ Contacts cache initialized with ${updatedContacts.length} items');
    } catch (e) {
      debugPrint('❌ Error initializing registered contacts: $e');
    }
  }

  // ---------------------------------------------------------------------------
  /// 🟩 Fetches all users from Firestore and matches them with phone contacts
  Future<List<Contact>> getRegisteredContactsFromFirestore() async {
    List<Contact> phoneContacts = [];
    List<Contact> registeredContacts = [];

    try {
      // Request contact permission and load contacts
      if (await FlutterContacts.requestPermission()) {
        phoneContacts = await FlutterContacts.getContacts(withProperties: true);
      }

      // Fetch all registered users
      var userCollection = await firestore.collection('users').get();
      final registeredNumbers = userCollection.docs
          .map((doc) => UserModel.fromMap(doc.data())
              .phoneNumber
              .replaceAll(RegExp(r'\D'), ''))
          .toSet();

      // Match with device contacts
      for (var contact in phoneContacts) {
        final number = contact.phones.isNotEmpty
            ? contact.phones.first.number.replaceAll(RegExp(r'\D'), '')
            : '';

        if (registeredNumbers.contains(number)) {
          registeredContacts.add(contact);
        }
      }
    } catch (e) {
      debugPrint('❌ Error fetching registered contacts: $e');
    }

    return registeredContacts;
  }

  // ---------------------------------------------------------------------------
  /// 🟩 Loads contacts either from Hive (cache) or from Firestore
  Future<List<Contact>> getRegisteredContacts({bool refreshFromFirestore = false}) async {
    final box = await Hive.openBox('registered_contacts');

    // If cache is empty or user wants refresh, fetch from Firestore
    if (refreshFromFirestore || !box.containsKey('contacts')) {
      final contacts = await getRegisteredContactsFromFirestore();
      await box.put('contacts', contacts.map(contactToMap).toList());
      return contacts;
    }

    // Otherwise, load from local cache
    final cachedData = box.get('contacts', defaultValue: []) as List;
    return cachedData
        .map((map) => contactFromMap(Map<String, dynamic>.from(map)))
        .toList();
  }

  // ---------------------------------------------------------------------------
  /// 🟩 When user taps a contact (navigate to chat if registered)
  void selectContact(Contact selectedContact, BuildContext context) async {
    try {
      var userCollection = await firestore.collection('users').get();
      bool isFound = false;
      bool isGroupChat = false;

      for (var document in userCollection.docs) {
        var userData = UserModel.fromMap(document.data());
        String selectedPhoneNum =
            selectedContact.phones[0].number.replaceAll(RegExp(r'\D'), '');

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
                'profilePic': userData.profilePic,
              },
            );
          }
        }
      }

      if (!isFound && context.mounted) {
        showSnackBar(context: context, content: 'This number does not exist on this app');
      }
    } catch (e) {
      debugPrint('❌ Error selecting contact: $e');
    }
  }
}
