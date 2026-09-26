# Guide: Setting Up Google Authentication for African Affinity

To enable Google Sign-In in the African Affinity app, you need to create credentials in the Google Cloud Console. Follow these steps carefully.

## Step 1: Create a Google Cloud Project
1. Go to the [Google Cloud Console](https://console.cloud.google.com/).
2. Click the project dropdown in the top left and select **New Project**.
3. Name it `African Affinity` and click **Create**.

## Step 2: Configure the OAuth Consent Screen
Before creating tokens, you must tell Google what users will see when they log in.
1. In the left sidebar, go to **APIs & Services** $\rightarrow$ **OAuth consent screen**.
2. Select **External** and click **Create**.
3. **App Information**:
    - App name: `African Affinity`
    - User support email: Your email.
    - Developer contact info: Your email.
4. Click **Save and Continue** through "Scopes" and "Test Users" (add your own email as a test user for now).
5. Finally, click **Back to Dashboard**.

## Step 3: Create OAuth 2.0 Client IDs
You need a separate client ID for each platform. Go to **APIs & Services** $\rightarrow$ **Credentials** $\rightarrow$ **Create Credentials** $\rightarrow$ **OAuth client ID**.

### A. Android Client ID
1. Application type: **Android**.
2. **Package Name**: `com.example.african_affinity` (as defined in `pubspec.yaml`).
3. **SHA-1 Certificate Fingerprint**:
    - Run this command in your terminal:
      ```bash
      keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
      ```
    - Copy the **SHA1** string (e.g., `AA:BB:CC...`) and paste it into the console.
4. Click **Create**.

### B. iOS Client ID
1. Application type: **iOS**.
2. **Bundle ID**: `com.example.african_affinity`.
3. Click **Create**.

### C. Web Client ID (Required for Backend Verification)
1. Application type: **Web application**.
2. **Authorized JavaScript origins**: `https://afroaffinity.com`
3. Click **Create**.

## Step 4: Pasting Tokens into the App
Once you have the **Web Client ID**, paste it into the app configuration:

1. Open `/Users/apple/Documents/Afro-Afinity/lib/app/config/auth_config.dart`.
2. Locate the `googleClientId` variable:
   ```dart
   static const String googleClientId = 'YOUR_WEB_CLIENT_ID_HERE.apps.googleusercontent.com';
   ```
3. Paste your **Web Client ID** there. 
   *Note: For Flutter's `google_sign_in` package, the Web Client ID is typically used as the primary identifier across platforms when verifying tokens on a backend.*

## Verification
- Run the app on the Android emulator.
- Click "Continue with Google".
- You should be prompted to select a Google account and then successfully logged into the app.
