# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Flutter salesman app ("RED ROSE SALESMAN APP", package `staff_app`) backed by Firebase project `products-managment-a23a7`. Deliberately minimal scope: salesmen browse a product catalog (cards with auto-scrolling image carousels), open a detail page with per-unit price combinations, build a cart, pick a customer at checkout, and place orders whose bill is sent via WhatsApp to a dashboard-configured number. Management happens in the companion Flutter-web admin panel at `/Users/nakhulkrishna/Products-Management` (own CLAUDE.md); both share one Firestore database.

Working branch: `revamp`. `feature/firebase-auth` is merged; `main` is stale.

## Commands

```bash
flutter pub get
flutter run
flutter analyze                       # keep at zero issues
flutter test test/product_calculations_test.dart   # calculation invariants — must stay green
flutter test                          # note: widget_test.dart is a stale template test that fails; not a regression
```

Firestore rules: `firestore.rules` here is the synced copy of the LIVE rules plus the `catalog_app_config` block — safe to deploy (`firebase deploy --only firestore:rules`), unlike older revisions which were missing the legacy collections. Cloud Functions in `functions/` are legacy; `testDeleteOrders` is an unauthenticated HTTP deleter and `deleteMonthlyOrders` targets the wrong collection — both flagged for removal, don't imitate them.

## Architecture

Entry: `main.dart` → `core/bootstrap/bootstrap.dart` (error handlers, image-cache caps, Firebase init) → `ProviderScope` → `AuthGatePage`.

- **State:** Riverpod 2, hand-written providers in `features/<feature>/presentation/providers/` and `shared/providers/`. Firebase is injected via `firebaseAuthProvider`/`firestoreProvider`.
- **Navigation:** no router. `AuthGatePage` → `LoginPage` | `MainShellPage` (two tabs: Products, Settings). Everything else is `Navigator.push`. Customers screen exists only as a selection picker opened from checkout.
- **Auth** (`features/auth/`): Firebase email/password. Sign-up needs only email + password; it writes `catalog_users/{uid}` with `role: 'Salesman'`, `approvalStatus: 'approved'`, `isActive: true` (name derived from the email prefix) plus a UID-keyed active `catalog_staff_salesmen` profile so the admin Staffs tab lists it. No approval flow — new accounts work immediately. Password reset from login page and settings.
- **Ordering flow:** `products_list_page.dart` (cards) → `product_detail_page.dart` (unit selection, quantity, add to cart) → `order_summary_page.dart` (inline customer picker; checkout button doubles as "Select Customer") → writes `catalog_orders/{ORD-yyyyMMdd-###}` (ID via transaction on `_catalog_order_counters`) → `order_success_page.dart` auto-opens WhatsApp with the formatted bill and can resend. Cart and selected customer are cleared after submit and on logout.
- **Stock/prices are live:** `productsProvider` is a StreamProvider over `catalog_products` snapshots; the admin Cloud Function `deductInventoryOnOrderCreate` decrements stock after each order and the stream picks it up.

## Calculation rules (guarded by test/product_calculations_test.dart)

- Firestore product docs (esp. bulk uploads) store numbers as **strings** — parse with the tolerant `_toDouble` in `product_model.dart`, never bare `as num?` casts.
- Price resolution matches the admin panel: per-unit market price from `pricing.markets.{market}.prices.{unit}`, priority `manualOffer ?? autoOffer ?? manual ?? auto`; an offer, when set, IS the charged price. Shared helpers in `features/products/domain/entities/product_pricing.dart` keep display and cart consistent — route any new price display through them.
- Units: `saleUnits[].conversionToBaseUnit` converts to base stock units; decimals allowed only for the base unit (pack units like CTN are integers). Stock validation sums base quantities across cart lines of the same product.

## Firebase specifics

- Market pricing: salesman's `salesMarketAccess` on their `catalog_staff_salesmen` doc → `hyper_market`/`local_market` price set (`salesman_market_provider.dart`). Hyper/local is intentionally NOT shown in the UI.
- WhatsApp order number: read `catalog_app_config/order_whatsapp` first, then legacy `order_whatsapp/main_number` (`shared/providers/whatsapp_order_number_provider.dart`); refetched every order. Number normalization: explicit `+`/`00` wins; bare 8-digit → Qatar 974, bare 10-digit → India 91.
- Salesman lookups fall back uid-doc → `uid` field → email, because admin-created salesman docs use `SM-###` ids while app-created ones are UID-keyed.
- Rules quirk that bites: queries over `catalog_users` fail permission-denied for salesmen whose profile the rules can't resolve — prefer single-doc reads of world-readable or self-owned docs.

## Gotchas

- `asstes/` (misspelled) is a real folder referenced by pubspec — don't rename without updating pubspec.
- Root `package.json`/`node_modules` are stray; functions deps live in `functions/package.json`.
- Bans were removed (no client enforcement); the legacy ban Cloud Functions may still be deployed but nothing calls them.
