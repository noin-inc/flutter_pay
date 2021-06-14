part of flutter_pay;

class PaymentResult {

  final String paymentToken;

  ApplePayResult? applePayResult;

  PaymentResult({ required this.paymentToken });

  static PaymentResult fromNative( Map<Object?, Object?> result ) {
    var paymentResult = PaymentResult( paymentToken: result['token'] as String );
    paymentResult.applePayResult = ApplePayResult.fromNative( result );
    return paymentResult;
  }

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

  static ApplePayResult fromNative( Map<Object?, Object?> result ) {
    var applePayParameter = result["applePayParameters"] as Map<Object?, Object?>;
    if( applePayParameter==null ) {
      return ApplePayResult();
    }

    return ApplePayResult(
      emailAddress: applePayParameter["emailAddress"] as String?,
      phoneNumber: applePayParameter["phoneNumber"] as String?,
      familyName: applePayParameter["familyName"] as String?,
      givenName: applePayParameter["givenName"] as String?,
      postalCode: applePayParameter["postalCode"] as String?,
      state: applePayParameter["state"] as String?,
      city: applePayParameter["city"] as String?,
      street: applePayParameter["street"] as String?,
      country : applePayParameter["country"] as String?,
      subAdministrativeArea : applePayParameter["subAdministrativeArea"] as String?,
      subLocality : applePayParameter["subLocality"] as String?,
    );
  }

}