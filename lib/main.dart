import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'theme/brand_theme.dart';
import 'features/auth/state/auth_state.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/auth/presentation/screens/auth_landing_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/auth/presentation/screens/phone_login_screen.dart';
import 'features/auth/presentation/screens/otp_screen.dart';
import 'features/auth/presentation/screens/details_screen.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/assist_choice_screen.dart';
import 'features/chat/ai_help_screen.dart';
import 'features/services/service_detail_screen.dart';
import 'features/auth/presentation/screens/language_screen.dart';
import 'features/auth/presentation/screens/gender_screen.dart';
import 'features/store/shop_screen_new.dart';
import 'features/store/cart_screen.dart';
import 'features/store/state/cart_state.dart';
import 'features/profile/edit_profile_screen.dart';
import 'core/odoo/odoo_state.dart';
import 'features/admin/odoo_config_screen.dart';
import 'features/admin/admin_entry_screen.dart';
import 'features/appointments/appointment_booking_screen.dart';
import 'features/services/unified_appointment_booking_screen.dart';
import 'features/services/booking_flow/step1_select_consultant_datetime.dart';
import 'features/services/booking_flow/step2_review_details.dart';
import 'features/services/booking_flow/step3_payment.dart';
import 'features/services/booking_flow/step4_confirmation.dart';
import 'core/models/odoo_models.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyCSS_KuD5VTmvJ_4JM8gHYf6-XMc0b_rTc',
      authDomain: 'house-of-sheelaa.firebaseapp.com',
      projectId: 'house-of-sheelaa',
      storageBucket: 'house-of-sheelaa.firebasestorage.app',
      messagingSenderId: '853952722810',
      appId: '1:853952722810:web:76b40df4ca85105dbc88c3',
      measurementId: 'G-XXMYSYW414',
    ),
  );
  if (kIsWeb) {
    try {
      await FirebaseAnalytics.instance.logEvent(name: 'app_start');
    } catch (_) {}
  }
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthState()),
        ChangeNotifierProvider(create: (_) => CartState()),
        ChangeNotifierProvider(create: (_) => OdooState()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'House of Sheelaa',
        theme: BrandTheme.light,
        darkTheme: BrandTheme.dark,
        themeMode: ThemeMode.dark,
        initialRoute: SplashScreen.route,
        routes: {
          SplashScreen.route: (_) => const SplashScreen(),
          AssistChoiceScreen.route: (_) => const AssistChoiceScreen(),
          AiHelpScreen.route: (_) => const AiHelpScreen(),
          AuthLandingScreen.route: (_) => const AuthLandingScreen(),
          LoginScreen.route: (_) => const LoginScreen(),
          RegisterScreen.route: (_) => const RegisterScreen(),
          PhoneLoginScreen.route: (_) => const PhoneLoginScreen(),
          OtpScreen.route: (_) => const OtpScreen(),
          DetailsScreen.route: (_) => const DetailsScreen(),
          HomeScreen.route: (_) => const HomeScreen(),
          ServiceDetailScreen.route: (_) => const ServiceDetailScreen(),
          EditProfileScreen.route: (_) => const EditProfileScreen(),
          LanguageScreen.route: (_) => const LanguageScreen(),
          GenderScreen.route: (_) => const GenderScreen(),
          ShopScreenNew.route: (_) => const ShopScreenNew(),
          CartScreen.route: (_) => const CartScreen(),
          OdooConfigScreen.route: (_) => const OdooConfigScreen(),
          AdminEntryScreen.route: (_) => const AdminEntryScreen(),
          '/appointment_booking': (_) => const AppointmentBookingScreen(),
          UnifiedAppointmentBookingScreen.route: (context) {
            final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
            return UnifiedAppointmentBookingScreen(
              appointmentTypeId: args?['appointmentTypeId'] as int? ?? 0,
              serviceName: args?['serviceName'] as String? ?? 'Service',
              price: args?['price'] as double?,
              serviceImage: args?['serviceImage'] as String?,
              durationMinutes: args?['durationMinutes'] as int?,
              productId: args?['productId'] as int?,
            );
          },
          // New booking flow routes
          BookingStep1SelectConsultantDatetime.route: (context) {
            final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
            return BookingStep1SelectConsultantDatetime(
              appointmentTypeId: args?['appointmentTypeId'] as int? ?? 0,
              serviceName: args?['serviceName'] as String? ?? 'Service',
              price: args?['price'] as double? ?? 0.0,
              serviceImage: args?['serviceImage'] as String?,
              durationMinutes: args?['durationMinutes'] as int? ?? 30,
              productId: args?['productId'] as int? ?? 0,
            );
          },
          BookingStep2ReviewDetails.route: (context) {
            final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
            final consultant = args?['selectedConsultant'] as OdooStaff?;
            final slot = args?['selectedSlot'] as OdooAppointmentSlot?;
            
            if (consultant == null || slot == null) {
              return const SizedBox(); // Fallback if data missing
            }
            
            return BookingStep2ReviewDetails(
              appointmentTypeId: args?['appointmentTypeId'] as int? ?? 0,
              serviceName: args?['serviceName'] as String? ?? 'Service',
              price: args?['price'] as double? ?? 0.0,
              serviceImage: args?['serviceImage'] as String?,
              durationMinutes: args?['durationMinutes'] as int? ?? 30,
              productId: args?['productId'] as int? ?? 0,
              selectedConsultant: consultant,
              selectedSlot: slot,
            );
          },
          BookingStep3Payment.route: (context) {
            final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
            final consultant = args?['selectedConsultant'] as OdooStaff?;
            final slot = args?['selectedSlot'] as OdooAppointmentSlot?;
            
            if (consultant == null || slot == null) {
              return const SizedBox(); // Fallback if data missing
            }
            
            return BookingStep3Payment(
              appointmentTypeId: args?['appointmentTypeId'] as int? ?? 0,
              serviceName: args?['serviceName'] as String? ?? 'Service',
              price: args?['price'] as double? ?? 0.0,
              serviceImage: args?['serviceImage'] as String?,
              durationMinutes: args?['durationMinutes'] as int? ?? 30,
              productId: args?['productId'] as int? ?? 0,
              selectedConsultant: consultant,
              selectedSlot: slot,
            );
          },
          BookingStep4Confirmation.route: (context) {
            final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
            final consultant = args?['selectedConsultant'] as OdooStaff?;
            final slot = args?['selectedSlot'] as OdooAppointmentSlot?;
            
            if (consultant == null || slot == null) {
              return const SizedBox(); // Fallback if data missing
            }
            
            return BookingStep4Confirmation(
              appointmentTypeId: args?['appointmentTypeId'] as int? ?? 0,
              serviceName: args?['serviceName'] as String? ?? 'Service',
              price: args?['price'] as double? ?? 0.0,
              selectedConsultant: consultant,
              selectedSlot: slot,
              paymentId: args?['paymentId'] as String? ?? '',
              saleOrderId: args?['saleOrderId'] as int?,
            );
          },
        },
      ),
    );
  }
}
