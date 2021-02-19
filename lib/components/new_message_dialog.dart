import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../models/message.dart';
import '../services/contacts_db_service.dart';
import '../services/sms_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

class NewMessageDialog extends StatefulWidget {
  final address;

  NewMessageDialog({Key key, this.address}) : super(key: key);

  _NewMessageDialogState createState() => _NewMessageDialogState();
}

class _NewMessageDialogState extends State<NewMessageDialog> {
  String _imageFileString;
  final ImagePicker _picker = ImagePicker();
  int costPerSMS = 15; // in MMK (Default for MPT)

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
      child: SingleChildScrollView(
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
                      decoration: InputDecoration(
                          prefixIcon: Icon(Icons.person),
                          hintText: "Name or group name"),
                    ),
                  if (widget.address == null)
                    TextField(
                      controller: addressController,
                      maxLines: 2,
                      decoration: InputDecoration(
                          prefixIcon: Icon(Icons.phone_android),
                          hintText: "Phones (seperated by commas \",\")"),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: _imageFileString == null
                            ? widget.address == null
                                ? TextField(
                                    controller: messageController,
                                    maxLines: 5,
                                    decoration: InputDecoration(
                                        prefixIcon:
                                            Icon(Icons.format_align_left),
                                        hintText: "Message"),
                                  )
                                : Image.asset('assets/ImagePlaceholder.png')
                            : Image.memory(gzip.decode(base64.decode(
                                _imageFileString.replaceFirst('img ', '')))),
                      ),
                      IconButton(
                        icon: Icon(_imageFileString == null
                            ? Icons.image
                            : Icons.clear),
                        onPressed: _imageFileString == null
                            ? () async {
                                try {
                                  var widthAndHeight = await showDialog(
                                      context: context,
                                      builder: (context) {
                                        final widthController =
                                            TextEditingController(text: "320");
                                        final heightController =
                                            TextEditingController(text: "320");
                                        final costPerSMSController =
                                            TextEditingController(
                                                text: costPerSMS.toString());
                                        return Dialog(
                                          child: Padding(
                                            padding: EdgeInsets.all(8),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                TextField(
                                                  controller: widthController,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  decoration: InputDecoration(
                                                      prefixText: "Width",
                                                      suffixText: "px"),
                                                ),
                                                TextField(
                                                  controller: heightController,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  decoration: InputDecoration(
                                                      prefixText: "Height",
                                                      suffixText: "px"),
                                                ),
                                                TextField(
                                                  controller:
                                                      costPerSMSController,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  decoration: InputDecoration(
                                                      prefixText: "Cost/SMS",
                                                      suffixText: "MMK"),
                                                ),
                                                ElevatedButton(
                                                  child: Text("Ok"),
                                                  onPressed: () {
                                                    Navigator.pop(context, [
                                                      int.parse(
                                                          widthController.text),
                                                      int.parse(heightController
                                                          .text),
                                                      int.parse(
                                                          costPerSMSController
                                                              .text)
                                                    ]);
                                                  },
                                                )
                                              ],
                                            ),
                                          ),
                                        );
                                      });
                                  if (widthAndHeight == null) return;
                                  var cropImageWidth = widthAndHeight[0];
                                  var cropImageHeight = widthAndHeight[1];
                                  setState(() {
                                    costPerSMS = widthAndHeight[2];
                                  });
                                  var pickedFile = await _picker.getImage(
                                      source: ImageSource.gallery,
                                      imageQuality: 50);

                                  File croppedImage =
                                      await ImageCropper.cropImage(
                                          sourcePath: pickedFile.path,
                                          maxWidth: cropImageWidth,
                                          maxHeight: cropImageHeight,
                                          compressQuality: 50,
                                          aspectRatio: CropAspectRatio(
                                              ratioX: double.parse(
                                                  cropImageWidth.toString()),
                                              ratioY: double.parse(
                                                  cropImageHeight.toString())));
                                  if (croppedImage == null) return;

                                  pickedFile = PickedFile(croppedImage.path);

                                  String imgString = base64.encode(gzip
                                      .encode(await pickedFile.readAsBytes()));

                                  setState(() {
                                    _imageFileString = "img " + imgString;
                                  });
                                } catch (e) {
                                  setState(() {
                                    print(e);
                                  });
                                }
                              }
                            : () => setState(() {
                                  _imageFileString = null;
                                }),
                      )
                    ],
                  ),
                  if (_imageFileString != null)
                    Text("SMS counts: " +
                        (_imageFileString.length / 160).ceil().toString() +
                        " * " +
                        costPerSMS.toString() +
                        "MMK = " +
                        ((_imageFileString.length / 160).ceil() * costPerSMS)
                            .toString() +
                        "MMK"),
                  if (_imageFileString == null && widget.address == null)
                    TextField(
                      controller: secretKeyController,
                      maxLength: 16,
                      onChanged: (value) => setState(() {}),
                      decoration: InputDecoration(
                          prefixIcon: Icon(Icons.vpn_key),
                          hintText: "Secret Key"),
                    ),
                  if (widget.address == null)
                    Row(
                      children: [
                        Checkbox(
                            value: isSaveContact,
                            onChanged: (value) =>
                                setState(() => isSaveContact = value)),
                        Text("Create new contact")
                      ],
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
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: Text("OK"))
                                    ],
                                  ));
                          return;
                        }
                        if (addressController.text.length < 1 &&
                            widget.address == null) {
                          showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                    content: Text("Please write phone number"),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: Text("OK"))
                                    ],
                                  ));
                          return;
                        }
                        if (messageController.text.length < 1 &&
                            _imageFileString == null) {
                          showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                    content: Text("Please write a message"),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: Text("OK"))
                                    ],
                                  ));
                          return;
                        }
                        if (secretKeyController.text.length > 16) {
                          showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                    content: Text(
                                        "Secret key cannot be more than 16 characters long"),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: Text("OK"))
                                    ],
                                  ));
                          return;
                        }
                        Message result;
                        if (secretKeyController.text.length > 0) {
                          result = await _smsService.sendEncryptedSMS(
                              addressController.text.split(','),
                              messageController.text,
                              secretKeyController.text);
                        } else {
                          result = await _smsService.sendNormalSMS(
                              widget.address == null
                                  ? addressController.text.split(',')
                                  : widget.address,
                              _imageFileString == null
                                  ? messageController.text
                                  : _imageFileString);
                        }
                        if (result != null && isSaveContact)
                          _contactsDbService.saveContact(
                            name: nameController.text,
                            address: addressController.text,
                            key: secretKeyController.text,
                            isGroup:
                                addressController.text.split(',').length > 1,
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
      ),
    );
  }
}
