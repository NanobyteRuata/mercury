import 'package:flutter/material.dart';
import 'package:mercury/utils/encryption_utils.dart';
import 'package:sms/sms.dart';

import '../extensions.dart';

class MessageTile extends StatelessWidget {
  final SmsMessage smsMessage;
  final bool decrypt;
  final String secretKey;

  MessageTile({Key key, @required this.smsMessage, this.decrypt = false, this.secretKey}) : super(key: key);

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
                _messageInfoText(context, smsMessage),
                _messageText(context, smsMessage),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _messageInfoText(BuildContext context, SmsMessage message) {
    final textStye = TextStyle(fontSize: 11, color: Theme.of(context).disabledColor);
    final sendDate = message.dateSent.formatTime();

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
