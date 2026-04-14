/// Store data model — maps to backend `StoreResponse`.
class StoreModel {
  final int? id;
  final int? ownerId;
  final String? ownerName;
  final String? ownerPhone;
  final String? storeName;
  final String? address;
  final String? phoneNumber;
  final String? description;
  final String? imageUrl;
  final bool? isOpen;
  final String? createdAt;
  final String? updatedAt;

  const StoreModel({
    this.id,
    this.ownerId,
    this.ownerName,
    this.ownerPhone,
    this.storeName,
    this.address,
    this.phoneNumber,
    this.description,
    this.imageUrl,
    this.isOpen,
    this.createdAt,
    this.updatedAt,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) => StoreModel(
        id: (json['id'] as num?)?.toInt(),
        ownerId: (json['ownerId'] as num?)?.toInt(),
        ownerName: json['ownerName'] as String?,
        ownerPhone: json['ownerPhone'] as String?,
        storeName: json['storeName'] ?? json['name'] as String?,
        address: json['address'] as String?,
        phoneNumber: json['phoneNumber'] as String?,
        description: json['description'] as String?,
        imageUrl: json['imageUrl'] as String?,
        isOpen: json['isOpen'] as bool?,
        createdAt: json['createdAt'] as String?,
        updatedAt: json['updatedAt'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'ownerId': ownerId,
        'ownerName': ownerName,
        'ownerPhone': ownerPhone,
        'storeName': storeName,
        'address': address,
        'phoneNumber': phoneNumber,
        'description': description,
        'imageUrl': imageUrl,
        'isOpen': isOpen,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  StoreModel copyWith({
    int? id,
    int? ownerId,
    String? ownerName,
    String? ownerPhone,
    String? storeName,
    String? address,
    String? phoneNumber,
    String? description,
    String? imageUrl,
    bool? isOpen,
    String? createdAt,
    String? updatedAt,
  }) =>
      StoreModel(
        id: id ?? this.id,
        ownerId: ownerId ?? this.ownerId,
        ownerName: ownerName ?? this.ownerName,
        ownerPhone: ownerPhone ?? this.ownerPhone,
        storeName: storeName ?? this.storeName,
        address: address ?? this.address,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        description: description ?? this.description,
        imageUrl: imageUrl ?? this.imageUrl,
        isOpen: isOpen ?? this.isOpen,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

/// Request body for PUT /stores/{id}.
class UpdateStoreProfileRequest {
  final String? storeName;
  final String? address;
  final String? phoneNumber;
  final String? description;
  final String? imageUrl;

  const UpdateStoreProfileRequest({
    this.storeName,
    this.address,
    this.phoneNumber,
    this.description,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() => {
        if (storeName != null) 'storeName': storeName,
        if (address != null) 'address': address,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (description != null) 'description': description,
        if (imageUrl != null) 'imageUrl': imageUrl,
      };
}
