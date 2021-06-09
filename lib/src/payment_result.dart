part of flutter_pay;

class PaymentResult {

  final String paymentToken;

  ApplePayResult? applePayResult;

  PaymentResult({ required this.paymentToken });

}

class ApplePayResult {
  
  String? emailAddress;
  String? phoneNumber;
  String? familyName;
  String? givenName;
  String? postalCode;
  String? state;
  String? city;
  String? street;
  String? subAdministrativeArea;
  String? subLocality;
  String? country;

  ApplePayResult({ this.emailAddress,
    this.phoneNumber,
    this.familyName,
    this.givenName,
    this.postalCode,
    this.state,
    this.city,
    this.street,
    this.subAdministrativeArea,
    this.subLocality,
    this.country });
  
}