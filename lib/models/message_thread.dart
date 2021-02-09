import 'message.dart';

class MessageThread {
  int threadId;
  String address;
  List<Message> messages = <Message>[];

  Message get lastMessage => messages.first;
}
