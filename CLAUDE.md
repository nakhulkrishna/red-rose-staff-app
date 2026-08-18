# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Flutter salesman/staff app ("RED ROSE SALESMAN APP", package `staff_app`) backed by Firebase (project `products-managment-a23a7`). Staff sign in, browse a product catalog, build carts, and submit orders for customers.

## Commands

```bash
flutter pub get                 # install deps
flutter run                     # run the app (device/simulator)
flutter analyze                 # lint (stock flutter_lints, no custom rules)
flutter test                    # run tests
flutter test test/widget_test.dart   # run a single test file
flutter build apk               # Android release build
```

Cloud Functions (in `functions/`, JavaScript, Node 20):

```bash
cd functions && npm install
npm run lint                    # eslint (also runs as a predeploy hook)
firebase deploy --only functions
firebase deploy --only firestore:rules
firebase emulators:start        # functions :5001, firestore :8080
```

Note: `test/widget_test.dart` is the stale default template test (expects "Hello, Salesman", pumps the app without Firebase init) — expect it to fail; don't treat that as a regression.

## Architecture

Entry flow: `lib/main.dart` → `core/bootstrap/bootstrap.dart` (`runZonedGuarded`, global error handlers → `AppLogger`, image cache caps, `Firebase.initializeApp`) → `runApp(ProviderScope(child: StaffApp))` (`core/app/app.dart`).

- **State management:** Riverpod 2 with hand-written providers (no codegen). Providers live in `lib/features/<feature>/presentation/providers/` and `lib/shared/providers/firebase_providers.dart` (`firebaseAuthProvider`, `firestoreProvider` — inject Firebase through these, not directly). The `provider` package in pubspec is vestigial; use Riverpod.
- **Routing:** No router package. `AuthGatePage` switches on `authStateProvider` → `LoginPage` or `MainShellPage` (bottom-nav shell driven by `bottomNavIndexProvider`). Deeper navigation is imperative `Navigator.push(MaterialPageRoute(...))`.
- **Feature layout:** `lib/features/{auth,customers,dashboard,home,navigation,notifications,orders,products,settings}`. Only `auth` and `products` have full data/domain/presentation layers (datasource → repository → usecase, each exposed as a Provider); other features are presentation-only.
- **Market/pricing context:** Salesmen have a market type (`MarketType.hyper`/`local` → Firestore keys `hyper_market`/`local_market`) via `salesman_market_provider.dart`; it drives which price set is shown (`shared/widgets/price_mode_banner.dart`).

## Firebase

- **Collections:** `catalog_products`, `catalog_orders`, `catalog_customers`, `catalog_staff_salesmen`, `catalog_users`, `_catalog_order_counters`, `_catalog_staff_counters`. Only `catalog_customers` is centralized in `core/config/firestore_collections.dart`; the rest are hardcoded inline throughout the codebase.
- **Auth:** firebase_auth email/password. After sign-in, `AuthRemoteDataSource` (`lib/features/auth/data/datasources/auth_remote_data_source.dart`) resolves the profile from `catalog_staff_salesmen` (matched by uid, docId, or lowercased email). Sign-up generates a staff code (`SM-001`-style) via an atomic transaction on `_catalog_staff_counters/sm_counter` and writes the profile to **two docs** (`doc(staffCode)` and `doc(uid)`). A custom `user-banned` error code is mapped and surfaced in `AuthGatePage`.
- **Security rules** (`firestore.rules`): role/permission model resolved from `catalog_users/{uid}` with fallback to `catalog_staff_salesmen/{uid}`; access gated by `hasPermission(key)` (admin, explicit `permissions` map, or role defaults — staff defaults to orders/customers/settings). Self-updates cannot change role/permissions/approvalStatus. Known gap: `_catalog_staff_counters` has no rule, so the sign-up staff-code transaction is likely denied in production.
- **Cloud Functions** (`functions/index.js`): scheduled monthly order purge (`deleteMonthlyOrders`, note it targets an `orders` collection, not `catalog_orders`), an unauthenticated `testDeleteOrders` HTTP function, and admin-only `banCatalogUser`/`unbanCatalogUser` callables.

## Gotchas

- The asset folder is misspelled **`asstes/`** and pubspec references that spelling — don't "fix" the name without updating pubspec (the images appear unused by Dart code).
- The root `package.json` / `node_modules/` are stray (real functions deps live in `functions/package.json`).
