class Message {
  int threadId;
  String address;
  String sender;
  String body;
  MessageKind kind;
  DateTime date;
  DateTime dateSent;
  bool isRead;

  Message({
    this.threadId,
    this.address,
    this.sender,
    this.body,
    this.kind,
    this.date,
    this.dateSent,
    this.isRead,
  });

  bool get isReceived => kind == MessageKind.Received;
}

enum MessageKind {
  Sent,
  Received,
  Draft,
}
