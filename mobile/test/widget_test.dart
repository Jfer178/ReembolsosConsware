import 'dart:convert';

import 'package:consware_reembolsos/main.dart';
import 'package:consware_reembolsos/models/reimbursement.dart';
import 'package:consware_reembolsos/models/session.dart';
import 'package:consware_reembolsos/services/auth_service.dart';
import 'package:consware_reembolsos/services/reimbursement_api_service.dart';
import 'package:consware_reembolsos/utils/formatters.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _rejectedJson = {
  'id': 8,
  'employeeName': 'Empleado Demo',
  'amount': 750000.00,
  'category': 'Transporte',
  'description': 'Taxi a reunión',
  'status': 'Rejected',
  'rejectionReason': 'No cumple la política de gastos.',
  'createdAtUtc': '2026-10-29T14:58:06.2555068Z',
  'decidedAtUtc': '2026-10-29T14:58:06.9850216Z',
  'decidedBy': 'Andrés Ramírez',
};

Map<String, dynamic> _loginJson({String role = 'Employee', Duration validFor = const Duration(hours: 8)}) => {
      'token': 'token-de-prueba',
      'expiresAtUtc': DateTime.now().toUtc().add(validFor).toIso8601String(),
      'user': {
        'username': 'empleado.demo',
        'fullName': 'Empleado Demo',
        'department': 'Comercial',
        'role': role,
      },
    };

http.Response _json(Object body, int status) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

class _MemoryStorage implements SessionStorage {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String newValue) async => value = newValue;

  @override
  Future<void> clear() async => value = null;
}

void main() {
  group('formatters', () {
    test('formatCop agrupa miles y muestra centavos solo si existen', () {
      expect(formatCop(85000), '\$ 85.000 COP');
      expect(formatCop(500000.01), '\$ 500.000,01 COP');
      expect(formatCop(1250000), '\$ 1.250.000 COP');
    });

    test('parseCopInput convierte el texto del campo', () {
      expect(parseCopInput('1.250.000'), 1250000);
      expect(parseCopInput(''), isNull);
    });
  });

  group('modelos', () {
    test('Reimbursement mapea la respuesta de la API, incluido quién decidió', () {
      final item = Reimbursement.fromJson(_rejectedJson);
      expect(item.status, ReimbursementStatus.rejected);
      expect(item.code, 'RB-2026-0008');
      expect(item.decidedBy, 'Andrés Ramírez');
      expect(item.exceedsAutoApprovalLimit, isTrue);
    });

    test('un estado desconocido es un error de formato', () {
      expect(() => Reimbursement.fromJson({..._rejectedJson, 'status': 'Foo'}), throwsFormatException);
    });

    test('Session expone nombre, iniciales y vigencia', () {
      final session = Session.fromLoginJson(_loginJson());
      expect(session.firstName, 'Empleado');
      expect(session.initials, 'ED');
      expect(session.isExpired, isFalse);
      expect(Session.fromLoginJson(_loginJson(validFor: const Duration(minutes: -1))).isExpired, isTrue);
    });
  });

  group('ReimbursementApiService', () {
    test('envía el token en Authorization', () async {
      String? auth;
      final service = ReimbursementApiService(
        token: () => 'abc',
        client: MockClient((request) async {
          auth = request.headers['Authorization'];
          return _json([], 200);
        }),
      );
      await service.getMyReimbursements();
      expect(auth, 'Bearer abc');
    });

    test('traduce el mensaje de error de la API', () async {
      final service = ReimbursementApiService(
        token: () => 'abc',
        client: MockClient((_) async => _json({'message': 'El monto debe ser mayor a cero.'}, 400)),
      );
      await expectLater(
        service.createReimbursement(amount: 0, category: 'Transporte', description: 'Taxi'),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'El monto debe ser mayor a cero.')),
      );
    });

    test('un 401 se convierte en sesión expirada', () async {
      final service = ReimbursementApiService(
        token: () => 'vencido',
        client: MockClient((_) async => _json({'message': 'Tu sesión no es válida.'}, 401)),
      );
      await expectLater(service.getMyReimbursements(), throwsA(isA<SessionExpiredException>()));
    });
  });

  group('AuthService', () {
    test('login correcto guarda la sesión y se recupera al reabrir la app', () async {
      final storage = _MemoryStorage();
      final auth = AuthService(storage: storage, client: MockClient((_) async => _json(_loginJson(), 200)));
      await auth.login('empleado.demo', 'clave');
      expect(auth.token, 'token-de-prueba');

      final reopened = AuthService(storage: storage, client: MockClient((_) async => _json({}, 500)));
      expect((await reopened.restore())?.fullName, 'Empleado Demo');
    });

    test('un aprobador no puede entrar a la app de empleados', () async {
      final auth = AuthService(
        storage: _MemoryStorage(),
        client: MockClient((_) async => _json(_loginJson(role: 'Approver'), 200)),
      );
      await expectLater(
        auth.login('andres.ramirez', 'clave'),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('panel web'))),
      );
      expect(auth.token, isNull);
    });

    test('una sesión guardada pero vencida no se recupera', () async {
      final storage = _MemoryStorage()
        ..value = jsonEncode(Session.fromLoginJson(_loginJson(validFor: const Duration(minutes: -5))).toJson());
      final auth = AuthService(storage: storage, client: MockClient((_) async => _json({}, 500)));
      expect(await auth.restore(), isNull);
      expect(storage.value, isNull);
    });
  });

  testWidgets('credenciales inválidas muestran el mensaje de la API', (tester) async {
    final auth = AuthService(
      storage: _MemoryStorage(),
      client: MockClient((_) async => _json({'message': 'Usuario o contraseña incorrectos.'}, 401)),
    );
    await tester.pumpWidget(ConswareApp(auth: auth, apiClient: MockClient((_) async => _json([], 200))));
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText).at(0), 'empleado.demo');
    await tester.enterText(find.byType(EditableText).at(1), 'mala');
    await tester.tap(find.text('Ingresar'));
    await tester.pumpAndSettle();

    expect(find.text('Usuario o contraseña incorrectos.'), findsOneWidget);
  });

  testWidgets('login correcto lleva al inicio con el nombre y las solicitudes', (tester) async {
    final auth = AuthService(storage: _MemoryStorage(), client: MockClient((_) async => _json(_loginJson(), 200)));
    final api = MockClient((_) async => _json([_rejectedJson], 200));
    await tester.pumpWidget(ConswareApp(auth: auth, apiClient: api));
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText).at(0), 'empleado.demo');
    await tester.enterText(find.byType(EditableText).at(1), 'Empleado2026!');
    await tester.tap(find.text('Ingresar'));
    await tester.pumpAndSettle();

    expect(find.text('¡Hola, Empleado!'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-requests')));
    await tester.pumpAndSettle();
    expect(find.text('No cumple la política de gastos.'), findsWidgets);
  });
}
