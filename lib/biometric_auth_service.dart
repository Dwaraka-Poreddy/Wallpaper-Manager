import 'package:local_auth/local_auth.dart';

class BiometricAuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<bool> authenticateUser() async {
    try {
      // Check if device supports biometrics
      bool isSupported = await _localAuth.isDeviceSupported();
      if (!isSupported) return false;

      // Trigger biometric authentication
      bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: "Authenticate to proceed",
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );

      return didAuthenticate;
    } catch (e) {
      // Log error if needed
      print("Authentication error: $e");
      return false;
    }
  }
}
