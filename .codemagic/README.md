# Hindu Connect - Codemagic CI/CD Setup

This repository is configured for automated iOS builds and App Store distribution using Codemagic.

## 🚀 Quick Start

1. **Connect Repository to Codemagic**
   - Go to [Codemagic Dashboard](https://codemagic.io)
   - Click "Add application"
   - Connect your GitHub repository
   - Select the `hindu-app-main` repository

2. **Configure Environment Variables**
   - Go to app settings → Environment variables
   - Add the variables listed in `env_vars.md`
   - Mark sensitive variables as "Secure"

3. **Set Up App Store Connect**
   - Create an API key in App Store Connect
   - Configure the API key in Codemagic
   - Set up automatic code signing

4. **Trigger Build**
   - Push to `main` branch or create a release tag
   - Codemagic will automatically build and upload to TestFlight

## 📁 Files Overview

- `codemagic.yaml` - Main Codemagic configuration
- `ios/export_options.plist` - iOS export configuration
- `.codemagic/scripts/build_ios.sh` - Custom build script
- `.codemagic/env_vars.md` - Environment variables documentation

## 🔧 Configuration Details

### Build Configuration
- **Platform**: iOS
- **Flutter Version**: Stable
- **Xcode Version**: Latest
- **Instance Type**: Mac Mini M1

### Build Process
1. Set up code signing
2. Install Flutter dependencies
3. Install iOS pods
4. Run Flutter analyze
5. Run Flutter tests
6. Build IPA for App Store
7. Upload to TestFlight

### Publishing
- **TestFlight**: Automatic upload
- **App Store**: Manual submission (set `submit_to_app_store: true` to enable)
- **Email Notifications**: Enabled
- **Slack Notifications**: Configured

## 🎯 Build Triggers

### Automatic Triggers
- **Push to main branch**: Builds and uploads to TestFlight
- **Release tags**: Builds and uploads to TestFlight
- **Pull requests**: Builds for testing (optional)

### Manual Triggers
- Use Codemagic dashboard to trigger builds manually
- Useful for testing different configurations

## 📱 App Information

- **Bundle ID**: `com.dikonda.hinduconnect`
- **App Name**: Hindu Connect
- **Current Version**: 1.0.2
- **Build Number**: 8

## 🔐 Security

- All sensitive data is encrypted in Codemagic
- API keys and certificates are stored securely
- No sensitive data is committed to the repository

## 🐛 Troubleshooting

### Common Issues

1. **Build Fails**
   - Check environment variables are set correctly
   - Verify Flutter dependencies
   - Check iOS pod installation

2. **Code Signing Issues**
   - Ensure certificates are valid
   - Check provisioning profiles
   - Verify bundle ID matches

3. **Upload Fails**
   - Check App Store Connect API key permissions
   - Verify app version is unique
   - Ensure app is configured in App Store Connect

### Getting Help

- Check Codemagic build logs for detailed error messages
- Refer to [Codemagic Documentation](https://docs.codemagic.io)
- Contact Codemagic support for platform-specific issues

## 📈 Monitoring

- Build status is available in Codemagic dashboard
- Email notifications for build results
- Slack notifications for team updates
- TestFlight provides distribution analytics

## 🔄 Updates

To update the build configuration:
1. Modify `codemagic.yaml`
2. Update environment variables if needed
3. Test with a manual build
4. Push changes to trigger automatic builds

## 📋 Checklist

Before your first build:
- [ ] Repository connected to Codemagic
- [ ] Environment variables configured
- [ ] App Store Connect API key set up
- [ ] Code signing configured
- [ ] App configured in App Store Connect
- [ ] Test build completed successfully
