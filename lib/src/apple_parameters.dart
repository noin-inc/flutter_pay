part of flutter_pay;

typedef ApplePayResultValidation = Future<bool> Function( PaymentResult paymentResult );

class AppleParameters {
  final String merchantIdentifier;
  final bool requiredShippingContactFields;
  final ApplePayResultValidation? applePayResultValidation;

  AppleParameters({
    required this.merchantIdentifier,
    required this.requiredShippingContactFields,
    this.applePayResultValidation
  });

  Map<String, dynamic> toMap() {
    return {
      'merchantIdentifier': merchantIdentifier,
      'requiredShippingContactFields': requiredShippingContactFields
    };
  }
}
