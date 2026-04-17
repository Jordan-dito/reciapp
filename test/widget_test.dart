import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:recicladora_app/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await dotenv.load(fileName: '.env');
    await initializeDateFormatting('es', null);
  });

  testWidgets('La app monta el árbol inicial sin excepción', (WidgetTester tester) async {
    await tester.pumpWidget(const RecicladoraApp());
    await tester.pump();
    // `RecicladoraApp` programa un timeout de 3s en initState; sin avanzar el reloj el test falla por timers pendientes
    await tester.pump(const Duration(seconds: 4));

    expect(tester.takeException(), isNull);
  });
}
