import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../extensions.dart';
import '../models/message.dart';

class MessageTile extends StatelessWidget {
  final Message smsMessage;
  final bool decrypt;
  final String secretKey;
  final Function onLongPress;

  MessageTile(
      {Key key,
      @required this.smsMessage,
      this.decrypt = false,
      this.secretKey,
      this.onLongPress})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: smsMessage.kind == MessageKind.Sent
              ? TextDirection.rtl
              : TextDirection.ltr,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: smsMessage.kind == MessageKind.Sent
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  _messageInfoText(context, smsMessage),
                  _messageText(context, smsMessage),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _messageInfoText(BuildContext context, Message message) {
    final textStye =
        TextStyle(fontSize: 11, color: Theme.of(context).disabledColor);
    final sendDate = message.dateSent.formatTime();

    if (message.kind == MessageKind.Sent) {
      return Text(sendDate, style: textStye);
    }

    return Text('${smsMessage.address}, $sendDate', style: textStye);
  }

  Widget _messageText(BuildContext context, Message message) {
    message.body = decrypt ? message.decryptedBody(secretKey) : message.body;
    return Container(
      padding: EdgeInsets.all(8),
      constraints:
          BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        color: _getMessageBubbleColor(message.kind, context),
      ),
      child: message.body.indexOf('img ') == 0
          ? Image.memory(
              gzip.decode(base64.decode(message.body.replaceFirst('img ', ''))))
          : Text(
              message.body,
              textAlign: message.kind == MessageKind.Sent
                  ? TextAlign.right
                  : TextAlign.left,
            ),
    );
  }

  _getMessageBubbleColor(MessageKind msgKind, BuildContext context) {
    if (msgKind == MessageKind.Sent) {
      return Theme.of(context).brightness == Brightness.light
          ? Colors.lightBlue[100]
          : Colors.lightBlue;
    } else {
      return Theme.of(context).cardColor;
    }
  }
}
