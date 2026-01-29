// ============================================================================
// USER MODEL
// ============================================================================

class User {
  final int id;
  final String username;
  final String email;
  final String? fullName;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.username,
    required this.email,
    this.fullName,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      // Parsear como UTC y convertir a zona horaria local
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  User copyWith({
    int? id,
    String? username,
    String? email,
    String? fullName,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          username == other.username &&
          email == other.email;

  @override
  int get hashCode => id.hashCode ^ username.hashCode ^ email.hashCode;

  @override
  String toString() => 'User(id: $id, username: $username, email: $email)';
}

// ============================================================================
// AUTH RESPONSE MODEL
// ============================================================================

class AuthResponse {
  final User user;
  final String accessToken;
  final String refreshToken;
  final String tokenType;

  const AuthResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    this.tokenType = 'Bearer',
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      tokenType: json['token_type'] as String? ?? 'Bearer',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'token_type': tokenType,
    };
  }
}

// ============================================================================
// REMINDER STATUS ENUM
// ============================================================================

enum ReminderStatus {
  pending,
  completed,
  cancelled;

  String toJson() => name;

  static ReminderStatus fromJson(String json) {
    switch (json) {
      case 'pending':
        return ReminderStatus.pending;
      case 'completed':
        return ReminderStatus.completed;
      case 'cancelled':
        return ReminderStatus.cancelled;
      default:
        return ReminderStatus.pending;
    }
  }
}

// ============================================================================
// EVENT MODEL
// ============================================================================

class Event {
  final int id;
  final String title;
  final DateTime eventDate;
  final ReminderStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Event({
    required this.id,
    required this.title,
    required this.eventDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as int,
      title: json['title'] as String,
      // Parsear como UTC y convertir a zona horaria local
      eventDate: DateTime.parse(json['event_date'] as String).toLocal(),
      status: ReminderStatus.fromJson(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'event_date': eventDate.toIso8601String(),
      'status': status.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Event copyWith({
    int? id,
    String? title,
    DateTime? eventDate,
    ReminderStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      eventDate: eventDate ?? this.eventDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Event &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          eventDate == other.eventDate;

  @override
  int get hashCode => id.hashCode ^ title.hashCode ^ eventDate.hashCode;

  @override
  String toString() => 'Event(id: $id, title: $title, date: $eventDate)';
}

// ============================================================================
// EVENT LIST RESPONSE MODEL
// ============================================================================

class EventListResponse {
  final List<Event> events;
  final int total;

  const EventListResponse({
    required this.events,
    required this.total,
  });

  factory EventListResponse.fromJson(Map<String, dynamic> json) {
    return EventListResponse(
      events: (json['events'] as List<dynamic>)
          .map((e) => Event.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'events': events.map((e) => e.toJson()).toList(),
      'total': total,
    };
  }
}

// ============================================================================
// REQUEST MODELS
// ============================================================================

class SignUpRequest {
  final String username;
  final String email;
  final String password;
  final String? fullName;

  const SignUpRequest({
    required this.username,
    required this.email,
    required this.password,
    this.fullName,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'password': password,
      if (fullName != null) 'full_name': fullName,
    };
  }
}

class SignInRequest {
  final String usernameOrEmail;
  final String password;

  const SignInRequest({
    required this.usernameOrEmail,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'username_or_email': usernameOrEmail,
      'password': password,
    };
  }
}

class CreateEventRequest {
  final String title;
  final DateTime eventDate;

  const CreateEventRequest({
    required this.title,
    required this.eventDate,
  });

  Map<String, dynamic> toJson() {
    // Convertir la fecha local a UTC antes de enviarla al backend
    final utcDate = eventDate.toUtc();
    return {
      'title': title,
      'event_date': utcDate.toIso8601String(),
    };
  }
}

class UpdateEventRequest {
  final String? title;
  final DateTime? eventDate;

  const UpdateEventRequest({
    this.title,
    this.eventDate,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (title != null) map['title'] = title;
    if (eventDate != null) {
      // Convertir la fecha local a UTC antes de enviarla al backend
      final utcDate = eventDate!.toUtc();
      map['event_date'] = utcDate.toIso8601String();
    }
    return map;
  }
}

// ============================================================================
// FAILURE MODEL
// ============================================================================

abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}