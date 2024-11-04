import 'dart:developer';

sealed class Method {
  final String plaintext;

  const Method(this.plaintext);

  static const Method payInvoice = _StandardMethod('pay_invoice');
  static const Method multiPayInvoice = _StandardMethod('multi_pay_invoice');
  static const Method payKeysend = _StandardMethod('pay_keysend');
  static const Method multiPayKeysend = _StandardMethod('multi_pay_keysend');
  static const Method makeInvoice = _StandardMethod('make_invoice');
  static const Method lookupInvoice = _StandardMethod('lookup_invoice');
  static const Method listTransactions = _StandardMethod('list_transactions');
  static const Method getBalance = _StandardMethod('get_balance');
  static const Method getInfo = _StandardMethod('get_info');
  static const Method unknown = _StandardMethod('unknown');

  // Registry to store all methods by their plaintext
  static final Map<String, Method> _methodsRegistry = {
    payInvoice.plaintext: payInvoice,
    multiPayInvoice.plaintext: multiPayInvoice,
    payKeysend.plaintext: payKeysend,
    multiPayKeysend.plaintext: multiPayKeysend,
    makeInvoice.plaintext: makeInvoice,
    lookupInvoice.plaintext: lookupInvoice,
    listTransactions.plaintext: listTransactions,
    getBalance.plaintext: getBalance,
    getInfo.plaintext: getInfo,
    unknown.plaintext: unknown,
  };

  // Factory method to get Method by plaintext
  factory Method.fromPlaintext(String plaintext) {
    return _methodsRegistry[plaintext] ?? Method.unknown;
  }

  // Method to register custom methods
  static void registerCustomMethods(List<Method> methods) {
    for (var method in methods) {
      if (!_methodsRegistry.containsKey(method.plaintext)) {
        _methodsRegistry[method.plaintext] = method;
      } else {
        log("Warning: Method '${method.plaintext}' is already registered.");
      }
    }
  }
}

// Internal class for standard methods
class _StandardMethod extends Method {
  const _StandardMethod(super.plaintext);
}

// Class for custom methods
abstract class CustomMethod extends Method {
  const CustomMethod(super.plaintext);
}
