import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mercury/screens/contact_messages_screen.dart';
import 'package:mercury/utils/sms_utils.dart';
import 'package:sms/sms.dart';

class MessageListScreen extends StatefulWidget {
  _MessageListScreenState createState() => _MessageListScreenState();
}

class _MessageListScreenState extends State<MessageListScreen> {
  List<SmsThread> threads = [];
  SmsQuery query = new SmsQuery();
  SmsReceiver receiver = new SmsReceiver();
  SmsSender sender = new SmsSender();

  bool composeLoading = false;

  TextEditingController secretKeyController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController messageController = TextEditingController();

  @override
  void initState() {
    _getThreads();
    // perform getThreads 5 times with 2 seconds interval
    // every time a new SMS is recieved
    // because SmsQuery is updated only after some time
    receiver.onSmsReceived.listen(_onSmsChange);
    sender.onSmsDelivered.listen(_onSmsChange);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mercury the messenger"),
        actions: [
          IconButton(
              icon: Icon(Icons.group),
              onPressed: () => Navigator.push(
                  context,
                  new MaterialPageRoute(
                      builder: (BuildContext context) => ContactMessagesScreen(
                            isGroupSMS: true,
                          )))),
          IconButton(icon: Icon(Icons.refresh), onPressed: _getThreads)
        ],
      ),
      body: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: ExpansionTile(
                leading: Icon(
                  Icons.add_comment_rounded,
                  color: Colors.blue,
                ),
                title: Text("Compose New"),
                children: [
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Column(
                      children: [
                        TextField(
                          controller: secretKeyController,
                          maxLength: 8,
                          onChanged: (value) => setState(() {}),
                          decoration: InputDecoration(
                              prefixIcon: Icon(Icons.vpn_key),
                              hintText: "Secret Key (8 characters)"),
                        ),
                        TextField(
                          controller: addressController,
                          onChanged: (value) => setState(() {}),
                          maxLines: 2,
                          decoration: InputDecoration(
                              prefixIcon: Icon(Icons.phone_android),
                              hintText:
                                  "Phone Numbers (seperated by commas \",\")"),
                        ),
                        TextField(
                          controller: messageController,
                          onChanged: (value) => setState(() {}),
                          maxLines: 5,
                          decoration: InputDecoration(
                              prefixIcon: Icon(Icons.format_align_left),
                              hintText: "Message"),
                        ),
                        Row(
                          children: [
                            Expanded(child: Container()),
                            IconButton(
                                icon: Icon(Icons.send,
                                    color: (addressController.text.length < 1 ||
                                            messageController.text.length < 1 ||
                                            composeLoading)
                                        ? Colors.grey
                                        : Colors.green),
                                onPressed: (addressController.text.length < 1 ||
                                        messageController.text.length < 1 ||
                                        composeLoading)
                                    ? null
                                    : () async {
                                        setState(() {
                                          composeLoading = true;
                                        });
                                        if (secretKeyController.text.length ==
                                            8) {
                                          await SmsUtil.sendEncryptedSMS(
                                              addressController.text.split(','),
                                              messageController.text,
                                              secretKeyController.text +
                                                  secretKeyController.text);
                                        } else {
                                          await SmsUtil.sendNormalSMS(
                                              addressController.text.split(','),
                                              messageController.text);
                                        }
                                        addressController.text = "";
                                        messageController.text = "";
                                        secretKeyController.text = "";
                                        setState(() {
                                          composeLoading = false;
                                        });
                                        Timer(Duration(seconds: 2),
                                            () => _getThreads());
                                      })
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Text(
                "All Messages",
                style: TextStyle(fontSize: 20),
              ),
            ),
            Expanded(
                child: threads.length == 0
                    ? Center(
                        child: CircularProgressIndicator(),
                      )
                    : ListView.builder(
                        itemCount: threads.length,
                        itemBuilder: (BuildContext context, int index) {
                          return Container(
                            decoration: BoxDecoration(
                                border: Border(
                                    bottom: BorderSide(color: Colors.grey))),
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                leading: Icon(
                                  Icons.comment,
                                  color: Colors.blue,
                                ),
                                isThreeLine: true,
                                title: Text(
                                  threads[index].address,
                                ),
                                subtitle: Text(
                                  threads[index].messages[0].body,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      DateFormat.jm().format(
                                          threads[index].messages[0].date),
                                      style: TextStyle(
                                          color: Colors.grey[800],
                                          fontSize: 11),
                                    ),
                                    Text(
                                      DateFormat.yMMMMd().format(
                                          threads[index].messages[0].date),
                                      style: TextStyle(
                                          color: Colors.grey[800],
                                          fontSize: 11),
                                    )
                                  ],
                                ),
                                onTap: () => Navigator.push(
                                    context,
                                    new MaterialPageRoute(
                                        builder: (BuildContext context) =>
                                            ContactMessagesScreen(
                                              thread: threads[index],
                                            ))),
                              ),
                            ),
                          );
                        }))
          ],
        ),
      ),
    );
  }

  _getThreads() async {
    List<SmsThread> tempThreads = await query.getAllThreads;
    setState(() {
      threads = tempThreads
          .where((element) =>
              element.address.startsWith('+959') ||
              element.address.startsWith('09'))
          .toList();
    });
  }

  _onSmsChange(event) {
    Timer timer = Timer.periodic(Duration(seconds: 2), (timer) {
      _getThreads();
    });
    Timer(Duration(seconds: 11), () {
      timer.cancel();
    });
  }
}
