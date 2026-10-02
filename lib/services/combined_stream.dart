import 'dart:async';

/// Emits only after both sources have supplied data. Cancels both listeners
/// when the widget leaves the screen; no additional stream package is needed.
Stream<R> combineStreams<A, B, R>(
  Stream<A> first,
  Stream<B> second,
  R Function(A, B) combine,
) {
  late StreamController<R> controller;
  StreamSubscription<A>? firstSubscription;
  StreamSubscription<B>? secondSubscription;
  A? firstValue;
  B? secondValue;
  bool hasFirst = false;
  bool hasSecond = false;
  void emit() {
    if (hasFirst && hasSecond && !controller.isClosed) {
      controller.add(combine(firstValue as A, secondValue as B));
    }
  }

  controller = StreamController<R>(
    onListen: () {
      firstSubscription = first.listen((value) {
        firstValue = value;
        hasFirst = true;
        emit();
      }, onError: controller.addError);
      secondSubscription = second.listen((value) {
        secondValue = value;
        hasSecond = true;
        emit();
      }, onError: controller.addError);
    },
    onCancel: () async {
      await firstSubscription?.cancel();
      await secondSubscription?.cancel();
    },
  );
  return controller.stream;
}
