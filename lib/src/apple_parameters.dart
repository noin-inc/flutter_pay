part of flutter_pay;

class AppleParameters {
  final String merchantIdentifier;
  final bool requiredShippingContactFields;

  AppleParameters({
    required this.merchantIdentifier,
    required this.requiredShippingContactFields
  });

  Map<String, dynamic> toMap() {
    return {
      'merchantIdentifier': merchantIdentifier,
      'requiredShippingContactFields': requiredShippingContactFields
    };
  }
}
