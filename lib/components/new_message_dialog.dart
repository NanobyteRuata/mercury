import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../models/message.dart';
import '../services/contacts_db_service.dart';
import '../services/sms_service.dart';

class NewMessageDialog extends StatefulWidget {
  _NewMessageDialogState createState() => _NewMessageDialogState();
}

class _NewMessageDialogState extends State<NewMessageDialog> {
  final _smsService = GetIt.instance.get<SmsService>();
  final _contactsDbService = GetIt.instance.get<ContactsDbService>();

  bool isSaveContact = false;

  TextEditingController secretKeyController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController messageController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "New Message",
                  style: TextStyle(fontSize: 20, color: Colors.blue),
                ),
                Padding(padding: EdgeInsets.only(top: 8)),
                if (isSaveContact)
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(prefixIcon: Icon(Icons.person), hintText: "Name or group name"),
                  ),
                TextField(
                  controller: addressController,
                  maxLines: 2,
                  decoration: InputDecoration(prefixIcon: Icon(Icons.phone_android), hintText: "Phones (seperated by commas \",\")"),
                ),
                TextField(
                  controller: messageController,
                  maxLines: 5,
                  decoration: InputDecoration(prefixIcon: Icon(Icons.format_align_left), hintText: "Message"),
                ),
                TextField(
                  controller: secretKeyController,
                  maxLength: 16,
                  decoration: InputDecoration(prefixIcon: Icon(Icons.vpn_key), hintText: "Secret Key"),
                ),
                Row(
                  children: [Checkbox(value: isSaveContact, onChanged: (value) => setState(() => isSaveContact = value)), Text("Create new contact")],
                )
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                  child: IconButton(
                icon: Icon(
                  Icons.clear,
                  color: Colors.red,
                ),
                onPressed: () => Navigator.pop(context),
              )),
              Expanded(
                child: IconButton(
                    icon: Icon(Icons.send, color: Colors.green),
                    onPressed: () async {
                      if (isSaveContact && nameController.text.length < 1) {
                        showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                                  content: Text(
                                    "Please write name",
                                  ),
                                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("OK"))],
                                ));
                        return;
                      }
                      if (addressController.text.length < 1) {
                        showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                                  content: Text("Please write phone number"),
                                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("OK"))],
                                ));
                        return;
                      }
                      if (messageController.text.length < 1) {
                        showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                                  content: Text("Please write a message"),
                                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("OK"))],
                                ));
                        return;
                      }
                      if (secretKeyController.text.length > 16) {
                        showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                                  content: Text("Secret key cannot be more than 16 characters long"),
                                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("OK"))],
                                ));
                        return;
                      }
                      Message result;
                      if (secretKeyController.text.length > 0) {
                        result = await _smsService.sendEncryptedSMS(addressController.text.split(','), messageController.text, secretKeyController.text);
                      } else {
                        result = await _smsService.sendNormalSMS(addressController.text.split(','), messageController.text);
                      }
                      if (result != null && isSaveContact)
                        _contactsDbService.saveContact(
                          name: nameController.text,
                          address: addressController.text,
                          key: secretKeyController.text,
                          isGroup: addressController.text.split(',').length > 1,
                        );
                      nameController.text = "";
                      addressController.text = "";
                      messageController.text = "";
                      secretKeyController.text = "";
                      Navigator.pop(context);
                    }),
              )
            ],
          )
        ],
      ),
    );
  }
}
