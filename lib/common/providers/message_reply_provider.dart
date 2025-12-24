import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_ui/common/enums/message_enum.dart';

class MessageReply {
  final String message;
  final bool isMe;
  final MessageEnum messageEnum;

  MessageReply(this.message, this.isMe, this.messageEnum);
}

/*final messageReplyProvider = StateProvider<MessageReply?>((ref) => null);*/

//*********** jojo migrated from StateProvider to Notifier, ChatGPT can help you ********
// Notifier class
class MessageReplyNotifier extends Notifier<MessageReply?> {
  @override
  MessageReply? build() => null;

  void setReply(MessageReply reply) {
    state = reply;
  }

  void clear() {
    state = null;
  }
}

// Provider
final messageReplyProvider =
    NotifierProvider<MessageReplyNotifier, MessageReply?>(
  MessageReplyNotifier.new,
);

