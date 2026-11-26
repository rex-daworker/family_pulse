import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// A window in which every member of the family is free.
class FreeSlot {
  const FreeSlot({
    required this.start,
    required this.end,
    required this.durationMinutes,
    required this.dayIndex,
  });

  final DateTime start;
  final DateTime end;
  final int durationMinutes;

  /// Offset from the first day of the searched range — 0 is today.
  final int dayIndex;

  factory FreeSlot.fromJson(Map<String, dynamic> json) {
    return FreeSlot(
      start: DateTime.parse(json['startIso'] as String).toLocal(),
      end: DateTime.parse(json['endIso'] as String).toLocal(),
      durationMinutes: (json['durationMinutes'] as num).toInt(),
      dayIndex: (json['dayIndex'] as num).toInt(),
    );
  }
}

class FreeTimeRangeResult {
  const FreeTimeRangeResult({
    required this.slots,
    required this.memberCount,
    required this.eventsScanned,
  });

  final List<FreeSlot> slots;
  final int memberCount;
  final int eventsScanned;
}

/// Raised for a failed call to the free-time service. `code` is stable and
/// language-neutral so the UI can decide what to show; it is never displayed
/// to the user directly.
class FreeTimeApiError implements Exception {
  const FreeTimeApiError(this.code);
  final String code;

  @override
  String toString() => 'FreeTimeApiError($code)';
}

/// Client for the Azure Functions multi-day free-time endpoint.
///
/// The single-day search stays on the device in [EventService.findFreeSlots] —
/// it is one small read and it must keep working offline-ish and instantly.
/// This client is only for the range search, which reads far more of the
/// calendar and would otherwise be recomputed identically on every family
/// member's phone.
///
/// Authentication piggybacks entirely on Firebase. The current user's ID token
/// is attached as a bearer token and verified server-side; no second identity
/// system exists and no credential is stored in the app.
class FreeTimeApi {
  FreeTimeApi({http.Client? client, FirebaseAuth? auth})
    : _client = client ?? http.Client(),
      _auth = auth ?? FirebaseAuth.instance;

  final http.Client _client;
  final FirebaseAuth _auth;

  /// Base URL of the Function App. Overridable at build time so the same
  /// source builds against a local `func start` or a different deployment:
  ///   flutter build web --dart-define=AZURE_FUNCTIONS_BASE_URL=http://localhost:7071
  static const String baseUrl = String.fromEnvironment(
    'AZURE_FUNCTIONS_BASE_URL',
    defaultValue: 'https://familypulse-fn-sznzoj.azurewebsites.net',
  );

  static const Duration _timeout = Duration(seconds: 20);

  Future<FreeTimeRangeResult> findFreeSlotsInRange({
    required String familyId,
    int days = 14,
    int minDurationMinutes = 60,
    int dayStartHour = 8,
    int dayEndHour = 22,
    int maxResults = 10,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw const FreeTimeApiError('not_signed_in');

    final token = await user.getIdToken();
    if (token == null) throw const FreeTimeApiError('no_token');

    // The server works in absolute instants. Sending local midnight as a UTC
    // instant keeps every timezone decision here, where the device's real
    // offset is known, rather than guessing at it server-side.
    final now = DateTime.now();
    final localMidnight = DateTime(now.year, now.month, now.day);

    late final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$baseUrl/api/free-slots'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'familyId': familyId,
              'rangeStartIso': localMidnight.toUtc().toIso8601String(),
              'days': days,
              'minDurationMinutes': minDurationMinutes,
              'dayStartHour': dayStartHour,
              'dayEndHour': dayEndHour,
              'maxResults': maxResults,
            }),
          )
          .timeout(_timeout);
    } catch (_) {
      // Covers DNS failure, no connectivity, TLS problems and the timeout.
      // A cold Flex Consumption worker can take a few seconds on the first
      // call of the day, which is why the timeout is generous.
      throw const FreeTimeApiError('unreachable');
    }

    switch (response.statusCode) {
      case 200:
        break;
      case 401:
        throw const FreeTimeApiError('unauthorized');
      case 403:
        throw const FreeTimeApiError('not_a_family_member');
      case 404:
        throw const FreeTimeApiError('family_empty');
      default:
        throw FreeTimeApiError('server_${response.statusCode}');
    }

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw const FreeTimeApiError('bad_response');
    }

    final slots = (body['slots'] as List<dynamic>? ?? [])
        .map((item) => FreeSlot.fromJson(item as Map<String, dynamic>))
        .toList();

    return FreeTimeRangeResult(
      slots: slots,
      memberCount: (body['memberCount'] as num?)?.toInt() ?? 0,
      eventsScanned:
          ((body['scanned'] as Map<String, dynamic>?)?['events'] as num?)
              ?.toInt() ??
          0,
    );
  }
}

final freeTimeApiProvider = Provider<FreeTimeApi>((ref) => FreeTimeApi());
