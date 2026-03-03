enum MarketType { hyper, local }

extension MarketTypeX on MarketType {
  String get firestoreKey {
    switch (this) {
      case MarketType.hyper:
        return 'hyper_market';
      case MarketType.local:
        return 'local_market';
    }
  }

  String get label {
    switch (this) {
      case MarketType.hyper:
        return 'Hyper Market';
      case MarketType.local:
        return 'Local Market';
    }
  }
}
