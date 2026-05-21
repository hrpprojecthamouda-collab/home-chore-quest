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

// Multi-listener model: attach() returns a token, detach(token) removes
// only that subscriber. The choreographer drives a single trigger; every
// attached widget reacts. This lets us mount a second visible surface
// (e.g. an overlay strip above a modal sheet) without unbinding the home
// header — both react in parallel.

class PipController {
  final Map<Object, Future<void> Function()> _reactors = {};

  Object attach(Future<void> Function() react) {
    final token = Object();
    _reactors[token] = react;
    return token;
  }

  void detach(Object token) {
    _reactors.remove(token);
  }

  Future<void> reactHappy() async {
    if (_reactors.isEmpty) return;
    await Future.wait(_reactors.values.map((r) => r()));
  }
}

class CoinChipController extends ChangeNotifier {
  final Map<Object, _CoinHandlers> _handlers = {};
  // Set to true while a choreographer is driving so the chip's auto-listen
  // path snaps silently instead of animating.
  bool active = false;

  Object attach({
    required void Function() highlight,
    required Future<void> Function(int target) countTo,
    required void Function(int v) snap,
  }) {
    final token = Object();
    _handlers[token] = _CoinHandlers(highlight, countTo, snap);
    return token;
  }

  void detach(Object token) {
    _handlers.remove(token);
  }

  void highlight() {
    for (final h in _handlers.values) {
      h.highlight();
    }
  }
  Future<void> countTo(int v) async {
    if (_handlers.isEmpty) return;
    await Future.wait(_handlers.values.map((h) => h.countTo(v)));
  }
  void snap(int v) {
    for (final h in _handlers.values) {
      h.snap(v);
    }
  }
}

class _CoinHandlers {
  final void Function() highlight;
  final Future<void> Function(int target) countTo;
  final void Function(int v) snap;
  _CoinHandlers(this.highlight, this.countTo, this.snap);
}

class XpBarController extends ChangeNotifier {
  final Map<Object, _XpHandlers> _handlers = {};
  bool active = false;

  Object attach({
    required void Function() highlight,
    required Future<void> Function(double pct, {required Duration duration}) fillTo,
    required void Function(double pct, {required int newMax}) snap,
  }) {
    final token = Object();
    _handlers[token] = _XpHandlers(highlight, fillTo, snap);
    return token;
  }

  void detach(Object token) {
    _handlers.remove(token);
  }

  void highlight() {
    for (final h in _handlers.values) {
      h.highlight();
    }
  }
  Future<void> fillTo(double pct, {required Duration duration}) async {
    if (_handlers.isEmpty) return;
    await Future.wait(
      _handlers.values.map((h) => h.fillTo(pct, duration: duration)),
    );
  }
  void snapTo(double pct, {required int newMax}) {
    for (final h in _handlers.values) {
      h.snap(pct, newMax: newMax);
    }
  }
}

class _XpHandlers {
  final void Function() highlight;
  final Future<void> Function(double pct, {required Duration duration}) fillTo;
  final void Function(double pct, {required int newMax}) snap;
  _XpHandlers(this.highlight, this.fillTo, this.snap);
}
