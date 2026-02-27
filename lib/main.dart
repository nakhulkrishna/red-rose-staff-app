import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:staff_app/core/app/app.dart';
import 'package:staff_app/core/bootstrap/bootstrap.dart';

Future<void> main() async {
  await bootstrap(() {
    runApp(const ProviderScope(child: StaffApp()));
  });
}
