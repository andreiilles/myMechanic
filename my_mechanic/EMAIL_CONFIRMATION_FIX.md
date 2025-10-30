# Email Confirmation Flow Fix

## Problem
After a user signs up, Supabase automatically sends a confirmation email. However, the app wasn't properly redirecting users back to the login screen with a clear message to confirm their email before signing in. Additionally, there was a navigation stack issue causing the sign-in button to not work properly.

## Solution
The signup flow has been updated to:
1. Detect when email confirmation is required (email not confirmed after signup)
2. Sign out the unconfirmed user
3. Pop the navigation stack back to the root (AuthWrapper)
4. Let AuthWrapper automatically show the LoginScreen
5. Display a success message in a SnackBar telling the user to check their email

## Changes Made

### 1. Updated `lib/main.dart`
- Added imports for `LoginScreen` and `SignUpScreen`
- Added named routes to `MaterialApp` (for future use):
  ```dart
  routes: {
    '/login': (context) => const LoginScreen(),
    '/signup': (context) => const SignUpScreen(),
  }
  ```

### 2. Updated `lib/screens/login_screen.dart`
- No changes needed - kept simple without message parameter
- The LoginScreen is shown by AuthWrapper when user is not authenticated

### 3. Updated `lib/screens/signup_screen.dart`
- Updated the email confirmation redirect logic to properly navigate back:
  ```dart
  // If email is not confirmed, redirect to login with message
  if (authProvider.user?.emailConfirmedAt == null) {
    if (mounted) {
      // Sign out the unconfirmed user
      await authProvider.signOut();
      
      // Pop back to root and let AuthWrapper show LoginScreen
      Navigator.of(context).popUntil((route) => route.isFirst);
      
      // Show success message after a brief delay
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Account created! Please check your email to confirm your account, then sign in.',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 5),
            ),
          );
        }
      });
    }
    return;
  }
  ```

## User Flow

1. **User Signs Up**: User enters email, password, and other required information
2. **Supabase Creates Account**: Supabase creates the auth account and sends confirmation email
3. **App Checks Confirmation**: App checks if `emailConfirmedAt` is null
4. **Sign Out Unconfirmed User**: If email is not confirmed, the user is signed out
5. **Navigate to Root**: Navigation stack is popped back to the root (AuthWrapper)
6. **AuthWrapper Shows Login**: AuthWrapper detects user is not authenticated and shows LoginScreen
7. **Display Message**: Green SnackBar appears at the bottom with the message: "Account created! Please check your email to confirm your account, then sign in."
8. **User Confirms Email**: User clicks the confirmation link in their email
9. **User Signs In**: User returns to the app and signs in with their credentials
10. **Profile Creation**: After successful sign-in with confirmed email, the app creates the user profile and any additional role-specific profiles (mechanic, etc.)

## Why This Approach Works

The key issue was that we were trying to navigate to a LoginScreen on top of the AuthWrapper, which also shows a LoginScreen when the user is not authenticated. This created a double-layer navigation stack that prevented the sign-in button from working properly.

By using `popUntil((route) => route.isFirst)`, we:
1. Remove all navigation layers (including SignUpScreen)
2. Get back to the root widget (AuthWrapper)
3. Let AuthWrapper naturally show the LoginScreen based on authentication state
4. Avoid navigation stack conflicts

The message is shown with a slight delay (300ms) to ensure the navigation has completed and the LoginScreen is visible before showing the SnackBar.

## Testing

To test this flow:
1. Sign up with a new email address
2. Observe that you're redirected back to the login screen (via AuthWrapper)
3. A green message should appear: "Account created! Please check your email to confirm your account, then sign in."
4. Check your email for the confirmation link
5. Click the confirmation link
6. Return to the app and sign in
7. The sign-in button should work properly and the app should complete the profile creation

## Supabase Configuration

Ensure your Supabase project has email confirmation enabled:
1. Go to Authentication > Settings in your Supabase dashboard
2. Under "Email Auth", make sure "Enable email confirmations" is checked
3. Configure your email templates as needed

## Future Improvements

- Add a "Resend confirmation email" button on the login screen
- Add a timer or countdown before allowing resend
- Improve error handling for expired confirmation links
- Add deep linking to automatically open the app after email confirmation
