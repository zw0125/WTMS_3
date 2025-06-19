class Worker {
  final int id;
  final String email;
  String fullName;
  String? phone;
  String? address;
  String? profileImage;

  Worker({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.address,
    this.profileImage,
  });

  factory Worker.fromJson(Map<String, dynamic> json) {
    return Worker(
      id: int.parse(json['id'].toString()),
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      address: json['address'],
      profileImage: json['profile_image'], // Add this line
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'address': address,
      'profile_image': profileImage, // Add this line
    };
  }
}
