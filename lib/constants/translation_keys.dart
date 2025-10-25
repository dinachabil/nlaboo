/// Translation keys constants to prevent typos and ensure consistency across the codebase.
/// This file contains all translation keys organized by category for type-safe access.
class TranslationKeys {
  TranslationKeys._(); // Prevent instantiation

  // ===========================================================================
  // GENERAL UI KEYS
  // ===========================================================================

  /// General UI elements and common actions
  static const String appTitle = 'app_title';
  static const String welcome = 'welcome';
  static const String ok = 'ok';
  static const String cancel = 'cancel';
  static const String error = 'error';
  static const String loading = 'loading';
  static const String retry = 'retry';
  static const String save = 'save';
  static const String delete = 'delete';
  static const String home = 'home';
  static const String settings = 'settings';
  static const String appName = 'app_name';

  // ===========================================================================
  // AUTHENTICATION KEYS
  // ===========================================================================

  /// Authentication related keys
  static const String signIn = 'sign_in';
  static const String signUp = 'sign_up';
  static const String login = 'login';
  static const String logout = 'logout';
  static const String logoutConfirm = 'logout_confirm';
  static const String loginSuccess = 'login_success';
  static const String loginFailed = 'login_failed';
  static const String loginTitle = 'login_title';
  static const String loginSubtitle = 'login_subtitle';
  static const String loginButton = 'login_button';
  static const String signupButton = 'signup_button';
  static const String dontHaveAccount = 'dont_have_account';
  static const String enterEmail = 'enter_email';
  static const String enterPassword = 'enter_password';
  static const String invalidCredentials = 'invalid_credentials';
  static const String emailNotConfirmed = 'email_not_confirmed';
  static const String signupFailed = 'signup_failed';
  static const String accountCreatedWelcome = 'account_created_welcome';
  static const String accountCreatedCheckEmail = 'account_created_check_email';
  static const String forgotPassword = 'forgot_password';

  // ===========================================================================
  // VALIDATION KEYS
  // ===========================================================================

  /// Form validation messages
  static const String emailRequired = 'email_required';
  static const String invalidEmail = 'invalid_email';
  static const String passwordRequired = 'password_required';
  static const String passwordTooShort8 = 'password_too_short_8';
  static const String passwordsNotMatch = 'passwords_not_match';
  static const String nameRequired = 'name_required';
  static const String nameTooShort = 'name_too_short';
  static const String nameMustContainLetter = 'name_must_contain_letter';
  static const String nameInvalidPlaceholder = 'name_invalid_placeholder';
  static const String phoneInvalid = 'phone_invalid';
  static const String phoneRequired = 'phone_required';
  static const String phoneInvalidMoroccan = 'phone_invalid_moroccan';
  static const String phoneReqDigits = 'phone_req_digits';
  static const String ageRequired = 'age_required';
  static const String ageInvalid = 'age_invalid';
  static const String locationRequired = 'location_required';
  static const String genderRequired = 'gender_required';
  static const String matchTitleRequired = 'match_title_required';
  static const String matchTitleTooShort = 'match_title_too_short';
  static const String maxPlayersRequired = 'max_players_required';
  static const String teamNameRequired = 'team_name_required';
  static const String teamNameTooShort = 'team_name_too_short';
  static const String matchDateTimeFuture = 'match_date_time_future';

  // ===========================================================================
  // PASSWORD REQUIREMENTS KEYS
  // ===========================================================================

  /// Password strength and requirements
  static const String emailAlreadyInUse = 'email_already_in_use';
  static const String passwordReqLength = 'password_req_length';
  static const String passwordReqUppercase = 'password_req_uppercase';
  static const String passwordReqLowercase = 'password_req_lowercase';
  static const String passwordReqDigit = 'password_req_digit';
  static const String passwordTooWeak = 'password_too_weak';
  static const String passwordRequirements = 'password_requirements';
  static const String passwordStrengthWeak = 'password_strength_weak';
  static const String passwordStrengthStrong = 'password_strength_strong';
  static const String phoneRequirements = 'phone_requirements';

  // ===========================================================================
  // FORM FIELD LABELS
  // ===========================================================================

  /// Form field labels and placeholders
  static const String fullName = 'full_name';
  static const String email = 'email';
  static const String age = 'age';
  static const String phone = 'phone';
  static const String password = 'password';
  static const String confirmPassword = 'confirm_password';
  static const String bio = 'bio';
  static const String bioHint = 'bio_hint';
  static const String selectGender = 'select_gender';
  static const String gender = 'gender';
  static const String male = 'male';
  static const String female = 'female';

  // ===========================================================================
  // ERROR KEYS
  // ===========================================================================

  /// Error messages and recovery suggestions
  static const String errorGeneric = 'error_generic';
  static const String errorNetwork = 'error_network';
  static const String errorUnauthorized = 'error_unauthorized';
  static const String errorInvalidInput = 'error_invalid_input';
  static const String errorUploadFailed = 'error_upload_failed';
  static const String errorDatabase = 'error_database';
  static const String errorRecoveryNetwork = 'error_recovery_network';
  static const String errorRecoveryAuth = 'error_recovery_auth';
  static const String errorRecoveryValidation = 'error_recovery_validation';
  static const String errorRecoveryUpload = 'error_recovery_upload';

  // ===========================================================================
  // SETTINGS AND PREFERENCES
  // ===========================================================================

  /// Settings and user preferences
  static const String language = 'language';
  static const String english = 'english';
  static const String french = 'french';
  static const String arabic = 'arabic';
  static const String theme = 'theme';
  static const String account = 'account';
  static const String systemMode = 'system_mode';
  static const String lightMode = 'light_mode';
  static const String darkMode = 'dark_mode';

  // ===========================================================================
  // PROFILE AND ACCOUNT MANAGEMENT
  // ===========================================================================

  /// Profile and account related keys
  static const String accountInfo = 'account_info';
  static const String userStats = 'user_stats';
  static const String matchesJoined = 'matches_joined';
  static const String matchesCreated = 'matches_created';
  static const String teamsOwned = 'teams_owned';
  static const String myTeams = 'my_teams';
  static const String viewAllTeams = 'view_all_teams';
  static const String noTeamsYet = 'no_teams_yet';
  static const String editProfile = 'edit_profile';
  static const String backToProfile = 'back_to_profile';
  static const String pictureDeleted = 'picture_deleted';
  static const String confirmSave = 'confirm_save';
  static const String confirmSaveMessage = 'confirm_save_message';
  static const String profileUpdated = 'profile_updated';

  // ===========================================================================
  // MATCH MANAGEMENT
  // ===========================================================================

  /// Match creation and management
  static const String createNewMatch = 'create_new_match';
  static const String setUpNewMatch = 'set_up_new_match';
  static const String matchTitle = 'match_title';
  static const String location = 'location';
  static const String maxPlayers = 'max_players';
  static const String players = 'players';
  static const String matchType = 'match_type';
  static const String mixed = 'mixed';
  static const String matchDate = 'match_date';
  static const String matchTime = 'match_time';
  static const String createMatch = 'create_match';
  static const String matchCreatedSuccessfully = 'match_created_successfully';
  static const String matchDetails = 'match_details';
  static const String matchNotFound = 'match_not_found';
  static const String matches = 'matches';
  static const String featuredMatches = 'featured_matches';
  static const String noFeaturedMatchesAvailable = 'no_featured_matches_available';
  static const String viewAll = 'view_all';

  // ===========================================================================
  // MATCH STATUS AND ACTIONS
  // ===========================================================================

  /// Match status and player actions
  static const String open = 'open';
  static const String closed = 'closed';
  static const String pending = 'pending';
  static const String confirmed = 'confirmed';
  static const String finished = 'finished';
  static const String cancelled = 'cancelled';
  static const String joined = 'joined';
  static const String owner = 'owner';
  static const String created = 'created';
  static const String members = 'members';
  static const String pleaseLoginToJoin = 'please_login_to_join';
  static const String joinedMatch = 'joined_match';
  static const String leftMatch = 'left_match';

  // ===========================================================================
  // TEAM MANAGEMENT
  // ===========================================================================

  /// Team creation and management
  static const String createTeam = 'create_team';
  static const String teamCreated = 'team_created';
  static const String teamName = 'team_name';
  static const String teamLogo = 'team_logo';
  static const String recruiting = 'recruiting';
  static const String allowJoinRequests = 'allow_join_requests';
  static const String teamManagement = 'team_management';
  static const String recruitingEnabled = 'recruiting_enabled';
  static const String recruitingDisabled = 'recruiting_disabled';
  static const String teamDetails = 'team_details';
  static const String teamNotFound = 'team_not_found';
  static const String teamMembers = 'team_members';
  static const String noMembers = 'no_members';
  static const String teams = 'teams';
  static const String featuredTeams = 'featured_teams';
  static const String noFeaturedTeamsAvailable = 'no_featured_teams_available';

  // ===========================================================================
  // TEAM ACTIONS AND REQUESTS
  // ===========================================================================

  /// Team joining and management actions
  static const String joinTeam = 'join_team';
  static const String joinRequestMessageHint = 'join_request_message_hint';
  static const String optionalMessage = 'optional_message';
  static const String sendRequest = 'send_request';
  static const String joinRequestSent = 'join_request_sent';
  static const String viewDetails = 'view_details';
  static const String manageTeam = 'manage_team';
  static const String requestToJoin = 'request_to_join';
  static const String noTeamsFoundInCity = 'no_teams_found_in_city';
  static const String joinRequests = 'join_requests';
  static const String requested = 'requested';
  static const String joinTeamRequestMessage = 'join_team_request_message';
  static const String joinRequestCancelled = 'join_request_cancelled';
  static const String alreadyMember = 'already_member';
  static const String teamOwner = 'team_owner';
  static const String requestApproved = 'request_approved';
  static const String requestRejected = 'request_rejected';
  static const String leaveTeam = 'leave_team';
  static const String leaveTeamConfirmation = 'leave_team_confirmation';
  static const String leftTeamSuccessfully = 'left_team_successfully';

  // ===========================================================================
  // TEAM DELETION
  // ===========================================================================

  /// Team deletion related keys
  static const String deleteTeam = 'delete_team';
  static const String deleteTeamConfirmation = 'delete_team_confirmation';
  static const String reasonOptional = 'reason_optional';
  static const String teamDeletedSuccessfully = 'team_deleted_successfully';

  // ===========================================================================
  // LOADING AND ERROR STATES
  // ===========================================================================

  /// Loading and error states for data fetching
  static const String failedToLoad = 'failed_to_load';
  static const String failedToLoadData = 'failed_to_load_data';
  static const String failedToLoadTeams = 'failed_to_load_teams';
  static const String failedToLoadMatch = 'failed_to_load_match';
  static const String failedToLoadPlayers = 'failed_to_load_players';

  // ===========================================================================
  // NOTIFICATIONS
  // ===========================================================================

  /// Notification related keys
  static const String notifications = 'notifications';

  // ===========================================================================
  // WELCOME AND LANDING PAGE
  // ===========================================================================

  /// Welcome and landing page content
  static const String welcomeToFootconnect = 'welcome_to_footconnect';
  static const String footballCommunity = 'football_community';
  static const String joinTheGame = 'join_the_game';
  static const String connectFootballCommunity = 'connect_football_community';
}