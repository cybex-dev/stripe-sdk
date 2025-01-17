import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../customer_session.dart';
import '../screens/payment_methods_screen.dart';

/// A managed repository for payment methods.
/// This is the preferred way to work with payment methods when using Flutter.
/// The store will only refresh itself if there are active listeners.
class PaymentMethodStore extends ChangeNotifier {
  final List<PaymentMethod> paymentMethods = [];
  bool isLoading = false;

  /// The customer session the store operates on.
  final CustomerSession _customerSession;

  static PaymentMethodStore? _instance;

  /// Access the singleton instance of [PaymentMethodStore].
  static PaymentMethodStore get instance {
    _instance ??= PaymentMethodStore();
    return _instance!;
  }

  PaymentMethodStore({CustomerSession? customerSession}) : _customerSession = customerSession ?? CustomerSession.instance {
    _customerSession.addListener(() => dispose());
  }

  /// Refreshes data from the API when the first listener is added.
  @override
  void addListener(VoidCallback listener) {
    final isFirstListener = !hasListeners;
    super.addListener(listener);
    if (isFirstListener) refresh();
  }

  /// Attach a payment method and refresh the store if there are any active listeners.
  Future<Map<String, dynamic>> attachPaymentMethod(String paymentMethodId) async {
    final paymentMethodFuture = await _customerSession.attachPaymentMethod(paymentMethodId);
    await refresh();
    return paymentMethodFuture;
  }

  /// Detach a payment method and refresh the store if there are any active listeners.
  Future<Map> detachPaymentMethod(String paymentMethodId) async {
    final paymentMethodFuture = await _customerSession.detachPaymentMethod(paymentMethodId);
    await refresh();
    return paymentMethodFuture;
  }

  /// Refresh the store if there are any active listeners.
  Future<void> refresh({bool forceRefresh = false}) async {
    if (!hasListeners) {
      if(!forceRefresh) {
        return Future.value();
      }
    }

    final paymentMethodFuture = _customerSession.listPaymentMethods(limit: 100);
    isLoading = true;
    notifyListeners();
    return paymentMethodFuture.then((value) {
      final List listData = value['data'] ?? <PaymentMethod>[];
      paymentMethods.clear();
      if (listData.isNotEmpty) {
        paymentMethods.addAll(listData.map((item) {
          var card = item['card'];
          return PaymentMethod(
              item['id'], card['last4'], card['brand'], DateTime(card['exp_year'], card['exp_month']), card["country"], card["address_line1_check"], card["address_line1_check"], card["cvc_check"]);
        }).toList());
      }
    }).whenComplete(() {
      isLoading = false;
      notifyListeners();
    });
  }

  /// Clear the store, notify all active listeners and dispose the ChangeNotifier.
  @override
  void dispose() {
    paymentMethods.clear();
    notifyListeners();
    super.dispose();
  }
}
