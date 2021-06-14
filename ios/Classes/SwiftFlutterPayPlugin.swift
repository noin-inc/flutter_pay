import Flutter
import UIKit
import PassKit

@available(iOS 10.0, *)
public class SwiftFlutterPayPlugin: NSObject, FlutterPlugin {

    let paymentAuthorizationController = PKPaymentAuthorizationController()

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_pay", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterPayPlugin()
        instance.flutterChannel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    var flutterResult: FlutterResult?
    var flutterChannel: FlutterMethodChannel?

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if (call.method == "canMakePayments") {
            canMakePayment(result: result)
        } else if (call.method == "canMakePaymentsWithActiveCard") {
            canMakePaymentsWithActiveCard(arguments: call.arguments, result: result)
        } else if (call.method == "requestPayment") {
            requestPayment(arguments: call.arguments, result: result)
        } else if (call.method == "switchEnvironment") {
        } else if (call.method == "showPaymentSetUp") {
            showPaymentSetUp();
        }
    }

    func showPaymentSetUp() {
        PKPassLibrary().openPaymentSetup()
    }

    func canMakePayment(arguments: Any? = nil, result: @escaping FlutterResult) {
        let canMakePayment = PKPaymentAuthorizationController.canMakePayments()
        result(canMakePayment)
    }

    func canMakePaymentsWithActiveCard(arguments: Any? = nil, result: @escaping FlutterResult) {
        guard let params = arguments as? [String: Any],
              let paymentNetworks = params["paymentNetworks"] as? [String] else {
            result(FlutterError(code: "invalidParameters", message: "Invalid parameters", details: nil))
            return;
        }
        let pkPaymentNetworks: [PKPaymentNetwork] = paymentNetworks.compactMap({ PaymentNetworkHelper.decodePaymentNetwork($0) })
        let canMakePayments = PKPaymentAuthorizationController.canMakePayments(usingNetworks: pkPaymentNetworks)
        result(canMakePayments)
    }

    func requestPayment(arguments: Any? = nil, result: @escaping FlutterResult) {
        guard let params = arguments as? [String: Any],
              let merchantID = params["merchantIdentifier"] as? String,
              let currency = params["currencyCode"] as? String,
              let countryCode = params["countryCode"] as? String,
              let allowedPaymentNetworks = params["allowedPaymentNetworks"] as? [String],
              let items = params["items"] as? [[String: String]],
              let requiredShippingContactFields = params["requiredShippingContactFields"] as? Bool else {
            result(FlutterError(code: "invalidParameters", message: "Invalid parameters", details: nil))
            return
        }

        var paymentItems = [PKPaymentSummaryItem]()
        items.forEach { item in
            let itemTitle = item["name"]
            let itemPrice = item["price"]
            let itemDecimalPrice = NSDecimalNumber(string: itemPrice)
            let item = PKPaymentSummaryItem(label: itemTitle ?? "", amount: itemDecimalPrice)
            paymentItems.append(item)
        }

        let paymentNetworks = allowedPaymentNetworks.count > 0 ? allowedPaymentNetworks.compactMap {
            PaymentNetworkHelper.decodePaymentNetwork($0)
        } : PKPaymentRequest.availableNetworks()

        let paymentRequest = PKPaymentRequest()
        paymentRequest.paymentSummaryItems = paymentItems

        paymentRequest.merchantIdentifier = merchantID
        paymentRequest.merchantCapabilities = .capability3DS
        paymentRequest.countryCode = countryCode
        paymentRequest.currencyCode = currency
        paymentRequest.supportedNetworks = paymentNetworks
        if (requiredShippingContactFields) {
            paymentRequest.requiredShippingContactFields = [
                PKContactField.emailAddress,
                PKContactField.name,
                PKContactField.phoneNumber,
                PKContactField.phoneticName,
                PKContactField.postalAddress
            ]
        }


        let paymentController = PKPaymentAuthorizationController(paymentRequest: paymentRequest)
        paymentController.delegate = self
        self.flutterResult = result
        paymentController.present(completion: nil)
    }

    private func paymentResult(pkPayment: PKPayment?, handler completion: ( (PKPaymentAuthorizationResult) -> Void )? = nil ) {
        if let result = flutterResult {
            if let payment = pkPayment {
                let token:String? = String(data: payment.token.paymentData, encoding: .utf8)
                let paymentResult:[String:Any] = [
                    "token": token,
                    "applePayParameters": [
                        "emailAddress": payment.shippingContact?.emailAddress,
                        "phoneNumber": payment.shippingContact?.phoneNumber?.stringValue,
                        "familyName": payment.shippingContact?.name?.familyName,
                        "givenName": payment.shippingContact?.name?.givenName,
                        "street": payment.shippingContact?.postalAddress?.street,
                        "city": payment.shippingContact?.postalAddress?.city,
                        "state": payment.shippingContact?.postalAddress?.state,
                        "postalCode": payment.shippingContact?.postalAddress?.postalCode,
                        "country": payment.shippingContact?.postalAddress?.country,
                        "subAdministrativeArea": payment.shippingContact?.postalAddress?.subAdministrativeArea,
                        "subLocality": payment.shippingContact?.postalAddress?.subLocality,
                    ]
                ]

                // validate a result of payment
                self.flutterChannel?.invokeMethod("validatePaymentResult", arguments: paymentResult, result: { _purchaseResult in
                    if let purchaseResult = _purchaseResult as? Bool {
                        if( purchaseResult ) {
                           result(paymentResult)
                           if let completionHandler = completion {
                               completionHandler(PKPaymentAuthorizationResult(status: .success, errors: nil))
                           }
                        } else {
                           result(FlutterError(code: "purchaseError", message: "purchase result is false", details: nil))
                        }
                    } else if let flutterError = _purchaseResult as? FlutterError {
                        result(FlutterError(code: "purchaseError", message: flutterError.message, details: nil))
                    }

                    if let completionHandler = completion {
                        completionHandler(PKPaymentAuthorizationResult(status: .failure, errors: nil))
                    }
                } )
                return;
            } else {
                result(FlutterError(code: "userCancelledError", message: "User cancelled the payment", details: nil))
            }
            flutterResult = nil
        }

        if let completionHandler = completion {
            completionHandler(PKPaymentAuthorizationResult(status: .failure, errors: nil))
        }
    }
}

extension SwiftFlutterPayPlugin: PKPaymentAuthorizationControllerDelegate {
    public func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        paymentResult(pkPayment: nil)
        controller.dismiss(completion: nil)
    }

    public func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController,
        didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        paymentResult(pkPayment: payment, handler: completion)
    }
}
