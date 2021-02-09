class Message {
  int threadId;
  String address;
  String sender;
  String body;
  MessageKind kind;
  DateTime date;
  DateTime dateSent;
  bool isRead;

  bool get isReceived => kind == MessageKind.Received;
}

enum MessageKind {
  Sent,
  Received,
  Draft,
}
