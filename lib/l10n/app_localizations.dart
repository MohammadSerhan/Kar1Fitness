import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Custom app localization. To add a new string:
/// 1. Add a key + English value in [_strings]['en']
/// 2. Add the same key with translations in 'he' and 'ar'
/// 3. Reference via `AppLocalizations.of(context).t('yourKey')` or add a getter
class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// Locales supported by the app.
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('he'),
    Locale('ar'),
  ];

  /// Delegates required by MaterialApp.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  /// Human-readable name shown in the language picker.
  static String displayName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'he':
        return 'עברית';
      case 'ar':
        return 'العربية';
      default:
        return code;
    }
  }

  String t(String key) {
    final langMap = _strings[locale.languageCode] ?? _strings['en']!;
    return langMap[key] ?? _strings['en']![key] ?? key;
  }

  // Common
  String get appName => t('appName');
  String get cancel => t('cancel');
  String get save => t('save');
  String get logout => t('logout');
  String get settings => t('settings');
  String get language => t('language');
  String get loading => t('loading');
  String get error => t('error');
  String get retry => t('retry');

  // Auth
  String get login => t('login');
  String get signup => t('signup');
  String get signUpTitle => t('signUpTitle');
  String get createAccount => t('createAccount');
  String get joinKar1 => t('joinKar1');
  String get welcomeBack => t('welcomeBack');
  String get fullName => t('fullName');
  String get email => t('email');
  String get password => t('password');
  String get confirmPassword => t('confirmPassword');
  String get forgotPassword => t('forgotPassword');
  String get resetPassword => t('resetPassword');
  String get dontHaveAccount => t('dontHaveAccount');
  String get alreadyHaveAccount => t('alreadyHaveAccount');
  String get pleaseEnterName => t('pleaseEnterName');
  String get pleaseEnterEmail => t('pleaseEnterEmail');
  String get invalidEmail => t('invalidEmail');
  String get pleaseEnterPassword => t('pleaseEnterPassword');
  String get passwordTooShort => t('passwordTooShort');
  String get pleaseConfirmPassword => t('pleaseConfirmPassword');
  String get passwordsDoNotMatch => t('passwordsDoNotMatch');
  String get logoutConfirmTitle => t('logoutConfirmTitle');
  String get logoutConfirmMessage => t('logoutConfirmMessage');
  String get noAccountFound => t('noAccountFound');
  String get resetEmailSent => t('resetEmailSent');
  String get resetEmailSentDescription => t('resetEmailSentDescription');
  String get checkInbox => t('checkInbox');
  String get backToLogin => t('backToLogin');
  String get sendResetLink => t('sendResetLink');

  // Home
  String get welcomeBackComma => t('welcomeBackComma');
  String get recommendedFocus => t('recommendedFocus');
  String get basedOnRecentWorkouts => t('basedOnRecentWorkouts');
  String get todaysActivity => t('todaysActivity');
  String get logWorkout => t('logWorkout');
  String get startWorkout => t('startWorkout');
  String get customWorkout => t('customWorkout');
  String get pickYourOwnExercises => t('pickYourOwnExercises');
  String get recommendedPrefix => t('recommendedPrefix');
  String get exercisesCount => t('exercisesCount');
  String get noWorkoutOnThisDay => t('noWorkoutOnThisDay');
  String get workoutCompleted => t('workoutCompleted');
  String get exercisesCompleted => t('exercisesCompleted');
  String get minutesShort => t('minutesShort');

  // Health data
  String get healthData => t('healthData');
  String get connectWearable => t('connectWearable');
  String get grantPermission => t('grantPermission');
  String get activity => t('activity');
  String get steps => t('steps');
  String get calories => t('calories');
  String get distanceKm => t('distanceKm');
  String get activeMin => t('activeMin');
  String get loadingHealthData => t('loadingHealthData');
  String get noHealthData => t('noHealthData');

  // Profile
  String get profile => t('profile');
  String get statistics => t('statistics');
  String get totalWorkouts => t('totalWorkouts');
  String get totalExercises => t('totalExercises');
  String get workoutFrequency => t('workoutFrequency');
  String get noWorkoutData => t('noWorkoutData');
  String get userNotFound => t('userNotFound');

  // Workout recording
  String get recordingWorkout => t('recordingWorkout');
  String get addExercise => t('addExercise');
  String get completeWorkout => t('completeWorkout');
  String get noExercisesAdded => t('noExercisesAdded');
  String get tapToAddExercises => t('tapToAddExercises');
  String get sets => t('sets');
  String get reps => t('reps');
  String get weightKg => t('weightKg');
  String get selectExercise => t('selectExercise');
  String get searchExercises => t('searchExercises');
  String get noExercisesFound => t('noExercisesFound');
  String get fillSetsReps => t('fillSetsReps');
  String get workoutSaved => t('workoutSaved');

  // Exercise detail
  String get targetMuscles => t('targetMuscles');
  String get equipment => t('equipment');
  String get description => t('description');
  String get unableToLoadVideo => t('unableToLoadVideo');

  // About screen
  String get about => t('about');
  String get gymDescription => t('gymDescription');
  String get exerciseLibrary => t('exerciseLibrary');
  String get location => t('location');
  String get phone => t('phone');
  String get hours => t('hours');
  String get hoursValue => t('hoursValue');
  String get locationValue => t('locationValue');
  String get noExercisesYet => t('noExercisesYet');

  // Muscle groups (used both for UI and recommendation engine)
  String get muscleChest => t('muscleChest');
  String get muscleBack => t('muscleBack');
  String get muscleShoulders => t('muscleShoulders');
  String get muscleLegs => t('muscleLegs');
  String get muscleArms => t('muscleArms');
  String get muscleCore => t('muscleCore');
  String get muscleFullBody => t('muscleFullBody');

  /// Translates an English muscle group label (e.g. "Chest") to the current locale.
  String translateMuscleGroup(String englishName) {
    switch (englishName) {
      case 'Chest':
        return muscleChest;
      case 'Back':
        return muscleBack;
      case 'Shoulders':
        return muscleShoulders;
      case 'Legs':
        return muscleLegs;
      case 'Arms':
        return muscleArms;
      case 'Core':
        return muscleCore;
      case 'Full Body':
        return muscleFullBody;
      default:
        return englishName;
    }
  }

  static const Map<String, Map<String, String>> _strings = {
    'en': {
      'appName': 'KAR1 Fitness',
      'cancel': 'Cancel',
      'save': 'Save',
      'logout': 'Logout',
      'settings': 'Settings',
      'language': 'Language',
      'loading': 'Loading...',
      'error': 'Error',
      'retry': 'Retry',

      'login': 'Login',
      'signup': 'Sign Up',
      'signUpTitle': 'Sign Up',
      'createAccount': 'Create Account',
      'joinKar1': 'Join KAR1 Fitness today',
      'welcomeBack': 'Welcome Back',
      'fullName': 'Full Name',
      'email': 'Email',
      'password': 'Password',
      'confirmPassword': 'Confirm Password',
      'forgotPassword': 'Forgot Password?',
      'resetPassword': 'Reset Password',
      'dontHaveAccount': "Don't have an account? ",
      'alreadyHaveAccount': 'Already have an account? ',
      'pleaseEnterName': 'Please enter your name',
      'pleaseEnterEmail': 'Please enter your email',
      'invalidEmail': 'Please enter a valid email',
      'pleaseEnterPassword': 'Please enter a password',
      'passwordTooShort': 'Password must be at least 6 characters',
      'pleaseConfirmPassword': 'Please confirm your password',
      'passwordsDoNotMatch': 'Passwords do not match',
      'logoutConfirmTitle': 'Logout',
      'logoutConfirmMessage': 'Are you sure you want to logout?',
      'noAccountFound': 'No account found with this email address.',
      'resetEmailSent': 'Email Sent!',
      'resetEmailSentDescription': 'We sent a password reset link to',
      'checkInbox': 'Check your inbox and follow the link to reset your password.',
      'backToLogin': 'Back to Login',
      'sendResetLink': 'Send Reset Link',

      'welcomeBackComma': 'Welcome back,',
      'recommendedFocus': 'Recommended Focus',
      'basedOnRecentWorkouts': 'Based on your recent workouts',
      'todaysActivity': "Today's Activity",
      'logWorkout': 'Log Workout',
      'startWorkout': 'Start a Workout',
      'customWorkout': 'Custom Workout',
      'pickYourOwnExercises': 'Pick your own exercises',
      'recommendedPrefix': 'Recommended',
      'exercisesCount': 'exercises based on your history',
      'noWorkoutOnThisDay': 'No workout on this day',
      'workoutCompleted': 'Workout Completed',
      'exercisesCompleted': 'exercises completed',
      'minutesShort': 'min',

      'healthData': 'Health Data',
      'connectWearable':
          'Connect your wearable device to track steps, calories, and more!',
      'grantPermission': 'Grant Permission',
      'activity': 'Activity',
      'steps': 'Steps',
      'calories': 'Calories',
      'distanceKm': 'Distance (km)',
      'activeMin': 'Active Min',
      'loadingHealthData': 'Loading health data...',
      'noHealthData': 'No health data available',

      'profile': 'Profile',
      'statistics': 'Statistics',
      'totalWorkouts': 'Total Workouts',
      'totalExercises': 'Total Exercises',
      'workoutFrequency': 'Workout Frequency (Last 30 Days)',
      'noWorkoutData': 'No workout data yet',
      'userNotFound': 'User not found',

      'recordingWorkout': 'Recording Workout',
      'addExercise': 'Add Exercise',
      'completeWorkout': 'Complete Workout',
      'noExercisesAdded': 'No exercises added yet',
      'tapToAddExercises': 'Tap the button below to add exercises',
      'sets': 'Sets',
      'reps': 'Reps',
      'weightKg': 'Weight (kg)',
      'selectExercise': 'Select Exercise',
      'searchExercises': 'Search exercises...',
      'noExercisesFound': 'No exercises found',
      'fillSetsReps': 'Please fill in sets and reps for all exercises',
      'workoutSaved': 'Workout saved successfully!',

      'targetMuscles': 'Target Muscles',
      'equipment': 'Equipment',
      'description': 'Description',
      'unableToLoadVideo': 'Unable to load video',

      'muscleChest': 'Chest',
      'muscleBack': 'Back',
      'muscleShoulders': 'Shoulders',
      'muscleLegs': 'Legs',
      'muscleArms': 'Arms',
      'muscleCore': 'Core',
      'muscleFullBody': 'Full Body',

      'about': 'About',
      'gymDescription':
          'Your premier fitness destination for achieving your health and wellness goals. We provide state-of-the-art equipment, expert guidance, and a supportive community to help you on your fitness journey.',
      'exerciseLibrary': 'Exercise Library',
      'location': 'Location',
      'phone': 'Phone',
      'hours': 'Hours',
      'hoursValue': 'Sun-Thu: 7AM-10:30PM, Fri-Sat: 8AM-7PM',
      'locationValue': 'Mjd El Kurum',
      'noExercisesYet': 'No exercises available yet',
    },
    'he': {
      'appName': 'KAR1 כושר',
      'cancel': 'ביטול',
      'save': 'שמירה',
      'logout': 'התנתק',
      'settings': 'הגדרות',
      'language': 'שפה',
      'loading': 'טוען...',
      'error': 'שגיאה',
      'retry': 'נסה שוב',

      'login': 'התחברות',
      'signup': 'הרשמה',
      'signUpTitle': 'הרשמה',
      'createAccount': 'יצירת חשבון',
      'joinKar1': 'הצטרף ל-KAR1 כושר היום',
      'welcomeBack': 'ברוך שובך',
      'fullName': 'שם מלא',
      'email': 'דוא"ל',
      'password': 'סיסמה',
      'confirmPassword': 'אימות סיסמה',
      'forgotPassword': 'שכחת סיסמה?',
      'resetPassword': 'איפוס סיסמה',
      'dontHaveAccount': 'אין לך חשבון? ',
      'alreadyHaveAccount': 'כבר יש לך חשבון? ',
      'pleaseEnterName': 'נא להזין שם',
      'pleaseEnterEmail': 'נא להזין דוא"ל',
      'invalidEmail': 'נא להזין דוא"ל תקין',
      'pleaseEnterPassword': 'נא להזין סיסמה',
      'passwordTooShort': 'הסיסמה חייבת להכיל לפחות 6 תווים',
      'pleaseConfirmPassword': 'נא לאמת את הסיסמה',
      'passwordsDoNotMatch': 'הסיסמאות אינן תואמות',
      'logoutConfirmTitle': 'התנתקות',
      'logoutConfirmMessage': 'האם אתה בטוח שברצונך להתנתק?',
      'noAccountFound': 'לא נמצא חשבון עם כתובת דוא"ל זו.',
      'resetEmailSent': 'הדוא"ל נשלח!',
      'resetEmailSentDescription': 'שלחנו קישור לאיפוס סיסמה אל',
      'checkInbox': 'בדוק את תיבת הדואר שלך ולחץ על הקישור לאיפוס הסיסמה.',
      'backToLogin': 'חזרה להתחברות',
      'sendResetLink': 'שלח קישור איפוס',

      'welcomeBackComma': 'ברוך שובך,',
      'recommendedFocus': 'מיקוד מומלץ',
      'basedOnRecentWorkouts': 'בהתבסס על האימונים האחרונים שלך',
      'todaysActivity': 'הפעילות של היום',
      'logWorkout': 'רישום אימון',
      'startWorkout': 'התחל אימון',
      'customWorkout': 'אימון מותאם אישית',
      'pickYourOwnExercises': 'בחר את התרגילים שלך',
      'recommendedPrefix': 'מומלץ',
      'exercisesCount': 'תרגילים בהתבסס על ההיסטוריה שלך',
      'noWorkoutOnThisDay': 'אין אימון ביום זה',
      'workoutCompleted': 'האימון הושלם',
      'exercisesCompleted': 'תרגילים הושלמו',
      'minutesShort': 'דק\'',

      'healthData': 'נתוני בריאות',
      'connectWearable':
          'חבר את המכשיר הלביש שלך כדי לעקוב אחר צעדים, קלוריות ועוד!',
      'grantPermission': 'אישור הרשאה',
      'activity': 'פעילות',
      'steps': 'צעדים',
      'calories': 'קלוריות',
      'distanceKm': 'מרחק (ק"מ)',
      'activeMin': 'דק\' פעילות',
      'loadingHealthData': 'טוען נתוני בריאות...',
      'noHealthData': 'אין נתוני בריאות זמינים',

      'profile': 'פרופיל',
      'statistics': 'סטטיסטיקה',
      'totalWorkouts': 'סה"כ אימונים',
      'totalExercises': 'סה"כ תרגילים',
      'workoutFrequency': 'תדירות אימונים (30 ימים אחרונים)',
      'noWorkoutData': 'עדיין אין נתוני אימון',
      'userNotFound': 'משתמש לא נמצא',

      'recordingWorkout': 'מקליט אימון',
      'addExercise': 'הוסף תרגיל',
      'completeWorkout': 'סיים אימון',
      'noExercisesAdded': 'עדיין לא נוספו תרגילים',
      'tapToAddExercises': 'לחץ על הכפתור מטה להוספת תרגילים',
      'sets': 'סטים',
      'reps': 'חזרות',
      'weightKg': 'משקל (ק"ג)',
      'selectExercise': 'בחר תרגיל',
      'searchExercises': 'חיפוש תרגילים...',
      'noExercisesFound': 'לא נמצאו תרגילים',
      'fillSetsReps': 'נא למלא סטים וחזרות עבור כל התרגילים',
      'workoutSaved': 'האימון נשמר בהצלחה!',

      'targetMuscles': 'שרירי מטרה',
      'equipment': 'ציוד',
      'description': 'תיאור',
      'unableToLoadVideo': 'לא ניתן לטעון את הסרטון',

      'muscleChest': 'חזה',
      'muscleBack': 'גב',
      'muscleShoulders': 'כתפיים',
      'muscleLegs': 'רגליים',
      'muscleArms': 'ידיים',
      'muscleCore': 'בטן',
      'muscleFullBody': 'כל הגוף',

      'about': 'אודות',
      'gymDescription':
          'היעד המוביל שלך לכושר להשגת יעדי הבריאות והרווחה שלך. אנו מספקים ציוד מתקדם, הדרכה מקצועית וקהילה תומכת שתעזור לך במסע הכושר שלך.',
      'exerciseLibrary': 'ספריית תרגילים',
      'location': 'מיקום',
      'phone': 'טלפון',
      'hours': 'שעות פתיחה',
      'hoursValue': 'א\'-ה\': 07:00-22:30, ו\'-ש\': 08:00-19:00',
      'locationValue': 'מג\'ד אל כרום',
      'noExercisesYet': 'עדיין אין תרגילים זמינים',
    },
    'ar': {
      'appName': 'KAR1 للياقة',
      'cancel': 'إلغاء',
      'save': 'حفظ',
      'logout': 'تسجيل الخروج',
      'settings': 'الإعدادات',
      'language': 'اللغة',
      'loading': 'جاري التحميل...',
      'error': 'خطأ',
      'retry': 'إعادة المحاولة',

      'login': 'تسجيل الدخول',
      'signup': 'إنشاء حساب',
      'signUpTitle': 'إنشاء حساب',
      'createAccount': 'إنشاء حساب',
      'joinKar1': 'انضم إلى KAR1 للياقة اليوم',
      'welcomeBack': 'مرحباً بعودتك',
      'fullName': 'الاسم الكامل',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'confirmPassword': 'تأكيد كلمة المرور',
      'forgotPassword': 'هل نسيت كلمة المرور؟',
      'resetPassword': 'إعادة تعيين كلمة المرور',
      'dontHaveAccount': 'ليس لديك حساب؟ ',
      'alreadyHaveAccount': 'لديك حساب بالفعل؟ ',
      'pleaseEnterName': 'يرجى إدخال اسمك',
      'pleaseEnterEmail': 'يرجى إدخال البريد الإلكتروني',
      'invalidEmail': 'يرجى إدخال بريد إلكتروني صحيح',
      'pleaseEnterPassword': 'يرجى إدخال كلمة المرور',
      'passwordTooShort': 'يجب أن تحتوي كلمة المرور على 6 أحرف على الأقل',
      'pleaseConfirmPassword': 'يرجى تأكيد كلمة المرور',
      'passwordsDoNotMatch': 'كلمات المرور غير متطابقة',
      'logoutConfirmTitle': 'تسجيل الخروج',
      'logoutConfirmMessage': 'هل أنت متأكد من تسجيل الخروج؟',
      'noAccountFound': 'لم يتم العثور على حساب بهذا البريد الإلكتروني.',
      'resetEmailSent': 'تم إرسال البريد!',
      'resetEmailSentDescription': 'أرسلنا رابط إعادة تعيين كلمة المرور إلى',
      'checkInbox': 'تحقق من بريدك الوارد واتبع الرابط لإعادة تعيين كلمة المرور.',
      'backToLogin': 'العودة لتسجيل الدخول',
      'sendResetLink': 'إرسال رابط الإعادة',

      'welcomeBackComma': 'مرحباً بعودتك،',
      'recommendedFocus': 'التركيز الموصى به',
      'basedOnRecentWorkouts': 'بناءً على تمارينك الأخيرة',
      'todaysActivity': 'نشاط اليوم',
      'logWorkout': 'تسجيل تمرين',
      'startWorkout': 'ابدأ تمريناً',
      'customWorkout': 'تمرين مخصص',
      'pickYourOwnExercises': 'اختر تمارينك الخاصة',
      'recommendedPrefix': 'موصى به',
      'exercisesCount': 'تمارين بناءً على سجلك',
      'noWorkoutOnThisDay': 'لا يوجد تمرين في هذا اليوم',
      'workoutCompleted': 'اكتمل التمرين',
      'exercisesCompleted': 'تمارين مكتملة',
      'minutesShort': 'دقيقة',

      'healthData': 'البيانات الصحية',
      'connectWearable':
          'وصّل جهازك القابل للارتداء لتتبع الخطوات والسعرات الحرارية والمزيد!',
      'grantPermission': 'منح الإذن',
      'activity': 'النشاط',
      'steps': 'الخطوات',
      'calories': 'السعرات',
      'distanceKm': 'المسافة (كم)',
      'activeMin': 'دقائق النشاط',
      'loadingHealthData': 'جاري تحميل البيانات الصحية...',
      'noHealthData': 'لا توجد بيانات صحية متاحة',

      'profile': 'الملف الشخصي',
      'statistics': 'الإحصائيات',
      'totalWorkouts': 'إجمالي التمارين',
      'totalExercises': 'إجمالي التدريبات',
      'workoutFrequency': 'تكرار التمرين (آخر 30 يوماً)',
      'noWorkoutData': 'لا توجد بيانات تمرين بعد',
      'userNotFound': 'المستخدم غير موجود',

      'recordingWorkout': 'تسجيل التمرين',
      'addExercise': 'إضافة تمرين',
      'completeWorkout': 'إنهاء التمرين',
      'noExercisesAdded': 'لم تتم إضافة تمارين بعد',
      'tapToAddExercises': 'اضغط على الزر أدناه لإضافة تمارين',
      'sets': 'مجموعات',
      'reps': 'تكرارات',
      'weightKg': 'الوزن (كجم)',
      'selectExercise': 'اختر تمريناً',
      'searchExercises': 'البحث عن تمارين...',
      'noExercisesFound': 'لم يتم العثور على تمارين',
      'fillSetsReps': 'يرجى ملء المجموعات والتكرارات لجميع التمارين',
      'workoutSaved': 'تم حفظ التمرين بنجاح!',

      'targetMuscles': 'العضلات المستهدفة',
      'equipment': 'المعدات',
      'description': 'الوصف',
      'unableToLoadVideo': 'تعذر تحميل الفيديو',

      'muscleChest': 'الصدر',
      'muscleBack': 'الظهر',
      'muscleShoulders': 'الأكتاف',
      'muscleLegs': 'الساقين',
      'muscleArms': 'الذراعين',
      'muscleCore': 'البطن',
      'muscleFullBody': 'الجسم كامل',

      'about': 'حول',
      'gymDescription':
          'وجهتك الأولى للياقة البدنية لتحقيق أهداف الصحة والعافية. نحن نوفر معدات حديثة وإرشادات من خبراء ومجتمعاً داعماً لمساعدتك في رحلتك نحو اللياقة.',
      'exerciseLibrary': 'مكتبة التمارين',
      'location': 'الموقع',
      'phone': 'الهاتف',
      'hours': 'ساعات العمل',
      'hoursValue': 'الأحد-الخميس: 7ص-10:30م، الجمعة-السبت: 8ص-7م',
      'locationValue': 'مجد الكروم',
      'noExercisesYet': 'لا تتوفر تمارين حتى الآن',
    },
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales
        .any((l) => l.languageCode == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
