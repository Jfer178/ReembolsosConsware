import 'dart:convert';

import 'package:consware_reembolsos/main.dart';
import 'package:consware_reembolsos/models/reimbursement.dart';
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
};

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

  group('Reimbursement.fromJson', () {
    test('mapea la respuesta de la API', () {
      final item = Reimbursement.fromJson(_rejectedJson);
      expect(item.status, ReimbursementStatus.rejected);
      expect(item.rejectionReason, 'No cumple la política de gastos.');
      expect(item.code, 'RB-2026-0008');
      expect(item.exceedsAutoApprovalLimit, isTrue);
      expect(item.createdAtUtc.isUtc, isTrue);
    });

    test('un estado desconocido es un error de formato', () {
      expect(
        () => Reimbursement.fromJson({..._rejectedJson, 'status': 'Foo'}),
        throwsFormatException,
      );
    });
  });

  group('ReimbursementApiService', () {
    test('traduce el mensaje de error de la API', () async {
      final service = ReimbursementApiService(
        client: MockClient((_) async => http.Response(
              jsonEncode({'message': 'El monto debe ser mayor a cero.'}),
              400,
              headers: {'content-type': 'application/json; charset=utf-8'},
            )),
      );
      await expectLater(
        service.createReimbursement(
          employeeName: 'Empleado Demo',
          amount: 0,
          category: 'Transporte',
          description: 'Taxi',
        ),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', 'El monto debe ser mayor a cero.')),
      );
    });

    test('un fallo de conexión es un mensaje legible', () async {
      final service = ReimbursementApiService(
        client: MockClient((_) async => throw http.ClientException('offline')),
      );
      await expectLater(
        service.getMyReimbursements('Empleado Demo'),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', contains('No se pudo conectar'))),
      );
    });
  });

  testWidgets('con la API apagada muestra el error y Reintentar', (tester) async {
    final service = ReimbursementApiService(
      client: MockClient((_) async => throw http.ClientException('offline')),
    );
    await tester.pumpWidget(ConswareApp(service: service));
    await tester.pumpAndSettle();

    expect(find.text('Reintentar'), findsWidgets);
  });

  testWidgets('muestra las solicitudes y el motivo de rechazo', (tester) async {
    final service = ReimbursementApiService(
      client: MockClient((_) async => http.Response(
            jsonEncode([_rejectedJson]),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          )),
    );
    await tester.pumpWidget(ConswareApp(service: service));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-requests')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Taxi a reunión'), findsWidgets);
    expect(find.text('No cumple la política de gastos.'), findsWidgets);
  });
}
