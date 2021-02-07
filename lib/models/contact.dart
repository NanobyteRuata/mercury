class Contact {
  String _name;
  String _address;
  String _key;

  Contact({String name, String address, String key}) {
    this._name = name;
    this._address = address;
    this._key = key;
  }

  String get name => _name;
  String get address => _address;
  String get key => _key;
}
