import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/vehicle_list_screen.dart';
import 'screens/booking_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/inspection_upload_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/credit_score_screen.dart';
import 'screens/active_rental_screen.dart';
import 'screens/rental_inspection_screen.dart';
import 'screens/inspection_result_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/review_details_screen.dart';
import 'screens/wishlist_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/booking_detail_screen.dart';
import 'widgets/scaffold_with_nav_bar.dart';
import 'screens/verification_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final GoRouter router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: '/verification',
          builder: (context, state) => const VerificationScreen(),
        ),

        ShellRoute(
          builder: (context, state, child) {
            return ScaffoldWithNavBar(child: child);
          },
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
            GoRoute(
              path: '/vehicles',
              builder: (context, state) => const VehicleListScreen(),
            ),
            GoRoute(
              path: '/active-rental',
              builder: (context, state) => const ActiveRentalScreen(bookingId: 0),
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),

        GoRoute(
          path: '/book/:vehicleId',
          builder: (context, state) {
            final vehicleId = int.parse(state.pathParameters['vehicleId']!);
            return BookingScreen(vehicleId: vehicleId);
          },
        ),
        GoRoute(
          path: '/active-rental/:bookingId',
          builder: (context, state) {
            final bookingId = int.parse(state.pathParameters['bookingId']!);
            return ActiveRentalScreen(bookingId: bookingId);
          },
        ),
        GoRoute(
          path: '/inspection',
          builder: (context, state) => const CameraScreen(),
        ),
        GoRoute(
          path: '/inspection/upload',
          builder: (context, state) {
            final imagePath = state.extra as String;
            return InspectionUploadScreen(imagePath: imagePath);
          },
        ),
        GoRoute(
          path: '/credit-score',
          builder: (context, state) => const CreditScoreScreen(),
        ),

        GoRoute(
          path: '/rental-inspection/:bookingId/:type',
          builder: (context, state) {
            final bookingId = int.parse(state.pathParameters['bookingId']!);
            final type = state.pathParameters['type']!;
            return RentalInspectionScreen(bookingId: bookingId, inspectionType: type);
          },
        ),
        GoRoute(
          path: '/inspection-result/:bookingId',
          builder: (context, state) {
            final bookingId = int.parse(state.pathParameters['bookingId']!);
            final extra = state.extra as Map<String, dynamic>?;
            return InspectionResultScreen(
              bookingId: bookingId,
              result: extra?['result'] ?? {},
              inspectionType: extra?['type'] ?? 'pre',
            );
          },
        ),

        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/wishlist',
          builder: (context, state) => const WishlistScreen(),
        ),
        GoRoute(
          path: '/booking-detail/:bookingId',
          builder: (context, state) {
            final bookingId = int.parse(state.pathParameters['bookingId']!);
            return BookingDetailScreen(bookingId: bookingId);
          },
        ),
        GoRoute(
          path: '/payment/:bookingId',
          builder: (context, state) {
            final bookingId = int.parse(state.pathParameters['bookingId']!);
            return PaymentScreen(bookingId: bookingId);
          },
        ),
        GoRoute(
          path: '/review-details/:bookingId',
          builder: (context, state) {
            final bookingId = int.parse(state.pathParameters['bookingId']!);
            final reviewData = state.extra as Map<String, dynamic>? ?? {};
            return ReviewDetailsScreen(bookingId: bookingId, reviewData: reviewData);
          },
        ),
      ],
      redirect: (context, state) {

        return null;
      },
    );

    return MaterialApp.router(
      title: 'AutoVision Rent',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}

