class EasySupportCustomerResult {
  const EasySupportCustomerResult({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.isBlocked,
    this.workspaceId,
    this.channelId,
    this.createdAt,
    this.updatedAt,
  });

  factory EasySupportCustomerResult.fromJson(Map<String, dynamic> json) {
    return EasySupportCustomerResult(
      id: json['id'] as String?,
      name: json['name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      isBlocked: json['is_blocked'] as bool?,
      workspaceId: json['workspace_id'] as String?,
      channelId: json['channel_id'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  final String? id;
  final String? name;
  final String? email;
  final String? phone;
  final bool? isBlocked;
  final String? workspaceId;
  final String? channelId;
  final String? createdAt;
  final String? updatedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (isBlocked != null) 'is_blocked': isBlocked,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (channelId != null) 'channel_id': channelId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }
}
