import 'package:intl/intl.dart';
import 'package:sms/sms.dart';

import 'models/message_thread.dart';
import 'models/message.dart';
import 'utils/encryption_utils.dart';

extension SmsMessageExtensions on SmsMessage {
  Message toMessage() {
    return Message()
      ..threadId = this.threadId
      ..address = this.address
      ..sender = this.sender
      ..body = this.body
      ..kind = this.kind.toMessageKind()
      ..date = this.date
      ..dateSent = this.dateSent
      ..isRead = this.isRead;
  }
}

extension SmsMessageKindExtensions on SmsMessageKind {
  MessageKind toMessageKind() {
    switch (this) {
      case SmsMessageKind.Sent:
        return MessageKind.Sent;
      case SmsMessageKind.Received:
        return MessageKind.Received;
      case SmsMessageKind.Draft:
        return MessageKind.Draft;
    }
    return null;
  }
}

extension SmsMessagesExtensions on Iterable<SmsMessage> {
  List<Message> toMessages() {
    try {
      final messages = this.map((x) => x.toMessage()).toList();
      return messages;
    } catch (e) {
      print(e);
    }
    return <Message>[];
  }
}

extension SmsThreadExtensions on SmsThread {
  SmsMessage get lastMessage => this.messages[0];
  MessageThread toMessageThread() {
    return MessageThread()
      ..threadId = this.threadId
      ..address = this.address
      ..messages = this.messages.toMessages();
  }
}

extension SmsThreadsExtensions on Iterable<SmsThread> {
  List<MessageThread> toMessageThreads() {
    return this.map((x) => x.toMessageThread()).toList();
  }
}

extension MessageExtendions on Message {
  String decryptedBody(secretKey) => EncryptionUtil.decrypt(secretKey, this.body ?? '');
}

extension DateTimeExtensions on DateTime {
  String formatDate() {
    try {
      return DateFormat.yMMMd().format(this);
    } catch (e) {
      return '';
    }
  }

  String formatTime() {
    try {
      return DateFormat.jm().format(this);
    } catch (e) {
      return '';
    }
  }

  String formatDateTime() {
    try {
      return DateFormat.jm().add_yMMMd().format(this);
    } catch (e) {
      return '';
    }
  }
}

extension AddressExtensions on String {
  String modifiedAddress() {
    return (this.indexOf('+959') == 0)
            ? this.replaceFirst('+959', '09')
            : (this.indexOf('09') == 0)
                ? this.replaceFirst('09', '+959')
                : this;
  }
}
