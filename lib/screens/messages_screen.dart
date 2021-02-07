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
  List<SmsMessage> smsMessages = [];
  bool isShowEncrypted = false;
  TextEditingController keyController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController messageController = TextEditingController();
  SmsReceiver receiver = new SmsReceiver();
  Contact contact;

  @override
  void initState() {
    _checkContact();
    receiver.onSmsReceived.listen(_onSmsChanged);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(contact == null ? widget.thread.address : contact.name),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _getMessages)
        ],
      ),
      body: Column(
        children: [
          Card(
            child: ExpansionTile(
              leading: Icon(
                Icons.perm_contact_cal,
                color: Colors.blue,
              ),
              title: Text("Contact Details"),
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
                      TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                              prefixIcon: Icon(Icons.person),
                              hintText: contact != null
                                  ? contact.isGroup
                                      ? "Group name"
                                      : "Name"
                                  : "Name"),
                          onChanged: (value) => setState(() => {})),
                      if (widget.thread == null)
                        TextField(
                          controller: addressController,
                          maxLines: 2,
                          onChanged: (value) => setState(() {}),
                          decoration: InputDecoration(
                              prefixIcon: Icon(Icons.phone_android),
                              hintText:
                                  "Phone Numbers (seperated by commas \",\")"),
                        ),
                      Row(
                        children: [
                          Expanded(child: Container()),
                          TextButton(
                              onPressed: _saveContact, child: Text("Save"))
                        ],
                      )
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
                      color: messageController.text.length == 0
                          ? Colors.grey
                          : Colors.green,
                    ),
                    onPressed:
                        messageController.text.length == 0 ? null : _sendSms)
              ],
            ),
          )
        ],
      ),
    );
  }

  _getMessages() async {
    List<SmsMessage> tempMessages = [];
    if (widget.thread != null || (contact != null && !contact.isGroup)) {
      String tempAddress =
          widget.thread != null ? widget.thread.address : contact.address;
      tempMessages = await SmsService.getSMS(tempAddress);
    } else {
      for (String address in contact.address
          .split(',')
          .where((addressStr) => addressStr.trim() != "")) {
        tempMessages.addAll(await SmsService.getSMS(address));
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
    }
    setState(() {
      smsMessages = tempMessages;
    });
  }

  _saveContact() async {
    bool status = false;
    if (contact == null) {
      status = await ContactsDbService.saveContact(
          name: nameController.text,
          address: widget.thread.address,
          key: keyController.text,
          isGroup: false);
    } else {
      status = await ContactsDbService.updateContact(
          name: nameController.text,
          address: addressController.text,
          key: keyController.text,
          id: contact.id,
          isGroup: addressController.text
                  .split(',')
                  .where((addressStr) => addressStr.trim() != "")
                  .where((addressStr) => addressStr.trim() != "")
                  .length >
              1);
    }
    final snackBar =
        SnackBar(content: Text(status ? 'Save successful' : 'Unsuccessful'));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  _checkContact() async {
    Contact tempContact;
    if (widget.thread != null) {
      List<Contact> tempContactList = await ContactsDbService.getContactsWhere(
          address: widget.thread.address);
      if (tempContactList.length == 0) {
        String modifiedAddress = (widget.thread.address.indexOf('+959') == 0)
            ? widget.thread.address.replaceFirst('+959', '09')
            : (widget.thread.address.indexOf('09') == 0)
                ? widget.thread.address.replaceFirst('09', '+959')
                : widget.thread.address;
        tempContactList =
            await ContactsDbService.getContactsWhere(address: modifiedAddress);
      }
      if (tempContactList.length > 0) {
        tempContact = tempContactList.first;
      }
    } else {
      tempContact = widget.contact;
    }

    if (tempContact != null) {
      nameController.text = tempContact.name;
      keyController.text = tempContact.key;
      addressController.text = tempContact.address;
      setState(() {
        contact = tempContact;
        isShowEncrypted =
            (tempContact.key != null && tempContact.key.length == 8)
                ? true
                : false;
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
      List<String> addresses = contact.address
          .split(',')
          .where((addressStr) => addressStr.trim() != "");
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
      tempSmsMessage = await SmsService.sendNormalSMS(
          widget.thread != null
              ? widget.thread.address
              : contact.address
                  .split(',')
                  .where((addressStr) => addressStr.trim() != "")
                  .toList(),
          messageController.text);
    } else {
      tempSmsMessage = await SmsService.sendEncryptedSMS(
          widget.thread != null
              ? widget.thread.address
              : contact.address
                  .split(',')
                  .where((addressStr) => addressStr.trim() != "")
                  .toList(),
          messageController.text,
          keyController.text + keyController.text);
    }
    if (tempSmsMessage != null) {
      tempSmsMessage.kind = SmsMessageKind.Sent;
      _onSmsChanged(tempSmsMessage);
    }
    messageController.text = "";
  }
}
