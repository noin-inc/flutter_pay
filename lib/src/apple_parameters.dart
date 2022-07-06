part of flutter_pay;

typedef ApplePayResultValidation = Future<bool> Function(PaymentResult paymentResult);

class AppleParameters {
  final String merchantIdentifier;
  final bool requiredShippingContactFields;
  final ApplePayResultValidation? applePayResultValidation;
  final List<MerchantCapability>? merchantCapabilities;

  AppleParameters({
    required this.merchantIdentifier,
    required this.requiredShippingContactFields,
    this.applePayResultValidation,
    this.merchantCapabilities,
  });

  Map<String, dynamic> toMap() {
    return {
      'merchantIdentifier': merchantIdentifier,
      'requiredShippingContactFields': requiredShippingContactFields,
      'merchantCapabilities': merchantCapabilities?.map<String>((e) => e.getName).toList() ?? [],
    };
  }
}
