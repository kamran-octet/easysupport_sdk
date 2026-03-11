enum EasySupportCustomerAction {
  create,
  update,
}

extension EasySupportCustomerActionJson on EasySupportCustomerAction {
  String toJson() => name;

  static EasySupportCustomerAction fromJson(String value) {
    switch (value.trim().toLowerCase()) {
      case 'create':
        return EasySupportCustomerAction.create;
      case 'update':
        return EasySupportCustomerAction.update;
      default:
        throw ArgumentError.value(
          value,
          'value',
          'Unsupported EasySupportCustomerAction',
        );
    }
  }
}
