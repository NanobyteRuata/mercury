import 'package:intl/intl.dart';
import 'package:sms/sms.dart';

extension SmsThreadExtensions on SmsThread {
  SmsMessage get lastMessage => this.messages[0];
}

extension DateTimeExtensions on DateTime {
  String formatDate() => DateFormat.yMMMd().format(this);
  String formatTime() => DateFormat.jm().format(this);
}
