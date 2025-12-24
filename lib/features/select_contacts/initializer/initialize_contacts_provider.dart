import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_ui/features/select_contacts/repository/select_contact_repository.dart';

/// 🟩 Provider that triggers automatic Firestore sync on app start
final initializeContactsProvider = FutureProvider<void>((ref) async {
  final repo = ref.watch(selectContactsRepositoryProvider);
  await repo.initializeRegisteredContactsOnAppStart();
});
