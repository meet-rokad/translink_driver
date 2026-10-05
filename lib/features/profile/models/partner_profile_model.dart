class PartnerProfile {
  final String? id;
  final String partnerId;
  final String? ownerName;
  final String? mobileNumber;
  final String? email;
  final String? businessName;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final String? panNumber;
  final String? gstNumber;
  final String? profilePic;
  final String? gender;
  final double rating;
  final bool isVerified;

  PartnerProfile({
    this.id,
    required this.partnerId,
    this.ownerName,
    this.mobileNumber,
    this.email,
    this.gender,
    this.businessName,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.panNumber,
    this.gstNumber,
    this.profilePic,
    this.rating = 0.0,
    this.isVerified = false,
  });

  factory PartnerProfile.fromJson(Map<String, dynamic> json) {
    return PartnerProfile(
      id: json['id'],
      partnerId: json['partner_id'],
      ownerName: json['owner_name'],
      mobileNumber: json['mobile_number'],
      email: json['email'],
      gender: json['gender'],
      businessName: json['business_name'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      pincode: json['pincode'],
      panNumber: json['pan_number'],
      gstNumber: json['gst_number'],
      profilePic: json['profile_pic'],
      rating: json['rating'] != null ? double.tryParse(json['rating'].toString()) ?? 0.0 : 0.0,
      isVerified: json['is_verified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'partner_id': partnerId,
      'owner_name': ownerName,
      if (mobileNumber != null) 'mobile_number': mobileNumber,
      'email': email,
      'gender': gender,
      'business_name': businessName,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'pan_number': panNumber,
      'gst_number': gstNumber,
      'profile_pic': profilePic,
      'rating': rating,
      'is_verified': isVerified,
    };
  }
}
