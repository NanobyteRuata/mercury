import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mercury/components/new_message_dialog.dart';
import 'package:mercury/models/contact.dart';
import 'package:mercury/screens/messages_screen.dart';
import 'package:mercury/services/contacts_db_service.dart';
import 'package:mercury/services/sms_service.dart';
import 'package:sms/sms.dart';

class HomeScreen extends StatefulWidget {
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<SmsThread> threads = [];
  List<Contact> contacts = [];
  SmsReceiver receiver = new SmsReceiver();
  SmsSender sender = new SmsSender();

  @override
  void initState() {
    _getThreads();
    _getContacts();
    receiver.onSmsReceived.listen(_onSmsChange);
    sender.onSmsDelivered.listen(_onSmsChange);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Builder(
        builder: (__) {
          return FloatingActionButton(
              child: Icon(Icons.add_comment),
              onPressed: () => showDialog(
                  context: context,
                  builder: (context) {
                    return NewMessageDialog();
                  }));
        },
      ),
      appBar: AppBar(
        title: Text("Mercury"),
        actions: [
          IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () async {
                await _getThreads();
                await _getContacts();
              })
        ],
      ),
      body: Container(
        child: DefaultTabController(
          length: 2,
          initialIndex: 0,
          child: Column(
            children: [
              TabBar(labelColor: Colors.blue, tabs: [
                Tab(
                  text: "All Messages",
                ),
                Tab(
                  text: "Contacts",
                ),
              ]),
              Expanded(
                  child: TabBarView(children: [
                threads.length == 0
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
                                  contacts
                                              .where((contact) =>
                                                  threads[index].address ==
                                                  contact.address)
                                              .length >
                                          0
                                      ? contacts
                                          .where((contact) =>
                                              threads[index].address ==
                                              contact.address)
                                          .first
                                          .name
                                      : threads[index].address,
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
                                            MessagesScreen(
                                              thread: threads[index],
                                            ))),
                              ),
                            ),
                          );
                        }),
                contacts == null
                    ? Center(
                        child: CircularProgressIndicator(),
                      )
                    : contacts.length == 0
                        ? Center(
                            child: Text("No contacts"),
                          )
                        : ListView.builder(
                            itemCount: contacts.length,
                            itemBuilder: (BuildContext context, int index) {
                              return Container(
                                decoration: BoxDecoration(
                                    border: Border(
                                        bottom:
                                            BorderSide(color: Colors.grey))),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.person,
                                      color: Colors.blue,
                                    ),
                                    title: Text(
                                      contacts[index].name,
                                    ),
                                    subtitle: Text(contacts[index].address),
                                    trailing: IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () async {
                                        bool status = await showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                                  content:
                                                      Text("Are you sure?"),
                                                  actions: [
                                                    TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context, false),
                                                        child: Text("No")),
                                                    TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context, true),
                                                        child: Text("Yes"))
                                                  ],
                                                ));
                                        if (status)
                                          await ContactsDbService.deleteContact(
                                              contacts[index].id);
                                        _getContacts();
                                      },
                                    ),
                                    onTap: () async {
                                      Navigator.push(
                                          context,
                                          new MaterialPageRoute(
                                              builder: (BuildContext context) =>
                                                  MessagesScreen(
                                                    contact: contacts[index],
                                                  )));
                                    },
                                  ),
                                ),
                              );
                            })
              ]))
            ],
          ),
        ),
      ),
    );
  }

  _getThreads() async {
    List<SmsThread> tempThreads = await SmsService.getAllThreads();
    setState(() => threads = tempThreads);
  }

  _getContacts() async {
    List<Contact> tempContacts = await ContactsDbService.getAllContacts();
    setState(() => contacts = tempContacts);
  }

  _onSmsChange(event) {
    _getContacts();
    // perform getThreads 5 times with 2 seconds interval
    // every time a new SMS is sent/recieved
    // because SmsThreads data is updated too late
    Timer timer = Timer.periodic(Duration(seconds: 2), (timer) {
      _getThreads();
    });
    Timer(Duration(seconds: 11), () {
      timer.cancel();
    });
  }
}
