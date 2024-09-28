enum Method {
  payInvoice('pay_invoice'),
  multiPayInvoice('multi_pay_invoice'),
  payKeysend('pay_keysend'),
  multiPayKeysend('multi_pay_keysend'),
  makeInvoice('make_invoice'),
  lookupInvoice('lookup_invoice'),
  listTransactions('list_transactions'),
  getBalance('get_balance'),
  getInfo('get_info'),
  unknown('unknown');

  final String plaintext;

  const Method(this.plaintext);

  factory Method.fromPlaintext(String plaintext) {
    return Method.values.firstWhere(
      (method) => method.plaintext == plaintext,
      orElse: () => Method.unknown,
    );
  }
}
