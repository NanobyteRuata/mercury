import 'package:intl/intl.dart';
import 'package:sms/sms.dart';

extension SmsThreadExtensions on SmsThread {
  SmsMessage get lastMessage => this.messages[0];
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
