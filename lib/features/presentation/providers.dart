import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';
import '../data/repository.dart';
import '../domain/models.dart';

// ============================================================================
// INFRASTRUCTURE PROVIDERS
// ============================================================================

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden');
});

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final repositoryProvider = Provider<Repository>((ref) {
  return Repository(ref.watch(apiClientProvider));
});

// ============================================================================
// AUTH STATE
// ============================================================================

class AuthState {
  final User? user;
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  
  const AuthState({
    this.user,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
  });
  
  AuthState copyWith({
    User? user,
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Helper function to get error message from Failure
String _getFailureMessage(Failure failure) {
  return failure.message;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Repository _repository;
  final ApiClient _apiClient;
  
  AuthNotifier(this._repository, this._apiClient) : super(const AuthState()) {
    checkAuthStatus();
  }
  
  Future<void> checkAuthStatus() async {
    final hasToken = await _apiClient.hasValidToken();
    if (hasToken) {
      final result = await _repository.getCurrentUser();
      result.fold(
        (failure) => state = const AuthState(),
        (user) => state = AuthState(user: user, isAuthenticated: true),
      );
    }
  }
  
  Future<void> signIn(String usernameOrEmail, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _repository.signIn(
      SignInRequest(usernameOrEmail: usernameOrEmail, password: password),
    );
    
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: _getFailureMessage(failure),
      ),
      (authResponse) => state = AuthState(
        user: authResponse.user,
        isAuthenticated: true,
        isLoading: false,
      ),
    );
  }
  
  Future<void> signUp(String username, String email, String password, String? fullName) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _repository.signUp(
      SignUpRequest(
        username: username,
        email: email,
        password: password,
        fullName: fullName,
      ),
    );
    
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: _getFailureMessage(failure),
      ),
      (authResponse) => state = AuthState(
        user: authResponse.user,
        isAuthenticated: true,
        isLoading: false,
      ),
    );
  }
  
  Future<void> signOut() async {
    await _repository.signOut();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(repositoryProvider),
    ref.watch(apiClientProvider),
  );
});

// ============================================================================
// EVENTS STATE
// ============================================================================

class EventsState {
  final List<Event> events;
  final List<Event> upcomingEvents;
  final bool isLoading;
  final String? error;
  
  const EventsState({
    this.events = const [],
    this.upcomingEvents = const [],
    this.isLoading = false,
    this.error,
  });
  
  EventsState copyWith({
    List<Event>? events,
    List<Event>? upcomingEvents,
    bool? isLoading,
    String? error,
  }) {
    return EventsState(
      events: events ?? this.events,
      upcomingEvents: upcomingEvents ?? this.upcomingEvents,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class EventsNotifier extends StateNotifier<EventsState> {
  final Repository _repository;
  
  EventsNotifier(this._repository) : super(const EventsState());
  
  Future<void> loadEvents() async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _repository.getAllEvents();
    
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: _getFailureMessage(failure),
      ),
      (events) => state = state.copyWith(events: events, isLoading: false),
    );
  }
  
  Future<void> loadUpcomingEvents() async {
    final result = await _repository.getUpcomingEvents();
    
    result.fold(
      (failure) => null,
      (events) => state = state.copyWith(upcomingEvents: events),
    );
  }
  
  Future<bool> createEvent(String title, DateTime eventDate) async {
    final result = await _repository.createEvent(
      CreateEventRequest(title: title, eventDate: eventDate),
    );
    
    return result.fold(
      (failure) {
        state = state.copyWith(error: _getFailureMessage(failure));
        return false;
      },
      (event) {
        loadEvents();
        loadUpcomingEvents();
        return true;
      },
    );
  }
  
  Future<bool> updateEvent(int id, String? title, DateTime? eventDate) async {
    final result = await _repository.updateEvent(
      id,
      UpdateEventRequest(title: title, eventDate: eventDate),
    );
    
    return result.fold(
      (failure) => false,
      (event) {
        loadEvents();
        loadUpcomingEvents();
        return true;
      },
    );
  }
  
  Future<bool> deleteEvent(int id) async {
    final result = await _repository.deleteEvent(id);
    
    return result.fold(
      (failure) => false,
      (_) {
        loadEvents();
        loadUpcomingEvents();
        return true;
      },
    );
  }
  
  Future<bool> completeEvent(int id) async {
    final result = await _repository.completeEvent(id);
    
    return result.fold(
      (failure) => false,
      (event) {
        loadEvents();
        loadUpcomingEvents();
        return true;
      },
    );
  }
  
  Future<bool> cancelEvent(int id) async {
    final result = await _repository.cancelEvent(id);
    
    return result.fold(
      (failure) => false,
      (event) {
        loadEvents();
        loadUpcomingEvents();
        return true;
      },
    );
  }
}

final eventsProvider = StateNotifierProvider<EventsNotifier, EventsState>((ref) {
  return EventsNotifier(ref.watch(repositoryProvider));
});

// ============================================================================
// COMPUTED PROVIDERS
// ============================================================================

final pendingEventsCountProvider = Provider<int>((ref) {
  final events = ref.watch(eventsProvider).events;
  return events.where((e) => e.status == ReminderStatus.pending).length;
});

final completedEventsCountProvider = Provider<int>((ref) {
  final events = ref.watch(eventsProvider).events;
  return events.where((e) => e.status == ReminderStatus.completed).length;
});