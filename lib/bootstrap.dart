import 'bootstrap_native.dart'
    if (dart.library.html) 'bootstrap_web.dart' as platform;

Future<void> start() => platform.start();
