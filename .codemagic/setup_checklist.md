# Codemagic Setup Checklist

Use this checklist to ensure your Hindu Connect iOS app is properly configured for Codemagic CI/CD.

## ✅ Pre-Setup Requirements

- [ ] Apple Developer Account (paid)
- [ ] App Store Connect access
- [ ] GitHub repository with your code
- [ ] Codemagic account (free tier available)

## 🔧 Codemagic Configuration

### 1. Repository Setup
- [ ] Connect GitHub repository to Codemagic
- [ ] Select the `hindu-app-main` repository
- [ ] Verify `codemagic.yaml` is detected

### 2. Environment Variables
- [ ] `APP_STORE_CONNECT_ISSUER_ID` - Your issuer ID
- [ ] `APP_STORE_CONNECT_KEY_IDENTIFIER` - Your key ID
- [ ] `APP_STORE_CONNECT_PRIVATE_KEY` - Your private key content
- [ ] `BUNDLE_ID` - `com.dikonda.hinduconnect`
- [ ] `APP_NAME` - `Hindu Connect`
- [ ] `APP_VERSION` - `1.0.2`
- [ ] `BUILD_NUMBER` - `8`
- [ ] `FIREBASE_PROJECT_ID` - `hinduconnectproject`

### 3. Code Signing
- [ ] Enable automatic code signing in Codemagic
- [ ] Or upload your own certificates
- [ ] Verify bundle ID matches

## 🍎 App Store Connect Setup

### 1. App Creation
- [ ] Create app in App Store Connect
- [ ] Bundle ID: `com.dikonda.hinduconnect`
- [ ] App Name: `Hindu Connect`
- [ ] SKU: `hinduconnect-ios`

### 2. API Key
- [ ] Create App Store Connect API key
- [ ] Download .p8 file
- [ ] Note Key ID and Issuer ID
- [ ] Add to Codemagic environment variables

### 3. App Information
- [ ] Complete app description
- [ ] Add keywords
- [ ] Upload screenshots
- [ ] Upload app icon (1024x1024)
- [ ] Complete age rating
- [ ] Add privacy policy URL
- [ ] Add terms of service URL

## 🚀 Build Configuration

### 1. Codemagic Settings
- [ ] Platform: iOS
- [ ] Flutter version: Stable
- [ ] Xcode version: Latest
- [ ] Instance type: Mac Mini M1

### 2. Build Triggers
- [ ] Push to main branch
- [ ] Release tags
- [ ] Pull requests (optional)

### 3. Publishing
- [ ] TestFlight upload enabled
- [ ] Email notifications configured
- [ ] Slack notifications (optional)

## 🧪 Testing

### 1. First Build
- [ ] Push code to main branch
- [ ] Monitor Codemagic build logs
- [ ] Check for any errors
- [ ] Verify IPA is created

### 2. TestFlight
- [ ] Check TestFlight upload
- [ ] Verify app appears in TestFlight
- [ ] Test on physical device
- [ ] Check all features work

### 3. App Store
- [ ] Submit for App Store review
- [ ] Wait for approval
- [ ] Release to public

## 🔍 Troubleshooting

### Common Issues
- [ ] Environment variables not set
- [ ] Code signing problems
- [ ] API key permissions
- [ ] Bundle ID mismatch
- [ ] Version conflicts

### Solutions
- [ ] Check Codemagic build logs
- [ ] Verify environment variables
- [ ] Test with manual build
- [ ] Contact Codemagic support

## 📊 Monitoring

### Build Monitoring
- [ ] Set up build notifications
- [ ] Monitor build success rate
- [ ] Track build duration
- [ ] Check for build failures

### App Monitoring
- [ ] Set up App Store Connect analytics
- [ ] Monitor download metrics
- [ ] Track user engagement
- [ ] Monitor crash reports

## 🔄 Maintenance

### Regular Updates
- [ ] Update Flutter version
- [ ] Update dependencies
- [ ] Test new iOS versions
- [ ] Update Codemagic configuration

### Version Management
- [ ] Increment version numbers
- [ ] Update build numbers
- [ ] Test before release
- [ ] Document changes

## 📋 Final Checklist

Before going live:
- [ ] All tests passing
- [ ] App tested on multiple devices
- [ ] App Store listing complete
- [ ] Privacy policy accessible
- [ ] Terms of service accessible
- [ ] App icon and screenshots uploaded
- [ ] Age rating completed
- [ ] App Store review submitted
- [ ] Approval received
- [ ] App released to public

## 🆘 Support

If you encounter issues:
1. Check Codemagic documentation
2. Review build logs
3. Test with manual build
4. Contact Codemagic support
5. Check Apple Developer forums

## 📞 Contact Information

- **Codemagic Support**: [support@codemagic.io](mailto:support@codemagic.io)
- **Apple Developer Support**: [developer.apple.com/support](https://developer.apple.com/support)
- **Flutter Documentation**: [flutter.dev](https://flutter.dev)

---

**Note**: This checklist should be completed before your first production build. Keep it updated as you make changes to your app or build configuration.
