# Codemagic Environment Variables Setup

This document outlines the environment variables you need to configure in Codemagic for building and publishing the Hindu Connect iOS app.

## Required Environment Variables

### 1. App Store Connect API Key
```
APP_STORE_CONNECT_ISSUER_ID: Your issuer ID from App Store Connect
APP_STORE_CONNECT_KEY_IDENTIFIER: Your key identifier
APP_STORE_CONNECT_PRIVATE_KEY: Your private key (P8 file content)
```

### 2. App Information
```
BUNDLE_ID: com.dikonda.hinduconnect
APP_NAME: Hindu Connect
APP_VERSION: 1.0.2
BUILD_NUMBER: 8
```

### 3. Firebase Configuration
```
FIREBASE_PROJECT_ID: hinduconnectproject
```

### 4. Code Signing (Optional - Codemagic can handle automatically)
```
CERTIFICATE_PRIVATE_KEY: Your certificate private key
APP_STORE_CONNECT_API_KEY_ID: Your API key ID
```

## How to Set Up Environment Variables in Codemagic

1. **Go to Codemagic Dashboard**
   - Navigate to your app settings
   - Click on "Environment variables"

2. **Add Each Variable**
   - Click "Add variable"
   - Enter the variable name
   - Enter the variable value
   - Mark as "Secure" for sensitive data (keys, certificates)

3. **App Store Connect API Key Setup**
   - Go to App Store Connect → Users and Access → Keys
   - Create a new API key with "App Manager" role
   - Download the .p8 file
   - Use the content of the .p8 file as `APP_STORE_CONNECT_PRIVATE_KEY`

4. **Certificate Setup**
   - Codemagic can automatically manage certificates
   - Or upload your own certificate and provisioning profile

## Security Notes

- Mark all sensitive variables as "Secure" in Codemagic
- Never commit API keys or certificates to your repository
- Use Codemagic's built-in certificate management when possible

## Testing the Setup

1. Push your code to the main branch
2. Codemagic will automatically trigger a build
3. Check the build logs for any missing variables
4. The IPA will be uploaded to TestFlight automatically

## Troubleshooting

- **Build fails**: Check that all required variables are set
- **Signing issues**: Verify certificate and provisioning profile
- **Upload fails**: Check App Store Connect API key permissions
- **TestFlight upload fails**: Ensure the app version is unique
