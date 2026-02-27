class ProductUnit {
  final String code;
  final double multiplierToBase;
  final bool allowDecimal;

  const ProductUnit({
    required this.code,
    required this.multiplierToBase,
    required this.allowDecimal,
  });
}
