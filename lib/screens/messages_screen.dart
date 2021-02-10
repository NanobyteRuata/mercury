import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:sms/sms.dart';

import '../extensions.dart';
import '../models/contact.dart';
import '../models/message.dart';
import '../models/message_thread.dart';
import '../components/message_tile.dart';
import '../services/contacts_db_service.dart';
import '../services/sms_service.dart';

class MessagesScreen extends StatefulWidget {
  final MessageThread thread;
  final Contact contact;

  @override
  _MessagesScreenState createState() => _MessagesScreenState();

  MessagesScreen({Key key, this.thread, this.contact}) : super(key: key);
}

class _MessagesScreenState extends State<MessagesScreen> {
  final key = new GlobalKey<ScaffoldState>();
  final _smsService = GetIt.instance.get<SmsService>();
  final _contactsDbService = GetIt.instance.get<ContactsDbService>();

  List<Message> smsMessages = [];
  bool isShowEncrypted = false;
  final _keyController = TextEditingController();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _messageController = TextEditingController();
  final _receiver = new SmsReceiver();
  bool _hideContactDetails = true;
  Contact contact;
  StreamSubscription<Message> _messageSub;

  @override
  void initState() {
    _checkContact();
    _messageSub = _receiver.onSmsReceived
        .transform(StreamTransformer<SmsMessage, Message>.fromHandlers(
          handleData: (data, sink) => sink.add(data.toMessage()),
        ))
        .listen(_onSmsChanged);
    super.initState();
  }

  @override
  void dispose() {
    _keyController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _messageController.dispose();
    _messageSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: key,
      appBar: AppBar(
        title: Text(contact == null ? widget.thread.address : contact.name),
        actions: [
          IconButton(
            icon: Icon(Icons.perm_contact_cal),
            onPressed: () => setState(() => _hideContactDetails = !_hideContactDetails),
          ),
        ],
      ),
      body: Column(
        children: [
          _contactDetails(),
          _messageListView(),
          _messageComposer(),
        ],
      ),
    );
  }

  Widget _contactDetails() {
    return Offstage(
      offstage: _hideContactDetails,
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(4),
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.perm_contact_cal, color: Colors.blue),
                title: Text("Contact Details"),
                trailing: IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => setState(() => _hideContactDetails = !_hideContactDetails),
                ),
              ),
              TextField(
                controller: _keyController,
                decoration: InputDecoration(prefixIcon: Icon(Icons.vpn_key), hintText: "Secret Key (8 characters)"),
                maxLength: 8,
                onChanged: (value) {
                  setState(() => isShowEncrypted = (value.length < 8) ? false : true);
                },
              ),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                    prefixIcon: Icon(Icons.person),
                    hintText: contact != null
                        ? contact.isGroup
                            ? "Group name"
                            : "Name"
                        : "Name"),
                onChanged: (value) => setState(() => {}),
              ),
              if (widget.thread == null)
                TextField(
                  controller: _addressController,
                  maxLines: 2,
                  onChanged: (value) => setState(() {}),
                  decoration: InputDecoration(prefixIcon: Icon(Icons.phone_android), hintText: "Phone Numbers (seperated by commas \",\")"),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: _saveContact, child: Text("Save")),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _messageListView() {
    return Expanded(
      child: RefreshIndicator(
        onRefresh: () => _getMessages(),
        child: Scrollbar(
          child: ListView.builder(
            reverse: true,
            itemCount: smsMessages.length,
            padding: EdgeInsets.symmetric(horizontal: 8),
            itemBuilder: (BuildContext context, int index) {
              final prevMsg = index == 0 ? null : smsMessages[index - 1];
              final message = smsMessages[index];
              final dateChanged = _isDateChange((message.dateSent ?? message.date), (prevMsg?.dateSent ?? prevMsg?.date));

              return Column(
                children: [
                  if (index == smsMessages.length - 1) _dateDivider(context, message), // first and last message
                  MessageTile(
                    secretKey: _keyController.text,
                    decrypt: isShowEncrypted,
                    smsMessage: message,
                    onLongPress: () async {
                      await Clipboard.setData(ClipboardData(text: message.decryptedBody(_keyController.text)));
                      key.currentState.showSnackBar(SnackBar(
                        width: 150,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
                        behavior: SnackBarBehavior.floating,
                        content: Text('Message copied', textAlign: TextAlign.center),
                      ));
                    },
                  ),
                  if (dateChanged && prevMsg != null) _dateDivider(context, prevMsg),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _messageComposer() {
    return Container(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.blue))),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: TextField(
                maxLines: null,
                controller: _messageController,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  hintText: "Message...",
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: _messageController.text.length == 0 ? Colors.grey : Colors.green),
            onPressed: _messageController.text.length == 0 ? null : _sendSms,
          )
        ],
      ),
    );
  }

  Widget _dateDivider(BuildContext context, Message message) {
    final line = Expanded(child: Container(width: double.maxFinite, height: 0.5, color: Theme.of(context).focusColor));
    final dateSend = (message.dateSent ?? message.date).formatDate();
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          line,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(dateSend, style: TextStyle(fontSize: 10, color: Theme.of(context).disabledColor)),
          ),
          line,
        ],
      ),
    );
  }

  bool _isDateChange(DateTime currentDate, DateTime previousDate) {
    return currentDate?.month != previousDate?.month || currentDate?.day != previousDate?.day;
  }

  _getMessages() async {
    List<Message> tempMessages = [];
    if (widget.thread != null || (contact != null && !contact.isGroup)) {
      String tempAddress = widget.thread != null ? widget.thread.address : contact.address;
      tempMessages = await _smsService.getSMS(tempAddress);
    } else {
      for (String address in contact.address.split(',').where((addressStr) => addressStr.trim() != "")) {
        tempMessages.addAll(await _smsService.getSMS(address));
      }
      tempMessages.sort((a, b) => a.date.isBefore(b.date) ? 1 : -1);
      Message previousSms;
      tempMessages.removeWhere((element) {
        if (previousSms != null && element.kind == MessageKind.Sent && element.sender.trim() == previousSms.sender.trim() && element.body.trim() == previousSms.body.trim()) {
          return true;
        }
        previousSms = element;
        return false;
      });
    }
    setState(() {
      smsMessages = tempMessages;
    });
  }

  _saveContact() async {
    bool status = false;
    if (contact == null) {
      status = await _contactsDbService.saveContact(name: _nameController.text, address: widget.thread.address, key: _keyController.text, isGroup: false);
    } else {
      status = await _contactsDbService.updateContact(
          name: _nameController.text,
          address: _addressController.text,
          key: _keyController.text,
          id: contact.id,
          isGroup: _addressController.text.split(',').where((addressStr) => addressStr.trim() != "").where((addressStr) => addressStr.trim() != "").length > 1);
    }
    final snackBar = SnackBar(content: Text(status ? 'Save successful' : 'Unsuccessful'));
    key.currentState.showSnackBar(snackBar);
  }

  _checkContact() async {
    Contact tempContact;
    if (widget.thread != null) {
      List<Contact> tempContactList = await _contactsDbService.getContactsWhere(address: widget.thread.address);
      if (tempContactList.length == 0) {
        String modifiedAddress = (widget.thread.address.indexOf('+959') == 0)
            ? widget.thread.address.replaceFirst('+959', '09')
            : (widget.thread.address.indexOf('09') == 0)
                ? widget.thread.address.replaceFirst('09', '+959')
                : widget.thread.address;
        tempContactList = await _contactsDbService.getContactsWhere(address: modifiedAddress);
      }
      if (tempContactList.length > 0) {
        tempContact = tempContactList.first;
      }
    } else {
      tempContact = widget.contact;
    }

    if (tempContact != null) {
      _nameController.text = tempContact.name;
      _keyController.text = tempContact.key;
      _addressController.text = tempContact.address;
      setState(() {
        contact = tempContact;
        isShowEncrypted = (tempContact.key != null && tempContact.key.length == 8) ? true : false;
      });
    }

    _getMessages();
  }

  _onSmsChanged(Message event) {
    List<Message> tempSmsMessages = smsMessages;
    Function updateMessages = () {
      tempSmsMessages.insert(0, event);
      setState(() {
        smsMessages = tempSmsMessages;
      });
    };
    if (widget.thread != null && event.address == widget.thread.address) {
      updateMessages();
    } else {
      List<String> addresses = contact.address.split(',').where((addressStr) => addressStr.trim() != "").toList();
      for (String address in addresses) {
        address = address.trim();
        String modifiedAddress = (address.indexOf('+959') == 0)
            ? address.replaceFirst('+959', '09')
            : (address.indexOf('09') == 0)
                ? address.replaceFirst('09', '+959')
                : address;
        if (event.address.trim() == address.trim() || event.address.trim() == modifiedAddress.trim()) {
          updateMessages();
        }
      }
    }
  }

  _sendSms() async {
    Message tempSmsMessage;
    if (_keyController.text.length != 8) {
      tempSmsMessage = await _smsService.sendNormalSMS(
          widget.thread != null ? [widget.thread.address] : contact.address.split(',').where((addressStr) => addressStr.trim() != "").toList(), _messageController.text);
    } else {
      tempSmsMessage = await _smsService.sendEncryptedSMS(
          widget.thread != null ? [widget.thread.address] : contact.address.split(',').where((addressStr) => addressStr.trim() != "").toList(),
          _messageController.text,
          _keyController.text + _keyController.text);
    }
    if (tempSmsMessage != null) {
      tempSmsMessage.kind = MessageKind.Sent;
      tempSmsMessage.date = DateTime.now();
      _onSmsChanged(tempSmsMessage);
    }
    _messageController.text = "";
  }
}
