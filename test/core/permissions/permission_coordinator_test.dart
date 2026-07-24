import 'dart:async';

import 'package:dali_cash/core/permissions/permission_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  test('startup requests notification then tracking only once', () async {
    final events = <String>[];
    final coordinator = PermissionCoordinator(
      requestNotificationPermission: () async {
        events.add('notification');
        return 'authorized';
      },
      requestTrackingPermission: () async {
        events.add('tracking');
        return 'authorized';
      },
      delay: (_) async {
        events.add('delay');
      },
    );

    final first = coordinator.requestStartupPermissions();
    final second = coordinator.requestStartupPermissions();
    await Future.wait([first, second]);
    await coordinator.requestStartupPermissions();

    expect(events, ['delay', 'notification', 'delay', 'tracking']);
  });

  test('startup permission failures do not escape', () async {
    var trackingRequests = 0;
    final coordinator = PermissionCoordinator(
      requestNotificationPermission: () async => throw StateError('failed'),
      requestTrackingPermission: () async {
        trackingRequests++;
        return 'authorized';
      },
      requestDelay: Duration.zero,
    );

    await expectLater(coordinator.requestStartupPermissions(), completes);

    expect(trackingRequests, 0);
  });

  test('each resume waits before requesting tracking permission', () async {
    final events = <String>[];
    final coordinator = PermissionCoordinator(
      requestNotificationPermission: () async => 'authorized',
      requestTrackingPermission: () async {
        events.add('tracking');
        return 'authorized';
      },
      delay: (_) async {
        events.add('delay');
      },
    );

    await coordinator.requestResumeTrackingPermission();
    await coordinator.requestResumeTrackingPermission();

    expect(events, ['delay', 'tracking', 'delay', 'tracking']);
  });

  test(
    'location service disabled requires the service settings prompt',
    () async {
      final coordinator = _locationCoordinator(
        serviceStatus: ServiceStatus.disabled,
        permissionStatus: PermissionStatus.granted,
      );

      final decision = await coordinator.requestCertificationLocation();

      expect(decision, CertificationLocationDecision.serviceDisabled);
    },
  );

  test('granted location proceeds without requesting again', () async {
    var requests = 0;
    final coordinator = _locationCoordinator(
      serviceStatus: ServiceStatus.enabled,
      permissionStatus: PermissionStatus.granted,
      onRequest: () => requests++,
    );

    final decision = await coordinator.requestCertificationLocation();

    expect(decision, CertificationLocationDecision.granted);
    expect(requests, 0);
  });

  test('first location denial stops certification without settings', () async {
    final coordinator = _locationCoordinator(
      serviceStatus: ServiceStatus.enabled,
      permissionStatus: PermissionStatus.denied,
      requestedStatus: PermissionStatus.denied,
    );

    final decision = await coordinator.requestCertificationLocation();

    expect(decision, CertificationLocationDecision.denied);
  });

  test('permanently denied location requires app settings', () async {
    final coordinator = _locationCoordinator(
      serviceStatus: ServiceStatus.enabled,
      permissionStatus: PermissionStatus.permanentlyDenied,
    );

    final decision = await coordinator.requestCertificationLocation();

    expect(decision, CertificationLocationDecision.settingsRequired);
  });

  test('restricted location requires app settings', () async {
    final coordinator = _locationCoordinator(
      serviceStatus: ServiceStatus.enabled,
      permissionStatus: PermissionStatus.restricted,
    );

    final decision = await coordinator.requestCertificationLocation();

    expect(decision, CertificationLocationDecision.settingsRequired);
  });

  test('concurrent certification entries share one location request', () async {
    var serviceChecks = 0;
    var statusChecks = 0;
    final releaseStatus = Completer<void>();
    final coordinator = PermissionCoordinator(
      requestNotificationPermission: () async => 'authorized',
      requestTrackingPermission: () async => 'authorized',
      requestDelay: Duration.zero,
      locationServiceStatusProvider: () async {
        serviceChecks++;
        return ServiceStatus.enabled;
      },
      locationPermissionStatusProvider: () async {
        statusChecks++;
        await releaseStatus.future;
        return PermissionStatus.granted;
      },
      locationPermissionRequester: () async => PermissionStatus.granted,
    );

    final first = coordinator.requestCertificationLocation();
    final second = coordinator.requestCertificationLocation();
    releaseStatus.complete();
    final results = await Future.wait([first, second]);

    expect(results, [
      CertificationLocationDecision.granted,
      CertificationLocationDecision.granted,
    ]);
    expect(serviceChecks, 1);
    expect(statusChecks, 1);
  });
}

PermissionCoordinator _locationCoordinator({
  required ServiceStatus serviceStatus,
  required PermissionStatus permissionStatus,
  PermissionStatus requestedStatus = PermissionStatus.granted,
  void Function()? onRequest,
}) {
  return PermissionCoordinator(
    requestNotificationPermission: () async => 'authorized',
    requestTrackingPermission: () async => 'authorized',
    requestDelay: Duration.zero,
    locationServiceStatusProvider: () async => serviceStatus,
    locationPermissionStatusProvider: () async => permissionStatus,
    locationPermissionRequester: () async {
      onRequest?.call();
      return requestedStatus;
    },
  );
}
