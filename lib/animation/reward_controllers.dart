// Imperative controllers for reward-animation widgets.
//
// The choreographer drives precise reward sequences (Pip reaction → coin glow
// → coin count-up → XP glow → XP fill → level-up → rest fill) by holding
// these controllers and awaiting their futures. Widgets attach themselves
// when they mount and detach on dispose, so callbacks always reach a live
// State.
//
// Using lightweight controller objects (instead of GlobalKey<State>) keeps
// widget internals private and survives State class renames.

import 'package:flutter/foundation.dart';

class PipController {
  Future<void> Function()? _react;

  void attach(Future<void> Function() react) {
    _react = react;
  }

  void detach() {
    _react = null;
  }

  Future<void> reactHappy() async {
    final r = _react;
    if (r == null) return;
    await r();
  }
}

class CoinChipController extends ChangeNotifier {
  void Function()? _highlight;
  Future<void> Function(int target)? _countTo;
  void Function(int v)? _snap;
  // Set to true while a choreographer is driving so the chip's auto-listen
  // path snaps silently instead of animating.
  bool active = false;

  void attach({
    required void Function() highlight,
    required Future<void> Function(int target) countTo,
    required void Function(int v) snap,
  }) {
    _highlight = highlight;
    _countTo = countTo;
    _snap = snap;
  }

  void detach() {
    _highlight = null;
    _countTo = null;
    _snap = null;
  }

  void highlight() => _highlight?.call();
  Future<void> countTo(int v) async {
    final fn = _countTo;
    if (fn == null) return;
    await fn(v);
  }
  void snap(int v) => _snap?.call(v);
}

class XpBarController extends ChangeNotifier {
  void Function()? _highlight;
  Future<void> Function(double pct, {required Duration duration})? _fillTo;
  void Function(double pct, {required int newMax})? _snap;
  bool active = false;

  void attach({
    required void Function() highlight,
    required Future<void> Function(double pct, {required Duration duration}) fillTo,
    required void Function(double pct, {required int newMax}) snap,
  }) {
    _highlight = highlight;
    _fillTo = fillTo;
    _snap = snap;
  }

  void detach() {
    _highlight = null;
    _fillTo = null;
    _snap = null;
  }

  void highlight() => _highlight?.call();
  Future<void> fillTo(double pct, {required Duration duration}) async {
    final fn = _fillTo;
    if (fn == null) return;
    await fn(pct, duration: duration);
  }
  void snapTo(double pct, {required int newMax}) =>
      _snap?.call(pct, newMax: newMax);
}
