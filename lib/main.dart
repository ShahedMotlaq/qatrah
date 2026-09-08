import 'package:qatrah/app/app.dart';
import 'package:qatrah/bootstrap.dart';

Future<void> main() async {
  await bootstrap(
    () => const App(),
  );
}
