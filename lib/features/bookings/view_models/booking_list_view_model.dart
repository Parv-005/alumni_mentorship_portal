import 'dart:developer' as developer;

import 'package:alumni_mentorship_platform/data/models/booking_request.dart';
import 'package:alumni_mentorship_platform/data/repositories/booking_repository.dart';
import 'package:flutter/foundation.dart';

/// View model for the role-aware [BookingListScreen]. Picks the right
/// repository call based on the current user's role and caches mentor /
/// student display names so the list can render synchronously.
class BookingListViewModel extends ChangeNotifier {
  BookingListViewModel({
    required this.isMentor,
    required this.currentUserId,
    BookingRepository? bookingRepository,
  }) : _bookingRepository = bookingRepository ?? const BookingRepository();

  /// True when the current viewer is a mentor (sees incoming requests)
  /// rather than a student (sees their own requests).
  final bool isMentor;

  /// The current user's profile id, used to detect "own" bookings.
  final String? currentUserId;
  final BookingRepository _bookingRepository;

  List<BookingRequest> _bookings = const <BookingRequest>[];
  bool _loading = false;
  String? _error;

  List<BookingRequest> get bookings => _bookings;
  bool get loading => _loading;
  String? get error => _error;

  /// Loads the appropriate list for the current user. Coalesces concurrent
  /// loads so pull-to-refresh doesn't race an in-flight request.
  Future<void> load() async {
    if (_loading) {
      return;
    }
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _bookings = isMentor
          ? await _bookingRepository.listForMentor()
          : await _bookingRepository.listForStudent();
    } on Object catch (e, st) {
      developer.log('BookingList load failed', error: e, stackTrace: st);
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Alias for [load] used by pull-to-refresh.
  Future<void> refresh() => load();
}
