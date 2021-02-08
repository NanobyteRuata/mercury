import 'package:flutter/material.dart';
import 'package:mercury/utils/encryption_utils.dart';
import 'package:sms/sms.dart';

import '../extensions.dart';

class Message extends StatelessWidget {
  final SmsMessage smsMessage;
  final bool decrypt;
  final String secretKey;
  final bool showDate;

  Message({Key key, @required this.smsMessage, this.decrypt = false, this.secretKey, this.showDate}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: smsMessage.kind == SmsMessageKind.Sent ? TextDirection.rtl : TextDirection.ltr,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: smsMessage.kind == SmsMessageKind.Sent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (showDate) _dateDivider(context, smsMessage),
                _messageInfoText(context, smsMessage),
                _messageText(context, smsMessage),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _dateDivider(BuildContext context, SmsMessage message) {
    final line = Expanded(child: Container(width: double.maxFinite, height: 0.5, color: Theme.of(context).focusColor));
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      width: MediaQuery.of(context).size.width - 32,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          line,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(message.dateSent.formatDate(), style: TextStyle(fontSize: 10, color: Theme.of(context).disabledColor)),
          ),
          line,
        ],
      ),
    );
  }

  Widget _messageInfoText(BuildContext context, SmsMessage message) {
    final textStye = TextStyle(fontSize: 11, color: Theme.of(context).disabledColor);
    final sendDate = message.date.formatTime();
    if (message.kind == SmsMessageKind.Sent) {
      return Text(sendDate, style: textStye);
    }

    return Text('${smsMessage.address}, $sendDate', style: textStye);
  }

  Widget _messageText(BuildContext context, SmsMessage message) {
    return Container(
      padding: EdgeInsets.all(8),
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        color: message.kind == SmsMessageKind.Sent ? Colors.lightBlue[100] : Theme.of(context).cardColor,
      ),
      child: Text(
        decrypt ? EncryptionUtil.decrypt(secretKey + secretKey, message.body) : message.body,
        textAlign: message.kind == SmsMessageKind.Sent ? TextAlign.right : TextAlign.left,
      ),
    );
  }
}
