import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:sms/sms.dart';

import '../extensions.dart';
import '../models/contact.dart';
import '../models/message_thread.dart';
import '../components/new_message_dialog.dart';
import '../screens/messages_screen.dart';
import '../services/contacts_db_service.dart';
import '../services/sms_service.dart';

class HomeScreen extends StatefulWidget {
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final _smsService = GetIt.instance.get<SmsService>();
  final _contactsDbService = GetIt.instance.get<ContactsDbService>();

  List<MessageThread> threads = [];
  List<Contact> contacts = [];
  SmsReceiver receiver = new SmsReceiver();
  SmsSender sender = new SmsSender();
  TabController _tabController;
  int _navigationIndex = 0;

  @override
  void initState() {
    _getContacts();
    _getThreads();
    _tabController = new TabController(vsync: this, length: 2);
    receiver.onSmsReceived.listen(_onSmsChange);
    sender.onSmsDelivered.listen(_onSmsChange);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: 0,
      child: Scaffold(
        appBar: AppBar(
          title: _navigationIndex == 0 ? Text('Messages') : Text('Contacts'),
        ),
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  _messageListView(),
                  _contactListView(),
                ],
              ),
            )
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          onTap: (index) {
            setState(() {
              _tabController.index = index;
              _navigationIndex = index;
            });
            if (index == 0) {
              setState(() => threads = null);
              _getThreads();
            }
            if (index == 1) {
              setState(() => contacts = null);
              _getContacts();
            }
          },
          elevation: 5,
          currentIndex: _navigationIndex,
          items: [
            BottomNavigationBarItem(icon: new Icon(Icons.chat_rounded), label: 'Messages'),
            BottomNavigationBarItem(icon: new Icon(Icons.people), label: 'Contacts'),
          ],
        ),
        floatingActionButton: Builder(
          builder: (__) {
            return FloatingActionButton(
              child: Icon(Icons.add_comment),
              onPressed: () => showDialog(
                context: context,
                builder: (context) => NewMessageDialog(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _messageListView() {
    return RefreshIndicator(
      onRefresh: () async => await _getThreads(),
      child: Scrollbar(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            if (threads == null || threads.length == 0) {
              return ListView.builder(
                itemCount: 1,
                itemBuilder: (context, index) {
                  return Container(
                    height: constraints.maxHeight,
                    child: Center(
                      child: threads == null ? CircularProgressIndicator() : Text("No messages"),
                    ),
                  );
                },
              );
            }

            return ListView.separated(
              itemCount: threads.length,
              separatorBuilder: (_, __) => Divider(height: 1),
              itemBuilder: (context, index) => _messageListTile(threads[index]),
            );
          },
        ),
      ),
    );
  }

  ListTile _messageListTile(MessageThread thread) {
    final trailingTextStyle = TextStyle(color: Theme.of(context).disabledColor, fontSize: 11);
    return ListTile(
      leading: Icon(Icons.comment, color: Colors.blue),
      title: Text(
        contacts.where((contact) => thread.address == contact.address).length > 0 ? contacts.where((contact) => thread.address == contact.address).first.name : thread.address,
      ),
      subtitle: Text(
        thread.lastMessage.body,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(thread.lastMessage.date.formatTime(), style: trailingTextStyle),
          Text(thread.lastMessage.date.formatDate(), style: trailingTextStyle),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          new MaterialPageRoute(
            builder: (BuildContext context) => MessagesScreen(thread: thread),
          ),
        );
      },
    );
  }

  Widget _contactListView() {
    return RefreshIndicator(
      onRefresh: () async => await _getContacts(),
      child: Scrollbar(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            if (contacts == null || contacts.length == 0) {
              return ListView.builder(
                itemCount: 1,
                itemBuilder: (context, index) {
                  return Container(
                    height: constraints.maxHeight,
                    child: Center(
                      child: threads == null ? CircularProgressIndicator() : Text("No contacts"),
                    ),
                  );
                },
              );
            }

            return ListView.separated(
              separatorBuilder: (_, __) => Divider(height: 1),
              itemCount: contacts.length,
              itemBuilder: (context, index) => _contactListTile(contacts[index]),
            );
          },
        ),
      ),
    );
  }

  Widget _contactListTile(Contact contact) {
    return ListTile(
      leading: Icon(Icons.person, color: Colors.blue),
      title: Text(contact.name),
      subtitle: Text(contact.address),
      trailing: IconButton(
        icon: Icon(Icons.delete, color: Colors.red),
        onPressed: () async {
          bool status = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              content: Text("Are you sure?"),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: Text("No")),
                TextButton(onPressed: () => Navigator.pop(context, true), child: Text("Yes"))
              ],
            ),
          );
          if (status) await _contactsDbService.deleteContact(contact.id);
          _getContacts();
        },
      ),
      onTap: () async {
        Navigator.push(
          context,
          new MaterialPageRoute(
            builder: (BuildContext context) => MessagesScreen(contact: contact),
          ),
        );
      },
    );
  }

  _getThreads() async {
    final tempThreads = await _smsService.getAllThreads();
    setState(() => threads = tempThreads);
  }

  _getContacts() async {
    List<Contact> tempContacts = await _contactsDbService.getAllContacts();
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
