// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get welcome => 'مرحباً';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get signup => 'إنشاء حساب';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get home => 'الرئيسية';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get admin => 'المدير';

  @override
  String welcomeUser(Object email) {
    return 'مرحباً $email';
  }

  @override
  String get loading => 'جارٍ التحميل...';

  @override
  String get language => 'اللغة';

  @override
  String get theme => 'المظهر';

  @override
  String get light => 'فاتح';

  @override
  String get dark => 'داكن';

  @override
  String get system => 'النظام';

  @override
  String get english => 'الإنجليزية';

  @override
  String get french => 'الفرنسية';

  @override
  String get arabic => 'العربية';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get goToLogin => 'الذهاب إلى تسجيل الدخول';

  @override
  String get goToSignup => 'الذهاب إلى إنشاء الحساب';

  @override
  String get goToProfile => 'الذهاب إلى الملف الشخصي';

  @override
  String get goToAdmin => 'الذهاب إلى المدير';

  @override
  String get adminOnly => 'وصول المدير فقط';
}
