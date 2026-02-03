import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';
import '../../core/configuration/app_logger.dart';
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
    bool clearError = false, // Nuevo parámetro para limpiar el error
  }) {
    return AuthState(
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
  
  // Helper para limpiar error
  AuthState clearError() => copyWith(clearError: true);
}

// Helper function to get error message from Failure
String _getFailureMessage(Failure failure) {
  // Personalizar mensajes de error para mejor UX
  if (failure is UnauthorizedFailure) {
    if (failure.message.toLowerCase().contains('invalid') || 
        failure.message.toLowerCase().contains('incorrect')) {
      return 'Invalid username or password. Please try again.';
    }
    return 'Authentication failed. Please check your credentials.';
  } else if (failure is ValidationFailure) {
    return failure.message;
  } else if (failure is NetworkFailure) {
    return 'No internet connection. Please check your network.';
  } else if (failure is ServerFailure) {
    return 'Server error. Please try again later.';
  }
  return failure.message;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Repository _repository;
  final ApiClient _apiClient;
  
  AuthNotifier(this._repository, this._apiClient) : super(const AuthState()) {
    checkAuthStatus();
  }
  
  Future<void> checkAuthStatus() async {
    try {
      final hasToken = await _apiClient.hasValidToken();
      if (hasToken) {
        final result = await _repository.getCurrentUser();
        result.fold(
          (failure) {
            logger.warning('[Auth] Failed to get current user: ${failure.message}');
            state = const AuthState();
          },
          (user) {
            logger.info('[Auth] User authenticated: ${user.username}');
            state = AuthState(user: user, isAuthenticated: true);
          },
        );
      }
    } catch (e, stackTrace) {
      logger.error('[Auth] Error checking auth status', e, stackTrace);
      state = const AuthState();
    }
  }
  
  Future<void> signIn(String usernameOrEmail, String password) async {
    logger.info('[Auth] Attempting sign in for: $usernameOrEmail');
    
    // Limpiar error previo y mostrar loading
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      final result = await _repository.signIn(
        SignInRequest(usernameOrEmail: usernameOrEmail, password: password),
      );
      
      result.fold(
        (failure) {
          logger.warning('[Auth] Sign in failed: ${failure.message}');
          state = state.copyWith(
            isLoading: false,
            error: _getFailureMessage(failure),
          );
        },
        (authResponse) {
          logger.info('[Auth] Sign in successful: ${authResponse.user.username}');
          state = AuthState(
            user: authResponse.user,
            isAuthenticated: true,
            isLoading: false,
            error: null,
          );
        },
      );
    } catch (e, stackTrace) {
      logger.error('[Auth] Unexpected error during sign in', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred. Please try again.',
      );
    }
  }
  
  Future<void> signUp(String username, String email, String password, String? fullName) async {
    logger.info('[Auth] Attempting sign up for: $username ($email)');
    
    // Limpiar error previo y mostrar loading
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      final result = await _repository.signUp(
        SignUpRequest(
          username: username,
          email: email,
          password: password,
          fullName: fullName,
        ),
      );
      
      result.fold(
        (failure) {
          logger.warning('[Auth] Sign up failed: ${failure.message}');
          
          // Personalizar mensajes de error de validación
          String errorMessage = _getFailureMessage(failure);
          
          // Mejorar mensajes específicos
          if (failure.message.toLowerCase().contains('already exists')) {
            errorMessage = 'Username or email already exists. Please try another.';
          } else if (failure.message.toLowerCase().contains('username')) {
            errorMessage = 'Invalid username. Please use 3-20 characters.';
          } else if (failure.message.toLowerCase().contains('email')) {
            errorMessage = 'Invalid email address. Please check and try again.';
          } else if (failure.message.toLowerCase().contains('password')) {
            errorMessage = 'Password must be at least 8 characters with letters and numbers.';
          }
          
          state = state.copyWith(
            isLoading: false,
            error: errorMessage,
          );
        },
        (authResponse) {
          logger.info('[Auth] Sign up successful: ${authResponse.user.username}');
          state = AuthState(
            user: authResponse.user,
            isAuthenticated: true,
            isLoading: false,
            error: null,
          );
        },
      );
    } catch (e, stackTrace) {
      logger.error('[Auth] Unexpected error during sign up', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred. Please try again.',
      );
    }
  }
  
  Future<void> signOut() async {
    logger.info('[Auth] Signing out user: ${state.user?.username}');
    await _repository.signOut();
    state = const AuthState();
  }
  
  // Método para limpiar errores manualmente
  void clearError() {
    if (state.error != null) {
      state = state.clearError();
    }
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
    bool clearError = false,
  }) {
    return EventsState(
      events: events ?? this.events,
      upcomingEvents: upcomingEvents ?? this.upcomingEvents,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
  
  EventsState clearError() => copyWith(clearError: true);
}

class EventsNotifier extends StateNotifier<EventsState> {
  final Repository _repository;
  
  EventsNotifier(this._repository) : super(const EventsState());
  
  Future<void> loadEvents() async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    final result = await _repository.getAllEvents();
    
    result.fold(
      (failure) {
        logger.warning('[Events] Failed to load events: ${failure.message}');
        state = state.copyWith(
          isLoading: false,
          error: _getFailureMessage(failure),
        );
      },
      (events) {
        logger.info('[Events] Loaded ${events.length} events');
        state = state.copyWith(
          events: events,
          isLoading: false,
          clearError: true,
        );
      },
    );
  }
  
  Future<void> loadUpcomingEvents() async {
    final result = await _repository.getUpcomingEvents();
    
    result.fold(
      (failure) => logger.warning('[Events] Failed to load upcoming events: ${failure.message}'),
      (events) {
        logger.info('[Events] Loaded ${events.length} upcoming events');
        state = state.copyWith(upcomingEvents: events);
      },
    );
  }
  
  // MODIFICADO: Ahora retorna el evento creado
  Future<Event?> createEvent(String title, DateTime eventDate) async {
    logger.info('[Events] Creating event: $title at $eventDate');
    
    final result = await _repository.createEvent(
      CreateEventRequest(title: title, eventDate: eventDate),
    );
    
    return result.fold(
      (failure) {
        logger.warning('[Events] Failed to create event: ${failure.message}');
        state = state.copyWith(error: _getFailureMessage(failure));
        return null;
      },
      (event) {
        logger.info('[Events] Event created successfully: ${event.id}');
        loadEvents();
        loadUpcomingEvents();
        return event;
      },
    );
  }
  
  Future<bool> updateEvent(int id, String? title, DateTime? eventDate) async {
    logger.info('[Events] Updating event $id');
    
    final result = await _repository.updateEvent(
      id,
      UpdateEventRequest(title: title, eventDate: eventDate),
    );
    
    return result.fold(
      (failure) {
        logger.warning('[Events] Failed to update event: ${failure.message}');
        state = state.copyWith(error: _getFailureMessage(failure));
        return false;
      },
      (event) {
        logger.info('[Events] Event updated successfully');
        loadEvents();
        loadUpcomingEvents();
        return true;
      },
    );
  }
  
  Future<bool> deleteEvent(int id) async {
    logger.info('[Events] Deleting event $id');
    
    final result = await _repository.deleteEvent(id);
    
    return result.fold(
      (failure) {
        logger.warning('[Events] Failed to delete event: ${failure.message}');
        return false;
      },
      (_) {
        logger.info('[Events] Event deleted successfully');
        loadEvents();
        loadUpcomingEvents();
        return true;
      },
    );
  }
  
  Future<bool> completeEvent(int id) async {
    logger.info('[Events] Completing event $id');
    
    final result = await _repository.completeEvent(id);
    
    return result.fold(
      (failure) {
        logger.warning('[Events] Failed to complete event: ${failure.message}');
        return false;
      },
      (event) {
        logger.info('[Events] Event completed successfully');
        loadEvents();
        loadUpcomingEvents();
        return true;
      },
    );
  }
  
  Future<bool> cancelEvent(int id) async {
    logger.info('[Events] Cancelling event $id');
    
    final result = await _repository.cancelEvent(id);
    
    return result.fold(
      (failure) {
        logger.warning('[Events] Failed to cancel event: ${failure.message}');
        return false;
      },
      (event) {
        logger.info('[Events] Event cancelled successfully');
        loadEvents();
        loadUpcomingEvents();
        return true;
      },
    );
  }
  
  void clearError() {
    if (state.error != null) {
      state = state.clearError();
    }
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