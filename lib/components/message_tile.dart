import 'package:flutter/material.dart';

import '../extensions.dart';
import '../models/message.dart';
import '../utils/encryption_utils.dart';

class MessageTile extends StatelessWidget {
  final Message smsMessage;
  final bool decrypt;
  final String secretKey;

  MessageTile({Key key, @required this.smsMessage, this.decrypt = false, this.secretKey}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: smsMessage.kind == MessageKind.Sent ? TextDirection.rtl : TextDirection.ltr,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: smsMessage.kind == MessageKind.Sent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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

  Widget _messageInfoText(BuildContext context, Message message) {
    final textStye = TextStyle(fontSize: 11, color: Theme.of(context).disabledColor);
    final sendDate = message.dateSent.formatTime();

    if (message.kind == MessageKind.Sent) {
      return Text(sendDate, style: textStye);
    }

    return Text('${smsMessage.address}, $sendDate', style: textStye);
  }

  Widget _messageText(BuildContext context, Message message) {
    return Container(
      padding: EdgeInsets.all(8),
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        color: message.kind == MessageKind.Sent ? Colors.lightBlue[100] : Theme.of(context).cardColor,
      ),
      child: Text(
        decrypt ? EncryptionUtil.decrypt(secretKey + secretKey, message.body) : message.body,
        textAlign: message.kind == MessageKind.Sent ? TextAlign.right : TextAlign.left,
      ),
    );
  }
}
