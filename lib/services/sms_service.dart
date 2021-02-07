import 'package:mercury/utils/encryption_utils.dart';
import 'package:sms/sms.dart';

class SmsService {
  static final SmsQuery query = new SmsQuery();
  static final SmsSender sender = new SmsSender();

  static Future<SmsMessage> sendNormalSMS(
      List<String> phoneNumbers, String message) async {
    try {
      SmsMessage smsMessage;
      for (String phoneNumber in phoneNumbers)
        smsMessage = await sender.sendSms(new SmsMessage(phoneNumber, message));
      return smsMessage;
    } catch (e) {
      print(e);
      return null;
    }
  }

  static Future<SmsMessage> sendEncryptedSMS(
      List<String> phoneNumbers, String message, String key) async {
    try {
      SmsMessage smsMessage;
      for (String phoneNumber in phoneNumbers)
        smsMessage = await sender.sendSms(
            new SmsMessage(phoneNumber, EncryptionUtil.encrypt(key, message)));
      return smsMessage;
    } catch (e) {
      print(e);
      return null;
    }
  }

  static Future<List<SmsMessage>> getSMS(String phoneNumber) async {
    try {
      // trim for no space
      phoneNumber = phoneNumber.trim();
      // if phoneNumber is with country code,
      // set modifiedPhoneNumber to be without country code
      // and vice versa
      String modifiedPhoneNumber = (phoneNumber.indexOf('+959') == 0)
          ? phoneNumber.replaceFirst('+959', '09')
          : (phoneNumber.indexOf('09') == 0)
              ? phoneNumber.replaceFirst('09', '+959')
              : phoneNumber;

      // get SMS of incoming phone number as with or without country code
      List<SmsMessage> smsMessages = await query.querySms(
          address: phoneNumber,
          count: 1,
          kinds: [SmsQueryKind.Inbox, SmsQueryKind.Sent]);
      List<SmsMessage> smsMessagesWithModified = await query.querySms(
          address: modifiedPhoneNumber,
          count: 1,
          kinds: [SmsQueryKind.Inbox, SmsQueryKind.Sent]);

      smsMessages.addAll(smsMessagesWithModified);

      if (smsMessages.length > 0) {
        List<SmsThread> tempThreads = await query.queryThreads(
            [smsMessages.first.threadId],
            kinds: [SmsQueryKind.Inbox, SmsQueryKind.Sent]);
        smsMessages = tempThreads.first.messages;
      }

      return smsMessages;
    } catch (e) {
      print(e);
      return [];
    }
  }

  static Future<List<SmsThread>> getAllThreads() async {
    return (await query.getAllThreads)
        .where((element) =>
            element.address.startsWith('+959') ||
            element.address.startsWith('09'))
        .toList();
  }
}
