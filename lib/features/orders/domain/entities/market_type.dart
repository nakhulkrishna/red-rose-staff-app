enum MarketType { hyper, local }

extension MarketTypeX on MarketType {
  String get label {
    switch (this) {
      case MarketType.hyper:
        return 'Hyper Market';
      case MarketType.local:
        return 'Local Market';
    }
  }
}
