import 'package:flutter_riverpod/flutter_riverpod.dart';

final alphaProvider = StateProvider<List<double>>((ref) {
  final List<double> a = [];
  return a;
});

final betaProvider = StateProvider<List<double>>((ref) {
  final List<double> b = [];
  return b;
});