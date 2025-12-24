import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_ui/features/select_contacts/repository/select_contact_repository.dart';

/// 🟩 Provider that loads registered contacts (from Hive cache or Firestore)
///
/// This will re-fetch the registered contacts whenever the screen rebuilds.
/// You can also manually trigger a refresh by calling:
/// `ref.refresh(getRegisteredContactsProvider);`
final getRegisteredContactsProvider =
    FutureProvider<List<Contact>>((ref) async {
  final controller = ref.watch(selectContactControllerProvider);
  // Always refresh Firestore on first screen load to get the latest users
  return await controller.getRegisteredContacts(refreshFromFirestore: true);
});

/// 🟩 Main controller provider — manages logic between UI and repository
final selectContactControllerProvider = Provider((ref) {
  final selectContactRepository = ref.watch(selectContactsRepositoryProvider);
  return SelectContactController(
    ref: ref,
    selectContactRepository: selectContactRepository,
  );
});

/// 🟩 Controller that connects the UI (SelectContactScreen)
/// with the repository (SelectContactRepository).
class SelectContactController {
  final Ref ref;
  final SelectContactRepository selectContactRepository;

  SelectContactController({
    required this.ref,
    required this.selectContactRepository,
  });

  // ---------------------------------------------------------------------------
  /// 🟩 Fetch only registered contacts (those who are users of the app)
  ///
  /// If [refreshFromFirestore] = true, it will skip Hive and fetch fresh data
  /// from Firestore; otherwise, it will try to load from the cached Hive data.
  Future<List<Contact>> getRegisteredContacts({
    bool refreshFromFirestore = false,
  }) async {
    try {
      final contacts = await selectContactRepository.getRegisteredContacts(
        refreshFromFirestore: refreshFromFirestore,
      );
      return contacts;
    } catch (e) {
      debugPrint('❌ Error getting registered contacts: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  /// 🟩 When user taps a contact on the SelectContactScreen
  ///
  /// This calls repository.selectContact() which checks Firestore to confirm
  /// the contact is a registered app user, then navigates to MobileChatScreen.
  void selectContact(Contact selectedContact, BuildContext context) {
    selectContactRepository.selectContact(selectedContact, context);
  }

  // ---------------------------------------------------------------------------
  /// 🟩 Called when app resumes (via ContactsLifecycleListener)
  ///
  /// It refreshes contacts cache automatically to check if new users joined.
  Future<void> initializeRegisteredContactsOnAppStart() async {
    await selectContactRepository.initializeRegisteredContactsOnAppStart();
  }
}
