part of flutter_pay;

class FlutterPay {
  final MethodChannel _channel = MethodChannel('flutter_pay');

  /// Switch Google Pay [environment]
  ///
  /// See [PaymentEnvironment]
  void setEnvironment(
      {PaymentEnvironment environment = PaymentEnvironment.Test}) {
    var params = <String, bool>{
      "isTestEnvironment": environment == PaymentEnvironment.Test,
    };
    _channel.invokeMethod('switchEnvironment', params);
  }

  /// Returns `true` if Apple/ Google Pay is available on device
  Future<bool> canMakePayments() async {
    final canMakePayments = await _channel.invokeMethod('canMakePayments');
    return canMakePayments;
  }

  /// Show payment Apple Pay setup
  Future<void> showPaymentSetup() async {
    await _channel.invokeMethod('showPaymentSetUp');
  }

  /// Returns true if Apple/Google Pay is available on device and there is at least one activated card
  ///
  /// You can set allowed payment networks in [allowedPaymentNetworks] parameter.
  /// See [PaymentNetwork]
  Future<bool> canMakePaymentsWithActiveCard(
      {required List<PaymentNetwork> allowedPaymentNetworks}) async {
    var paymentNetworks =
        allowedPaymentNetworks.map((network) => network.getName).toList();
    var params = <String, dynamic>{"paymentNetworks": paymentNetworks};

    final canMakePayments =
        await _channel.invokeMethod('canMakePaymentsWithActiveCard', params);
    return canMakePayments;
  }

  /// Process the payment and returns the token from Apple/Google pay
  ///
  /// Can throw [FlutterPayError]
  ///
  /// * [googleParameters] - options for Google Pay
  /// * [appleParameters] - options for Apple Pay
  /// * [allowedPaymentNetworks] - List of allowed payment networks.
  /// See [PaymentNetwork].
  /// * [allowedCardAuthMethods] - List of allowed authenticaion methods
  /// methods for Google Pay.
  /// * [paymentItems] - affects only Apple Pay. See [PaymentItem]
  /// * [merchantName] - affects only Google Pay.
  /// Mercant name which will be displayed to customer.
  Future<PaymentResult> requestPayment({
    GoogleParameters? googleParameters,
    AppleParameters? appleParameters,
    List<PaymentNetwork> allowedPaymentNetworks = const [],
    required List<PaymentItem> paymentItems,
    bool emailRequired = false,
    required String currencyCode,
    required String countryCode,
  }) async {
    var items = paymentItems.map((item) => item.toJson()).toList();
    var params = <String, dynamic>{
      "currencyCode": currencyCode,
      "countryCode": countryCode,
      "allowedPaymentNetworks":
          allowedPaymentNetworks.map((network) => network.getName).toList(),
      "items": items,
      "emailRequired": emailRequired,
    };

    // callback from swift whether payment accept or reject.
    if( Platform.isIOS ) {
      _channel.setMethodCallHandler( (methodCall) async {
        if( methodCall.method == "validatePaymentResult" ) {
          var rawPaymentResult = methodCall.arguments;
          if( appleParameters?.applePayResultValidation==null ) {
            // accept if validation is all okay.
            return true;
          }
          // convert native arguments Map<Object?, Object?> to an object PaymentResult.
          var paymentResult = PaymentResult.fromNative( rawPaymentResult );
          // validate a result of payment on the flutter.
          return await appleParameters?.applePayResultValidation?.call( paymentResult );
        }
      } );
    }

    if (Platform.isAndroid && googleParameters != null) {
      params.addAll(googleParameters.toMap());
    } else if (Platform.isIOS && appleParameters != null) {
      params.addAll(appleParameters.toMap());
    } else {
      throw FlutterPayError(description: "");
    }

    try {
      var response = await _channel.invokeMethod('requestPayment', params);
      var payResponse = Map<String, dynamic>.from(response);
      if (payResponse == null) {
        throw FlutterPayError(description: "Pay response cannot be parsed");
      }

      var paymentToken = payResponse["token"];
      if (paymentToken != null) {
        print("Payment token: $paymentToken");

        var paymentResult = PaymentResult(paymentToken: paymentToken);
        if( Platform.isIOS ) {
          paymentResult.applePayResult = ApplePayResult.fromNative(payResponse);
        }
        return paymentResult;
      } else {
        print("Payment token: null");
        return PaymentResult(paymentToken: "");
      }
    } on PlatformException catch (error) {
      if (error.code == "userCancelledError") {
        print(error.message);
        return PaymentResult(paymentToken: "");
      }
      if (error.code == "paymentError") {
        print(error.message);
        return PaymentResult(paymentToken: "");
      }
      throw FlutterPayError(code: error.code, description: error.message);
    }
  }

}
