class Contact {
  int _id;
  String _name;
  String _address;
  String _key;
  int _isGroup;

  Contact({int id, String name, String address, String key, int isGroup}) {
    this._id = id;
    this._name = name;
    this._address = address;
    this._key = key;
    this._isGroup = isGroup;
  }

  Contact.fromMap(Map map) {
    this._id = map['id'];
    this._name = map['name'];
    this._address = map['address'];
    this._key = map['key'];
    this._isGroup = map['isGroup'];
  }

  int get id => _id;
  String get name => _name;
  String get address => _address;
  String get key => _key;
  bool get isGroup => _isGroup != 0;
}
