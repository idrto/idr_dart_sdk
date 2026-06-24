import 'package:idr_dart_sdk/idr_dart_sdk.dart';
import 'package:test/test.dart';

void main() {
  group('IdrResult', () {
    test('fromJson parses success', () {
      final result = IdrResult.fromJson({
        'ok': true,
        'code': 0,
        'data': {'entity_id': 'user@corp.com'},
      });
      expect(result.ok, isTrue);
      expect(result.code, 0);
      expect(result.data['entity_id'], 'user@corp.com');
    });

    test('fromJson parses failure', () {
      final result = IdrResult.fromJson({
        'ok': false,
        'code': 2,
        'message': 'Not logged in',
      });
      expect(result.ok, isFalse);
      expect(result.message, 'Not logged in');
    });
  });

  group('IdrSession', () {
    test('fromJson maps connect payload', () {
      final session = IdrSession.fromJson({
        'entity_id': 'corp.com',
        'host': 'laptop',
        'service': '22',
        'signal_session': 'sess-1',
        'local_port': 54321,
      });
      expect(session.entityId, 'corp.com');
      expect(session.host, 'laptop');
      expect(session.service, '22');
      expect(session.signalSession, 'sess-1');
      expect(session.localPort, 54321);
    });
  });

  group('IdrConfig', () {
    test('holds tenant api base url', () {
      const config = IdrConfig(
        apiBaseUrl: 'https://sig.scomm.ai',
        stateDir: '/data/idr',
      );
      expect(config.apiBaseUrl, 'https://sig.scomm.ai');
      expect(config.stateDir, '/data/idr');
    });
  });

  group('IdrConnectOptions', () {
    test('defaults match Rust ConnectOptions', () {
      const opts = IdrConnectOptions();
      expect(opts.holdSeconds, 0);
      expect(opts.localPort, 0);
      expect(opts.tunnelTimeoutSeconds, 60);
    });
  });

  group('IdrEvent', () {
    test('join pending carries request path', () {
      const event = IdrJoinPendingEvent(requestId: '/tmp/join.req', host: 'phone');
      expect(event, isA<IdrJoinPendingEvent>());
      expect(event.host, 'phone');
    });
  });

  group('IdrTokenStorage', () {
    test('NoOp storage is inert', () async {
      const storage = NoOpIdrTokenStorage();
      await storage.write('k', 'v');
      expect(await storage.read('k'), isNull);
      await storage.delete('k');
    });
  });
}
