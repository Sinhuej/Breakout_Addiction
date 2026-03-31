class SupportContact {
  final String name;
  final String phone;

  const SupportContact({
    required this.name,
    required this.phone,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
    };
  }

  factory SupportContact.fromMap(Map<String, dynamic> map) {
    return SupportContact(
      name: (map['name'] as String?) ?? '',
      phone: (map['phone'] as String?) ?? '',
    );
  }

  bool get isValid => name.trim().isNotEmpty && phone.trim().isNotEmpty;
}
