import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'error_handler.dart';
import '../models/user.dart' as app_user;
import '../models/match.dart';
import '../models/team.dart';
import '../models/notification.dart';
import '../models/team.dart' as team_models;
import '../models/city.dart';
import '../utils/validators.dart';
import 'cache_service.dart';

// Default retry configuration for network operations
final _defaultRetryConfig = RetryConfig(
  maxAttempts: 3,
  initialDelay: const Duration(seconds: 1),
  backoffMultiplier: 2.0,
  maxDelay: const Duration(seconds: 10),
  shouldRetry: (error) => error is NetworkError,
);

class ApiService {
    final SupabaseClient _supabase = Supabase.instance.client;
    final CacheService _cacheService = CacheService();

    // Subscription management
    final Map<String, RealtimeChannel> _activeSubscriptions = {};

    // Debug logging
    void _log(String message, {String? context, dynamic error}) {
      final timestamp = DateTime.now().toIso8601String();
      final logMessage = '[ApiService:$timestamp] $message';
      if (context != null) {
        debugPrint('$logMessage (Context: $context)');
      } else {
        debugPrint(logMessage);
      }
      if (error != null) {
        debugPrint('$logMessage Error: $error');
      }
    }

    ApiService({String environment = 'production'}) {
      // Real-time subscriptions are now initialized after authentication
      // in the AuthProvider to prevent unauthenticated subscription attempts
    }

    /// Cleanup method to dispose of subscriptions
    Future<void> dispose() async {
      // Create a copy of the values to avoid concurrent modification
      final subscriptions = List<RealtimeChannel>.from(_activeSubscriptions.values);
      for (final subscription in subscriptions) {
        try {
          await subscription.unsubscribe();
        } catch (e) {
          ErrorHandler.logError(e, null, 'ApiService.dispose');
        }
      }
      _activeSubscriptions.clear();
    }



  // Real-time subscriptions
  Stream<List<Match>> get matchesStream => _supabase
      .from('matches')
      .stream(primaryKey: ['id'])
      .eq('status', 'open')
      .order('match_date')
      .map((data) => data.map((json) => Match.fromJson(json)).toList());

  Stream<List<Team>> get teamsStream => _supabase
      .from('teams')
      .stream(primaryKey: ['id'])
      .order('created_at')
      .map((data) => data.map((json) => Team.fromJson(json)).toList());

  Stream<List<NotificationModel>> get notificationsStream => _supabase
      .from('notifications')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .map((data) => data.map((json) => NotificationModel.fromJson(json)).toList());

  // User profile real-time stream
  Stream<app_user.User?> get userProfileStream {
    final user = _supabase.auth.currentUser;
    if (user == null) return Stream.value(null);

    return _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', user.id)
        .map((data) {
          if (data.isEmpty) return null;
          return app_user.User.fromJson(data.first);
        });
  }

  // User-specific notifications stream
  Stream<List<NotificationModel>> get userNotificationsStream {
    final user = _supabase.auth.currentUser;
    if (user == null) return Stream.value([]);

    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => NotificationModel.fromJson(json)).toList());
  }

  // User teams stream
  Stream<List<Team>> get userTeamsStream {
    final user = _supabase.auth.currentUser;
    if (user == null) return Stream.value([]);

    return _supabase
        .from('teams')
        .stream(primaryKey: ['id'])
        .eq('owner_id', user.id)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => Team.fromJson(json)).toList());
  }

  /// Initialize real-time subscriptions after authentication
  /// This should be called from AuthProvider after successful login
  void initializeRealtimeSubscriptions() {
    // Prevent race conditions by checking authentication first
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // Only initialize if not already initialized
    if (_activeSubscriptions.isNotEmpty) return;

    // Set up real-time listeners for critical data with error handling
    _setupSubscription('teams', 'teams', (payload) {
      // Only invalidate teams cache when data changes
      _cacheService.invalidateTeamsCache();
    });

    _setupSubscription('users', 'users', (payload) {
      // Only invalidate user stats cache when user data changes
      _cacheService.invalidateUserStatsCache();
    });
  }

   void _setupSubscription(String channelName, String tableName, Function(PostgresChangePayload) callback) {
     _log('Setting up real-time subscription for $channelName', context: 'setupSubscription');
     // Check authentication before setting up subscription
     final user = _supabase.auth.currentUser;
     if (user == null) {
       _log('Skipping real-time subscription setup for $channelName: user not authenticated', context: 'setupSubscription');
       return;
     }

     try {
       _log('Creating channel: $channelName', context: 'setupSubscription');
       final channel = _supabase.channel(channelName);

       channel.onPostgresChanges(
         event: PostgresChangeEvent.all,
         schema: 'public',
         table: tableName,
         callback: (payload) {
           try {
             _log('Received real-time update for $tableName', context: 'realtimeCallback');
             callback(payload);
           } catch (e) {
             _log('Error in real-time callback for $tableName', context: 'realtimeCallback', error: e);
             ErrorHandler.logError(e, null, 'RealtimeCallback_$tableName');
           }
         },
       );

       // Store reference for cleanup
       _activeSubscriptions[channelName] = channel;
       _log('Stored subscription reference for $channelName', context: 'setupSubscription');

       channel.subscribe(
         (status, error) {
           if (status == RealtimeSubscribeStatus.subscribed) {
             _log('Successfully subscribed to $channelName', context: 'subscriptionStatus');
           } else if (status == RealtimeSubscribeStatus.closed) {
             // Subscription closed, remove from active subscriptions
             _activeSubscriptions.remove(channelName);
             _log('Subscription closed for $channelName', context: 'subscriptionStatus');
           } else if (error != null) {
             _log('Subscription error for $channelName', context: 'subscriptionStatus', error: error);
             ErrorHandler.logError(error, null, 'RealtimeSubscription_$channelName');
             // Only attempt to resubscribe if user is still authenticated
             final currentUser = _supabase.auth.currentUser;
             if (currentUser != null && !_activeSubscriptions.containsKey(channelName)) {
               _log('Attempting to resubscribe to $channelName in 5 seconds', context: 'subscriptionStatus');
               Future.delayed(const Duration(seconds: 5), () {
                 _setupSubscription(channelName, tableName, callback);
               });
             }
           }
         },
       );
     } catch (e) {
       _log('Failed to setup real-time subscription for $channelName', context: 'setupSubscription', error: e);
       ErrorHandler.logError(e, null, 'SetupRealtimeSubscription_$channelName');
     }
   }

  // Auth methods - Using Supabase Auth directly
  Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
    String role = 'player',
    String? gender,
    int? age,
    String? phone,
  }) async {
    _log('Starting signup process', context: 'signup');
    // Input validation
    final nameError = validateName(name);
    if (nameError != null) throw ValidationError(nameError);

    final emailError = validateEmail(email);
    if (emailError != null) throw ValidationError(emailError);

    final passwordError = validatePassword(password);
    if (passwordError != null) throw ValidationError(passwordError);

    if (age != null) {
      final ageError = validateAgeOptional(age.toString());
      if (ageError != null) throw ValidationError(ageError);
    }

    if (phone != null && phone.isNotEmpty) {
      final phoneError = validatePhoneOptional(phone);
      if (phoneError != null) throw ValidationError(phoneError);
    }

    return ErrorHandler.withRetry(
      () async {
        try {
          _log('Calling Supabase auth.signUp', context: 'signup');
          // Use Supabase Auth for signup
          final authResponse = await _supabase.auth.signUp(
            email: email,
            password: password,
            data: {
              'name': name,
              'role': role,
              'gender': gender,
              'age': age,
              'phone': phone,
            },
          );

          _log('Supabase signup response received', context: 'signup');

          if (authResponse.user != null) {
            _log('Creating user profile in users table', context: 'signup');
            // Create user profile in the users table
            await _supabase.from('users').insert({
              'id': authResponse.user!.id,
              'name': name,
              'email': email,
              'role': role,
              'gender': gender,
              'age': age,
              'phone': phone,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });

            _log('User profile created successfully', context: 'signup');
            return {
              'user': authResponse.user!.toJson(),
              'session': authResponse.session?.toJson(),
              'message': 'Account created successfully. Please check your email to confirm your account.',
            };
          } else {
            _log('Signup failed: No user returned from Supabase', context: 'signup');
            throw ValidationError('Failed to create account. Please try again.');
          }
        } on AuthException catch (e) {
          _log('AuthException during signup', context: 'signup', error: e);
          if (e.message.contains('already registered')) {
            throw ValidationError('An account with this email already exists');
          } else if (e.message.contains('Password should be at least')) {
            throw ValidationError('Password is too weak. Please choose a stronger password.');
          } else if (e.message.contains('Invalid email')) {
            throw ValidationError('Please enter a valid email address');
          } else {
            throw ValidationError('Signup failed: ${e.message}');
          }
        } catch (e) {
          _log('Unexpected error during signup', context: 'signup', error: e);
          throw GenericError('Signup failed: ${e.toString()}');
        }
      },
      config: _defaultRetryConfig,
      context: 'ApiService.signup',
    );
  }

  Future<Map<String, dynamic>> login({
      required String email,
      required String password,
    }) async {
      _log('Starting login process', context: 'login');
      // Input validation
      final emailError = validateEmail(email);
      if (emailError != null) throw ValidationError(emailError);

      final passwordError = validatePassword(password);
      if (passwordError != null) throw ValidationError(passwordError);

      return ErrorHandler.withRetry(
        () async {
          try {
            _log('Calling Supabase auth.signInWithPassword', context: 'login');
            final authResponse = await _supabase.auth.signInWithPassword(
              email: email,
              password: password,
            );

            _log('Supabase login response received', context: 'login');

            if (authResponse.user != null && authResponse.session != null) {
              _log('Fetching user profile from users table', context: 'login');
              // Get user profile from users table
              final userProfile = await _supabase
                  .from('users')
                  .select('*')
                  .eq('id', authResponse.user!.id)
                  .single();

              _log('User profile retrieved successfully', context: 'login');
              return {
                'user': app_user.User.fromJson(userProfile).toJson(),
                'session': authResponse.session!.toJson(),
                'message': 'Login successful',
              };
            } else {
              _log('Login failed: Invalid response from Supabase', context: 'login');
              throw AuthError('Invalid email or password');
            }
          } on AuthException catch (e) {
            _log('AuthException during login', context: 'login', error: e);
            if (e.message.contains('Invalid login credentials')) {
              throw AuthError('Invalid email or password');
            } else if (e.message.contains('Email not confirmed')) {
              throw ValidationError('Please confirm your email before logging in');
            } else {
              throw ValidationError('Login failed: ${e.message}');
            }
          } catch (e) {
            _log('Unexpected error during login', context: 'login', error: e);
            throw GenericError('Login failed: ${e.toString()}');
          }
        },
        config: _defaultRetryConfig,
        context: 'ApiService.login',
      );
    }

  // User methods
   Future<app_user.User> getCurrentUser() async {
     _log('Attempting to get current user', context: 'getCurrentUser');
     return ErrorHandler.withRetry(
       () async {
         final user = _supabase.auth.currentUser;
         if (user == null) {
           _log('No authenticated user found', context: 'getCurrentUser');
           throw AuthError('No authenticated user');
         }

         _log('Fetching user profile for ID: ${user.id}', context: 'getCurrentUser');
         final userProfile = await _supabase
             .from('users')
             .select('*')
             .eq('id', user.id)
             .single();

         _log('User profile retrieved successfully', context: 'getCurrentUser');
         return app_user.User.fromJson(userProfile);
       },
       config: _defaultRetryConfig,
       context: 'ApiService.getCurrentUser',
     );
   }

  Future<String?> uploadAvatar(File imageFile) async {
     return ErrorHandler.withRetry(
       () async {
         final user = _supabase.auth.currentUser;
         if (user == null) {
           throw AuthError('No authenticated user');
         }

         // Upload to Supabase Storage
         final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
         final fileBytes = await imageFile.readAsBytes();

         final response = await _supabase.storage
             .from('avatars')
             .uploadBinary(fileName, fileBytes);

         if (response.isNotEmpty) {
           // Get public URL
           final publicUrl = _supabase.storage
               .from('avatars')
               .getPublicUrl(fileName);

           // Update user profile with avatar URL
           await _supabase
               .from('users')
               .update({'avatar_url': publicUrl})
               .eq('id', user.id);

           return publicUrl;
         } else {
           throw UploadError('Failed to upload avatar');
         }
       },
       config: _defaultRetryConfig,
       context: 'ApiService.uploadAvatar',
     );
   }

  Future<String?> uploadAvatarBytes(
     Uint8List imageBytes,
     String filename,
   ) async {
     return ErrorHandler.withRetry(
       () async {
         final user = _supabase.auth.currentUser;
         if (user == null) {
           throw AuthError('No authenticated user');
         }

         // Upload to Supabase Storage
         final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}_$filename';

         final response = await _supabase.storage
             .from('avatars')
             .uploadBinary(fileName, imageBytes);

         if (response.isNotEmpty) {
           // Get public URL
           final publicUrl = _supabase.storage
               .from('avatars')
               .getPublicUrl(fileName);

           // Update user profile with avatar URL
           await _supabase
               .from('users')
               .update({'avatar_url': publicUrl})
               .eq('id', user.id);

           return publicUrl;
         } else {
           throw UploadError('Failed to upload avatar');
         }
       },
       config: _defaultRetryConfig,
       context: 'ApiService.uploadAvatarBytes',
     );
   }

  Future<app_user.User> updateProfile({
     String? name,
     String? position,
     String? bio,
     String? imageUrl,
     String? gender,
     String? phone,
     int? age,
     String? location,
   }) async {
     // Input validation
     if (name != null) {
       final nameError = validateName(name);
       if (nameError != null) throw ValidationError(nameError);
     }

     if (phone != null && phone.isNotEmpty) {
       final phoneError = validatePhoneOptional(phone);
       if (phoneError != null) throw ValidationError(phoneError);
     }

     if (age != null) {
       final ageError = validateAgeOptional(age.toString());
       if (ageError != null) throw ValidationError(ageError);
     }

     if (location != null && location.isNotEmpty) {
       final locationError = validateLocation(location);
       if (locationError != null) throw ValidationError(locationError);
     }

     return ErrorHandler.withRetry(
       () async {
         final user = _supabase.auth.currentUser;
         if (user == null) {
           throw AuthError('No authenticated user');
         }

         final Map<String, dynamic> updates = {};
         if (name != null) updates['name'] = name;
         if (position != null) updates['position'] = position;
         if (bio != null) updates['bio'] = bio;
         if (imageUrl != null) updates['image_url'] = imageUrl;
         if (gender != null) updates['gender'] = gender;
         if (phone != null) updates['phone'] = phone;
         if (age != null) updates['age'] = age;
         if (location != null) updates['location'] = location;

         final response = await _supabase
             .from('users')
             .update(updates)
             .eq('id', user.id)
             .select()
             .single();

         // Invalidate user stats cache since profile was updated
         await _cacheService.invalidateUserStatsCache();

         return app_user.User.fromJson(response);
       },
       config: _defaultRetryConfig,
       context: 'ApiService.updateProfile',
     );
   }

  Future<app_user.User> getUserById(String userId) async {
     return ErrorHandler.withRetry(
       () async {
         final response = await _supabase
             .from('users')
             .select('*')
             .eq('id', userId)
             .single();

         return app_user.User.fromJson(response);
       },
       config: _defaultRetryConfig,
       context: 'ApiService.getUserById',
     );
   }

  Future<List<app_user.User>> getAllUsers() async {
    return ErrorHandler.withFallback(
      () async {
        final response = await _supabase
            .from('users')
            .select('*')
            .order('created_at');

        return (response as List)
            .map((json) => app_user.User.fromJson(json))
            .toList();
      },
      [], // Return empty list as fallback
      context: 'ApiService.getAllUsers',
    );
  }

  Future<void> deleteUser(String userId) async {
    return ErrorHandler.withErrorHandling(() async {
      await _supabase.from('users').delete().eq('id', userId);
    }, context: 'ApiService.deleteUser');
  }

  // Match methods
  Future<List<Match>> getMatches({int? limit, int? offset}) async {
    return ErrorHandler.withFallback(
      () async {
        var query = _supabase
            .from('matches')
            .select('*')
            .eq('status', 'open')
            .order('match_date');

        if (limit != null) query = query.limit(limit);
        if (offset != null) query = query.range(offset, offset + (limit ?? 20) - 1);

        final response = await query;
        return (response as List).map((json) => Match.fromJson(json)).toList();
      },
      [],
      context: 'ApiService.getMatches',
    );
  }

  Future<List<Match>> getAllMatches({int? limit, int? offset}) async {
     return ErrorHandler.withFallback(
       () async {
         var query = _supabase
             .from('matches')
             .select('*')
             .order('match_date');

         if (limit != null) query = query.limit(limit);
         if (offset != null) query = query.range(offset, offset + (limit ?? 20) - 1);

         final response = await query;
         return (response as List).map((json) => Match.fromJson(json)).toList();
       },
       [],
       context: 'ApiService.getAllMatches',
     );
   }

  Future<Match> getMatch(String matchId) async {
    return ErrorHandler.withRetry(
      () async {
        final response = await _supabase
            .from('matches')
            .select('*')
            .eq('id', matchId)
            .single();

        return Match.fromJson(response);
      },
      config: _defaultRetryConfig,
      context: 'ApiService.getMatch',
    );
  }

  Future<Match> createMatch({
    required String team1Id,
    required String team2Id,
    required DateTime matchDate,
    required String location,
    String? title,
    int? maxPlayers,
    String? matchType,
  }) async {
    // Input validation
    final dateError = validateMatchDateTime(matchDate);
    if (dateError != null) throw ValidationError(dateError);

    final locationError = validateLocation(location);
    if (locationError != null) throw ValidationError(locationError);

    if (title != null && title.isNotEmpty) {
      final titleError = validateMatchTitle(title);
      if (titleError != null) throw ValidationError(titleError);
    }

    if (maxPlayers != null) {
      final playersError = validateMaxPlayers(maxPlayers);
      if (playersError != null) throw ValidationError(playersError);
    }

    return ErrorHandler.withRetry(
      () async {
        final Map<String, dynamic> matchData = {
          'match_date': matchDate.toIso8601String(),
          'location': location,
          'team1_id': team1Id,
          'team2_id': team2Id,
        };

        if (title != null && title.isNotEmpty) {
          matchData['title'] = title;
        }

        if (maxPlayers != null) {
          matchData['max_players'] = maxPlayers;
        }

        if (matchType != null && matchType.isNotEmpty) {
          matchData['match_type'] = matchType;
        }

        final response = await _supabase
            .from('matches')
            .insert(matchData)
            .select()
            .single();

        return Match.fromJson(response);
      },
      config: _defaultRetryConfig,
      context: 'ApiService.createMatch',
    );
  }

  Future<void> closeMatch(String matchId) async {
    return ErrorHandler.withErrorHandling(() async {
      await _supabase
          .from('matches')
          .update({'status': 'closed'})
          .eq('id', matchId);
    }, context: 'ApiService.closeMatch');
  }

  // Team methods
  Future<List<Team>> getUserTeams() async {
    return ErrorHandler.withFallback(
      () async {
        final user = _supabase.auth.currentUser;
        if (user == null) return [];

        final response = await _supabase
            .from('teams')
            .select('*')
            .eq('owner_id', user.id)
            .order('created_at');

        return (response as List).map((json) => Team.fromJson(json)).toList();
      },
      [], // Return empty list as fallback
      context: 'ApiService.getUserTeams',
    );
  }

  Future<List<Team>> getMyTeams() async {
     return ErrorHandler.withFallback(
       () async {
         final user = _supabase.auth.currentUser;
         if (user == null) return [];

         final response = await _supabase
             .from('teams')
             .select('*')
             .eq('owner_id', user.id)
             .order('created_at', ascending: false);

         return (response as List).map((json) => Team.fromJson(json)).toList();
       },
       [], // Return empty list as fallback
       context: 'ApiService.getMyTeams',
     );
   }

  Future<Team> createTeam(
     String name, {
     String? location,
     int? numberOfPlayers,
     String? description,
     String? logo,
     bool? isRecruiting,
     int? minAge,
     int? maxAge,
   }) async {
     // Input validation
     final nameError = validateTeamName(name);
     if (nameError != null) throw ValidationError(nameError);

     if (location != null && location.isNotEmpty) {
       final locationError = validateLocation(location);
       if (locationError != null) throw ValidationError(locationError);
     }

     if (numberOfPlayers != null) {
       final playersError = validateMaxPlayers(numberOfPlayers);
       if (playersError != null) throw ValidationError(playersError);
     }

     return ErrorHandler.withRetry(
       () async {
         final user = _supabase.auth.currentUser;
         if (user == null) {
           throw AuthError('No authenticated user');
         }

         // Call Edge Function for team creation
         final response = await _supabase.functions.invoke('create-team', body: {
           'name': name,
           'location': location,
           'description': description,
           'maxPlayers': numberOfPlayers ?? 11,
           'minAge': minAge ?? 15,
           'maxAge': maxAge ?? 40,
         });

         if (response.status != 201) {
           throw GenericError('Failed to create team: ${response.data}');
         }

         final team = Team.fromJson(response.data);

         // Invalidate teams cache since we created a new team
         await _cacheService.invalidateTeamsCache();

         return team;
       },
       config: _defaultRetryConfig,
       context: 'ApiService.createTeam',
     );
   }

  // Participant methods
  Future<void> joinMatch(String matchId) async {
     return ErrorHandler.withRetry(
       () async {
         final user = _supabase.auth.currentUser;
         if (user == null) {
           throw AuthError('No authenticated user');
         }

         await _supabase
             .from('match_participants')
             .insert({
               'match_id': matchId,
               'user_id': user.id,
               'joined_at': DateTime.now().toIso8601String(),
             });
       },
       config: _defaultRetryConfig,
       context: 'ApiService.joinMatch',
     );
   }

  Future<void> leaveMatch(String matchId) async {
     return ErrorHandler.withRetry(
       () async {
         final user = _supabase.auth.currentUser;
         if (user == null) {
           throw AuthError('No authenticated user');
         }

         await _supabase
             .from('match_participants')
             .delete()
             .eq('match_id', matchId)
             .eq('user_id', user.id);
       },
       config: _defaultRetryConfig,
       context: 'ApiService.leaveMatch',
     );
   }

  Future<List<app_user.User>> getMatchPlayers(String matchId) async {
    return ErrorHandler.withFallback(
      () async {
        final response = await _supabase
            .from('match_players')
            .select('users(*)')
            .eq('match_id', matchId);

        return (response as List)
            .map((json) => app_user.User.fromJson(json['users']))
            .toList();
      },
      [], // Return empty list as fallback
      context: 'ApiService.getMatchPlayers',
    );
  }

  // Notification methods
  Future<List<NotificationModel>> getNotifications() async {
    return ErrorHandler.withFallback(
      () async {
        final response = await _supabase
            .from('notifications')
            .select('*')
            .order('created_at', ascending: false);

        return (response as List)
            .map((json) => NotificationModel.fromJson(json))
            .toList();
      },
      [], // Return empty list as fallback
      context: 'ApiService.getNotifications',
    );
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    return ErrorHandler.withErrorHandling(() async {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    }, context: 'ApiService.markNotificationAsRead');
  }

  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? relatedId,
  }) async {
    return ErrorHandler.withErrorHandling(() async {
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type,
        'related_id': relatedId,
      });
    }, context: 'ApiService.createNotification');
  }

  // Team browsing methods
  Future<List<Team>> getAllTeams({int? limit, int? offset}) async {
    // Skip cache for paginated requests
    if (limit != null || offset != null) {
      return _fetchTeamsFromNetwork(limit: limit, offset: offset);
    }

    // Try to get from cache first
    final cachedTeams = _cacheService.getCachedTeams();
    if (cachedTeams != null && cachedTeams.isNotEmpty) {
      // Background refresh for teams data
      _cacheService.refreshCriticalData(() async {
        final freshTeams = await _fetchTeamsFromNetwork();
        await _cacheService.cacheTeams(freshTeams);
      });
      return cachedTeams;
    }

    // Fetch from network if not cached
    final teams = await _fetchTeamsFromNetwork();
    await _cacheService.cacheTeams(teams);
    return teams;
  }

  Future<List<Team>> _fetchTeamsFromNetwork({int? limit, int? offset}) async {
     return ErrorHandler.withFallback(
       () async {
         var query = _supabase
             .from('teams')
             .select('*')
             .order('created_at', ascending: false);

         if (limit != null) query = query.limit(limit);
         if (offset != null) query = query.range(offset, offset + (limit ?? 20) - 1);

         final response = await query;
         return (response as List).map((json) => Team.fromJson(json)).toList();
       },
       [],
       context: 'ApiService.getAllTeams',
     );
   }

  Future<List<City>> getCities() async {
    // Try to get from cache first
    final cachedCities = _cacheService.getCachedCities();
    if (cachedCities != null && cachedCities.isNotEmpty) {
      // Background refresh for critical data
      _cacheService.refreshCriticalData(() async {
        final freshCities = await _fetchCitiesFromNetwork();
        await _cacheService.cacheCities(freshCities);
      });
      return cachedCities;
    }

    // Fetch from network if not cached
    final cities = await _fetchCitiesFromNetwork();
    await _cacheService.cacheCities(cities);
    return cities;
  }

  Future<List<City>> _fetchCitiesFromNetwork() async {
     try {
       final response = await _supabase
           .from('cities')
           .select('*')
           .order('name');

       return (response as List).map((json) => City.fromJson(json)).toList();
     } catch (e) {
       // Cities table might not exist yet - return empty list
       return [];
     }
   }

  Future<Team> getTeam(String teamId) async {
    return ErrorHandler.withRetry(
      () async {
        final response = await _supabase
            .from('teams')
            .select('*')
            .eq('id', teamId)
            .single();

        return Team.fromJson(response);
      },
      config: _defaultRetryConfig,
      context: 'ApiService.getTeam',
    );
  }

  Future<List<app_user.User>> getTeamMembers(String teamId) async {
    return ErrorHandler.withFallback(
      () async {
        // Get team members directly from team_members table
        final response = await _supabase
            .from('team_members')
            .select('*, users(*)')
            .eq('team_id', teamId);

        return (response as List)
            .map(
              (json) => app_user.User.fromJson({
                ...json['users'],
                'role': json['role'],
              }),
            )
            .toList();
      },
      [], // Return empty list as fallback
      context: 'ApiService.getTeamMembers',
    );
  }

  // Team Join Request methods
  Future<team_models.TeamJoinRequest> createJoinRequest(
     String teamId, {
     String? message,
   }) async {
     return ErrorHandler.withRetry(
       () async {
         final user = _supabase.auth.currentUser;
         if (user == null) {
           throw AuthError('No authenticated user');
         }

         final response = await _supabase
             .from('team_join_requests')
             .insert({
               'team_id': teamId,
               'user_id': user.id,
               'message': message,
               'status': 'pending',
             })
             .select()
             .single();

         return team_models.TeamJoinRequest.fromJson(response);
       },
       config: _defaultRetryConfig,
       context: 'ApiService.createJoinRequest',
     );
   }

  Future<List<team_models.TeamJoinRequest>> getTeamJoinRequests(
     String teamId,
   ) async {
     return ErrorHandler.withFallback(
       () async {
         final response = await _supabase
             .from('team_join_requests')
             .select('*, users(*)')
             .eq('team_id', teamId)
             .eq('status', 'pending')
             .order('created_at');

         return (response as List)
             .map((json) => team_models.TeamJoinRequest.fromJson(json))
             .toList();
       },
       [], // Return empty list as fallback
       context: 'ApiService.getTeamJoinRequests',
     );
   }

  Future<team_models.TeamJoinRequest> updateJoinRequestStatus(
     String teamId,
     String requestId,
     String status,
   ) async {
     return ErrorHandler.withRetry(
       () async {
         final response = await _supabase
             .from('team_join_requests')
             .update({'status': status})
             .eq('id', requestId)
             .eq('team_id', teamId)
             .select()
             .single();

         return team_models.TeamJoinRequest.fromJson(response);
       },
       config: _defaultRetryConfig,
       context: 'ApiService.updateJoinRequestStatus',
     );
   }

  Future<List<team_models.TeamJoinRequest>> getMyJoinRequests() async {
     return ErrorHandler.withFallback(
       () async {
         final user = _supabase.auth.currentUser;
         if (user == null) return [];

         final response = await _supabase
             .from('team_join_requests')
             .select('*, teams(*)')
             .eq('user_id', user.id)
             .order('created_at', ascending: false);

         return (response as List)
             .map((json) => team_models.TeamJoinRequest.fromJson(json))
             .toList();
       },
       [], // Return empty list as fallback
       context: 'ApiService.getMyJoinRequests',
     );
   }

  Future<void> cancelJoinRequest(String teamId, String requestId) async {
     return ErrorHandler.withRetry(
       () async {
         final user = _supabase.auth.currentUser;
         if (user == null) {
           throw AuthError('No authenticated user');
         }

         await _supabase
             .from('team_join_requests')
             .delete()
             .eq('id', requestId)
             .eq('user_id', user.id)
             .eq('team_id', teamId);
       },
       config: _defaultRetryConfig,
       context: 'ApiService.cancelJoinRequest',
     );
   }

  Future<List<Team>> searchTeams(String query) async {
    return ErrorHandler.withFallback(
      () async {
        final response = await _supabase
            .from('teams')
            .select('*')
            .or('name.ilike.%$query%,location.ilike.%$query%')
            .order('created_at', ascending: false);

        return (response as List).map((json) => Team.fromJson(json)).toList();
      },
      [], // Return empty list as fallback
      context: 'ApiService.searchTeams',
    );
  }

  Future<void> toggleTeamRecruiting(String teamId) async {
     return ErrorHandler.withRetry(
       () async {
         final user = _supabase.auth.currentUser;
         if (user == null) {
           throw AuthError('No authenticated user');
         }

         // First get current recruiting status
         final team = await _supabase
             .from('teams')
             .select('is_recruiting')
             .eq('id', teamId)
             .eq('owner_id', user.id)
             .single();

         // Toggle the status
         await _supabase
             .from('teams')
             .update({'is_recruiting': !(team['is_recruiting'] ?? false)})
             .eq('id', teamId)
             .eq('owner_id', user.id);
       },
       config: _defaultRetryConfig,
       context: 'ApiService.toggleTeamRecruiting',
     );
   }

  Future<void> deleteTeam(String teamId, {String? reason}) async {
     await ErrorHandler.withRetry(
       () async {
         final user = _supabase.auth.currentUser;
         if (user == null) {
           throw AuthError('No authenticated user');
         }

         await _supabase
             .from('teams')
             .delete()
             .eq('id', teamId)
             .eq('owner_id', user.id);
       },
       config: _defaultRetryConfig,
       context: 'ApiService.deleteTeam',
     );

     // Invalidate teams cache since we deleted a team
     await _cacheService.invalidateTeamsCache();
   }

  // User statistics methods
  Future<Map<String, dynamic>> getUserStats() async {
    // Try to get from cache first
    final cachedStats = _cacheService.getCachedUserStats();
    if (cachedStats != null) {
      // Background refresh for user stats
      _cacheService.refreshCriticalData(() async {
        final freshStats = await _fetchUserStatsFromNetwork();
        await _cacheService.cacheUserStats(freshStats);
      });
      return cachedStats;
    }

    // Fetch from network if not cached
    final stats = await _fetchUserStatsFromNetwork();
    await _cacheService.cacheUserStats(stats);
    return stats;
  }

  Future<Map<String, dynamic>> _fetchUserStatsFromNetwork() async {
     return ErrorHandler.withFallback(
       () async {
         final user = _supabase.auth.currentUser;
         if (user == null) {
           throw AuthError('No authenticated user');
         }

         // Get matches joined count
         final matchesJoined = await _supabase
             .from('match_participants')
             .select('id')
             .eq('user_id', user.id);

         // Get matches created count (as team owner)
         final matchesCreated = await _supabase
             .from('matches')
             .select('id')
             .or('team1_id.eq.${user.id},team2_id.eq.${user.id}');

         // Get teams owned count
         final teamsOwned = await _supabase
             .from('teams')
             .select('id')
             .eq('owner_id', user.id);

         return {
           'matches_joined': (matchesJoined as List).length,
           'matches_created': (matchesCreated as List).length,
           'teams_owned': (teamsOwned as List).length,
         };
       },
       {
         'matches_joined': 0,
         'matches_created': 0,
         'teams_owned': 0,
       }, // Safe defaults
       context: 'ApiService.getUserStats',
     );
   }

  Future<app_user.User> getUser(String userId) async {
     return ErrorHandler.withRetry(
       () async {
         final response = await _supabase
             .from('users')
             .select('*')
             .eq('id', userId)
             .single();

         return app_user.User.fromJson(response);
       },
       config: _defaultRetryConfig,
       context: 'ApiService.getUser',
     );
   }
}
