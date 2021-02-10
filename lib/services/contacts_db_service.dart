import 'package:injectable/injectable.dart';

import '../models/contact.dart';
import '../services/base_db_service.dart';

@singleton
class ContactsDbService {
  Future<List<Contact>> getAllContacts() async {
    List<Contact> contactList = [];
    List<Map> contactMaplist = await BaseDbService.database.rawQuery('SELECT * FROM Contacts');
    for (Map contactMap in contactMaplist) {
      contactList.add(new Contact.fromMap(contactMap));
    }
    return contactList;
  }

  Future<List<Contact>> getContactsWhere({String id, String name, String address, bool isGroup}) async {
    List<Contact> contactList = [];
    List<String> conditions = [];
    if (id != null || name != null || address != null || isGroup != null) {
      if (id != null) conditions.add("id=$id");
      if (name != null) conditions.add("name=\"$name\"");
      if (address != null) conditions.add("address=\"$address\"");
      if (isGroup != null) conditions.add("isGroup=$isGroup");
    }

    List<Map> contactMaplist = await BaseDbService.database.rawQuery('SELECT * FROM Contacts ${conditions.length > 0 ? "WHERE " + conditions.join(" AND ") : ""}');
    for (Map contactMap in contactMaplist) {
      contactList.add(new Contact.fromMap(contactMap));
    }
    return contactList;
  }

  Future<bool> saveContact({String name, String address, String key, bool isGroup}) async {
    try {
      await BaseDbService.database.transaction((txn) async {
        await txn.rawInsert('INSERT INTO Contacts(name, address, key, isGroup) VALUES(?, ?, ?, ?)', [name, address, key, isGroup ? 1 : 0]);
      });
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<bool> updateContact({int id, String name, String address, String key, bool isGroup}) async {
    try {
      await BaseDbService.database.rawUpdate('UPDATE Contacts SET name = ?, address = ? , key = ?, isGroup = ? WHERE id = ?', [name, address, key, isGroup ? 1 : 0, id]);
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<bool> deleteContact(int id) async {
    try {
      await BaseDbService.database.rawDelete('DELETE FROM Contacts WHERE id=$id');
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }
}
