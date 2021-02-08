import 'package:flutter/material.dart';
import 'package:mercury/components/message.dart';
import 'package:mercury/models/contact.dart';
import 'package:mercury/services/contacts_db_service.dart';
import 'package:mercury/services/sms_service.dart';
import 'package:sms/sms.dart';

class MessagesScreen extends StatefulWidget {
  final SmsThread thread;
  final Contact contact;

  @override
  _MessagesScreenState createState() => _MessagesScreenState();

  MessagesScreen({Key key, this.thread, this.contact}) : super(key: key);
}

class _MessagesScreenState extends State<MessagesScreen> {
  final key = new GlobalKey<ScaffoldState>();
  List<SmsMessage> smsMessages = [];
  bool isShowEncrypted = false;
  final _keyController = TextEditingController();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _messageController = TextEditingController();
  final _receiver = new SmsReceiver();
  Contact contact;

  @override
  void initState() {
    _checkContact();
    _receiver.onSmsReceived.listen(_onSmsChanged);
    super.initState();
  }

  @override
  void dispose() {
    _keyController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _messageController.dispose();
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
            icon: Icon(Icons.refresh),
            onPressed: _getMessages,
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
    return Card(
      child: ExpansionTile(
        leading: Icon(Icons.perm_contact_cal, color: Colors.blue),
        title: Text("Contact Details"),
        children: [
          Padding(
            padding: EdgeInsets.all(4),
            child: Column(
              children: [
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
          )
        ],
      ),
    );
  }

  Widget _messageListView() {
    SmsMessage prevMsg;
    return Expanded(
      child: Scrollbar(
        child: ListView.builder(
          reverse: true,
          itemCount: smsMessages.length,
          padding: EdgeInsets.symmetric(horizontal: 8),
          itemBuilder: (BuildContext context, int index) {
            final message = smsMessages[index];
            final dateChanged = _isDateChange(message.dateSent, prevMsg?.dateSent);
            prevMsg = message;

            return Message(
              secretKey: _keyController.text,
              decrypt: isShowEncrypted,
              smsMessage: message,
              showDate: dateChanged,
            );
          },
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
                controller: _messageController,
                decoration: InputDecoration(hintText: "Message..."),
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

  bool _isDateChange(DateTime date1, DateTime date2) {
    return date1?.month != date2?.month && date1?.day != date2?.day;
  }

  _getMessages() async {
    List<SmsMessage> tempMessages = [];
    if (widget.thread != null || (contact != null && !contact.isGroup)) {
      String tempAddress = widget.thread != null ? widget.thread.address : contact.address;
      tempMessages = await SmsService.getSMS(tempAddress);
    } else {
      for (String address in contact.address.split(',').where((addressStr) => addressStr.trim() != "")) {
        tempMessages.addAll(await SmsService.getSMS(address));
      }
      tempMessages.sort((a, b) => a.date.isBefore(b.date) ? 1 : -1);
      SmsMessage previousSms;
      tempMessages.removeWhere((element) {
        if (previousSms != null && element.kind == SmsMessageKind.Sent && element.sender.trim() == previousSms.sender.trim() && element.body.trim() == previousSms.body.trim()) {
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
      status = await ContactsDbService.saveContact(name: _nameController.text, address: widget.thread.address, key: _keyController.text, isGroup: false);
    } else {
      status = await ContactsDbService.updateContact(
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
      List<Contact> tempContactList = await ContactsDbService.getContactsWhere(address: widget.thread.address);
      if (tempContactList.length == 0) {
        String modifiedAddress = (widget.thread.address.indexOf('+959') == 0)
            ? widget.thread.address.replaceFirst('+959', '09')
            : (widget.thread.address.indexOf('09') == 0)
                ? widget.thread.address.replaceFirst('09', '+959')
                : widget.thread.address;
        tempContactList = await ContactsDbService.getContactsWhere(address: modifiedAddress);
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

  _onSmsChanged(SmsMessage event) {
    List<SmsMessage> tempSmsMessages = smsMessages;
    Function updateMessages = () {
      tempSmsMessages.insert(0, event);
      setState(() {
        smsMessages = tempSmsMessages;
      });
    };
    if (widget.thread != null && event.address == widget.thread.address) {
      updateMessages();
    } else {
      List<String> addresses = contact.address.split(',').where((addressStr) => addressStr.trim() != "");
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
    SmsMessage tempSmsMessage;
    if (_keyController.text.length != 8) {
      tempSmsMessage = await SmsService.sendNormalSMS(
          widget.thread != null ? [widget.thread.address] : contact.address.split(',').where((addressStr) => addressStr.trim() != "").toList(), _messageController.text);
    } else {
      tempSmsMessage = await SmsService.sendEncryptedSMS(
          widget.thread != null ? [widget.thread.address] : contact.address.split(',').where((addressStr) => addressStr.trim() != "").toList(),
          _messageController.text,
          _keyController.text + _keyController.text);
    }
    if (tempSmsMessage != null) {
      tempSmsMessage.kind = SmsMessageKind.Sent;
      _onSmsChanged(tempSmsMessage);
    }
    _messageController.text = "";
  }
}
