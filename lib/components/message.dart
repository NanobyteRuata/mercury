import 'package:flutter/material.dart';
import 'package:mercury/utils/encryption_utils.dart';
import 'package:sms/sms.dart';
import 'package:intl/intl.dart' as Intl;

class Message extends StatelessWidget {
  final SmsMessage smsMessage;
  final bool decrypt;
  final String secretKey;

  Message(
      {Key key,
      @required this.smsMessage,
      this.decrypt = false,
      this.secretKey})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: smsMessage.kind == SmsMessageKind.Sent
          ? TextDirection.rtl
          : TextDirection.ltr,
      children: [
        Container(
          constraints:
              BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: smsMessage.kind == SmsMessageKind.Sent
                ? Colors.blue
                : Colors.grey[200],
          ),
          margin: EdgeInsets.symmetric(vertical: 8),
          padding: EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: smsMessage.kind == SmsMessageKind.Sent
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (smsMessage.kind == SmsMessageKind.Received)
                Text(
                  smsMessage.address,
                  style: TextStyle(color: Colors.blue, fontSize: 11),
                ),
              if (smsMessage.kind == SmsMessageKind.Received)
                Padding(padding: EdgeInsets.only(top: 5)),
              Text(
                decrypt
                    ? EncryptionUtil.decrypt(
                        secretKey + secretKey, smsMessage.body)
                    : smsMessage.body,
                textAlign: smsMessage.kind == SmsMessageKind.Sent
                    ? TextAlign.right
                    : TextAlign.left,
              ),
              Padding(padding: EdgeInsets.only(top: 5)),
              Text(
                Intl.DateFormat.jm().format(smsMessage.date),
                style: TextStyle(color: Colors.grey[800], fontSize: 11),
              ),
              Text(
                Intl.DateFormat.yMMMMd().format(smsMessage.date),
                style: TextStyle(color: Colors.grey[800], fontSize: 11),
              )
            ],
          ),
        ),
        Expanded(child: Container())
      ],
    );
  }
}
