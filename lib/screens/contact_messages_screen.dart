import 'package:flutter/material.dart';
import 'package:mercury/components/message.dart';
import 'package:mercury/utils/sms_utils.dart';
import 'package:sms/sms.dart';
// import 'package:sqflite/sqflite.dart';

class ContactMessagesScreen extends StatefulWidget {
  final SmsThread thread;
  final bool isGroupSMS;

  @override
  _ContactMessagesScreenState createState() => _ContactMessagesScreenState();

  ContactMessagesScreen({Key key, this.thread, this.isGroupSMS = false})
      : super(key: key);
}

class _ContactMessagesScreenState extends State<ContactMessagesScreen> {
  List<SmsMessage> smsMessages = [];
  bool isShowEncrypted = false;
  TextEditingController keyController = TextEditingController();
  TextEditingController multiAddressController = TextEditingController();
  TextEditingController messageController = TextEditingController();
  SmsQuery query = new SmsQuery();
  SmsReceiver receiver = new SmsReceiver();

  _getMessages() async {
    if (widget.isGroupSMS &&
        !(multiAddressController.text.split(",").length == 1 &&
            multiAddressController.text.split(",").first == "")) {
      List<SmsMessage> tempMessages = [];
      for (String address in multiAddressController.text.split(',')) {
        tempMessages.addAll(await SmsUtil.getSMS(address));
      }
      tempMessages.sort((a, b) => a.date.isBefore(b.date) ? 1 : -1);
      SmsMessage previousSms;
      tempMessages.removeWhere((element) {
        if (previousSms != null &&
            element.kind == SmsMessageKind.Sent &&
            element.sender.trim() == previousSms.sender.trim() &&
            element.body.trim() == previousSms.body.trim()) {
          return true;
        }
        previousSms = element;
        return false;
      });
      setState(() {
        smsMessages = tempMessages;
      });
    } else {
      query.queryThreads([widget.thread.threadId],
          kinds: [SmsQueryKind.Inbox, SmsQueryKind.Sent]).then((value) {
        value.first.messages.sort((a, b) => a.date.isBefore(b.date) ? 1 : -1);
        setState(() {
          smsMessages = value.first.messages;
        });
      });
    }
  }

  _onSmsChanged(SmsMessage event) {
    List<SmsMessage> tempSmsMessages = smsMessages;
    Function updateMessages = () {
      tempSmsMessages.insert(0, event);
      setState(() {
        smsMessages = tempSmsMessages;
      });
    };
    if (!widget.isGroupSMS && event.address == widget.thread.address) {
      updateMessages();
    } else {
      List<String> addresses = multiAddressController.text.split(',');
      for (String address in addresses) {
        address = address.trim();
        String modifiedAddress = (address.indexOf('+959') == 0)
            ? address.replaceFirst('+959', '09')
            : (address.indexOf('09') == 0)
                ? address.replaceFirst('09', '+959')
                : address;
        if (event.address.trim() == address.trim() ||
            event.address.trim() == modifiedAddress.trim()) {
          updateMessages();
        }
      }
    }
  }

  _sendSms() async {
    SmsMessage tempSmsMessage;
    if (keyController.text.length != 8) {
      tempSmsMessage = await SmsUtil.sendNormalSMS(
          widget.isGroupSMS
              ? multiAddressController.text.split(',').toList()
              : [widget.thread.address],
          messageController.text);
    } else {
      tempSmsMessage = await SmsUtil.sendEncryptedSMS(
          widget.isGroupSMS
              ? multiAddressController.text.split(',').toList()
              : [widget.thread.address],
          messageController.text,
          keyController.text + keyController.text);
    }
    if (tempSmsMessage != null) {
      tempSmsMessage.kind = SmsMessageKind.Sent;
      _onSmsChanged(tempSmsMessage);
    }
    messageController.text = "";
  }

  @override
  void initState() {
    if (!widget.isGroupSMS) {
      smsMessages = widget.thread.messages;
    }
    receiver.onSmsReceived.listen(_onSmsChanged);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isGroupSMS ? "Group SMS" : widget.thread.address),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _getMessages)
        ],
      ),
      body: Column(
        children: [
          Card(
            child: ExpansionTile(
              leading: Icon(
                Icons.construction_sharp,
                color: Colors.blue,
              ),
              title: Text("Configurations"),
              children: [
                Padding(
                  padding: EdgeInsets.all(4),
                  child: Column(
                    children: [
                      TextField(
                        controller: keyController,
                        decoration: InputDecoration(
                            prefixIcon: Icon(Icons.vpn_key),
                            hintText: "Secret Key (8 characters)"),
                        maxLength: 8,
                        onChanged: (value) {
                          setState(() {
                            isShowEncrypted = (value.length < 8) ? false : true;
                          });
                        },
                      ),
                      if (widget.isGroupSMS)
                        TextField(
                          controller: multiAddressController,
                          maxLines: 2,
                          decoration: InputDecoration(
                              prefixIcon: Icon(Icons.phone_android),
                              hintText:
                                  "Phone Numbers (seperated by commas \",\")"),
                        ),
                      if (widget.isGroupSMS)
                        TextButton(
                            child: Text("Get Messages"),
                            onPressed: _getMessages),
                    ],
                  ),
                )
              ],
            ),
          ),
          Expanded(
              child: ListView.builder(
                  reverse: true,
                  itemCount: smsMessages.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Message(
                      secretKey: keyController.text,
                      decrypt: isShowEncrypted,
                      smsMessage: smsMessages[index],
                    );
                  })),
          Container(
            decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.blue))),
            child: Row(
              children: [
                Expanded(
                    child: Padding(
                  padding: EdgeInsets.all(8),
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(hintText: "Message..."),
                    onChanged: (value) => setState(() {}),
                  ),
                )),
                IconButton(
                    icon: Icon(
                      Icons.send,
                      color: (!widget.isGroupSMS &&
                                  messageController.text.length < 1) ||
                              (widget.isGroupSMS &&
                                  (multiAddressController.text
                                                  .split(",")
                                                  .length ==
                                              1 &&
                                          multiAddressController.text
                                                  .split(",")
                                                  .first ==
                                              "" ||
                                      messageController.text.length < 1))
                          ? Colors.grey
                          : Colors.green,
                    ),
                    onPressed: (!widget.isGroupSMS &&
                                messageController.text.length < 1) ||
                            (widget.isGroupSMS &&
                                multiAddressController.text.split(",").length ==
                                    1 &&
                                multiAddressController.text.split(",").first ==
                                    "" &&
                                messageController.text.length < 1)
                        ? null
                        : _sendSms)
              ],
            ),
          )
        ],
      ),
    );
  }
}
