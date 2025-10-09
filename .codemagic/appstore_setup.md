# App Store Connect Setup Guide

This guide will help you set up App Store Connect for automated publishing of the Hindu Connect iOS app.

## 🍎 App Store Connect Configuration

### 1. Create App in App Store Connect

1. **Login to App Store Connect**
   - Go to [App Store Connect](https://appstoreconnect.apple.com)
   - Sign in with your Apple Developer account

2. **Create New App**
   - Click "My Apps" → "+" → "New App"
   - Fill in the details:
     - **Platform**: iOS
     - **Name**: Hindu Connect
     - **Primary Language**: English
     - **Bundle ID**: `com.dikonda.hinduconnect`
     - **SKU**: `hinduconnect-ios`
     - **User Access**: Full Access

3. **App Information**
   - **Category**: Lifestyle or Reference
   - **Content Rights**: No
   - **Age Rating**: Complete the questionnaire

### 2. Set Up API Key

1. **Create API Key**
   - Go to "Users and Access" → "Keys" → "App Store Connect API"
   - Click "+" to create a new key
   - **Name**: Hindu Connect CI/CD
   - **Access**: App Manager
   - **Download**: Save the .p8 file securely

2. **Get Key Information**
   - **Key ID**: Found in the key list
   - **Issuer ID**: Found at the top of the Keys page
   - **Private Key**: Content of the downloaded .p8 file

### 3. Configure Codemagic

1. **Add Environment Variables**
   ```
   APP_STORE_CONNECT_ISSUER_ID: [Your Issuer ID]
   APP_STORE_CONNECT_KEY_IDENTIFIER: [Your Key ID]
   APP_STORE_CONNECT_PRIVATE_KEY: [Your Private Key Content]
   ```

2. **Set Up Code Signing**
   - Codemagic can automatically manage certificates
   - Or upload your own distribution certificate

## 📱 App Store Listing

### Required Information

1. **App Description**
   ```
   World's 1st Complete Devotional App - Hindu Connect
   
   Experience the sacredness of Sanatana Dharma with technology! 
   Discover sacred texts, explore temples, learn about saints, 
   and connect with your spiritual journey.
   ```

2. **Keywords**
   ```
   Hindu, devotional, sacred texts, temples, spirituality, 
   Sanatana Dharma, mantras, chants, prayers
   ```

3. **Screenshots**
   - iPhone screenshots (required)
   - iPad screenshots (if supporting iPad)
   - Various device sizes

4. **App Icon**
   - 1024x1024 pixels
   - PNG format
   - No transparency

### App Categories
- **Primary**: Lifestyle
- **Secondary**: Reference

## 🔐 Security & Compliance

### Privacy Policy
- Required for App Store submission
- Must be accessible via URL
- Should cover data collection and usage

### Terms of Service
- Recommended for user agreements
- Should be accessible via URL

### Data Collection
- Declare what data you collect
- Explain how data is used
- Provide user control options

## 🚀 Publishing Process

### 1. TestFlight Distribution

1. **Automatic Upload**
   - Codemagic uploads to TestFlight automatically
   - Builds are available for internal testing

2. **Beta Testing**
   - Add beta testers
   - Collect feedback
   - Fix issues before App Store release

### 2. App Store Release

1. **Manual Submission**
   - Submit for App Store review
   - Wait for Apple's approval
   - Release to public

2. **Automatic Submission** (Optional)
   - Enable in Codemagic configuration
   - Automatically submits for review
   - Requires careful testing

## 📊 Monitoring & Analytics

### App Store Connect Analytics
- Download metrics
- User engagement
- Revenue tracking
- Crash reports

### TestFlight Analytics
- Beta tester feedback
- Crash reports
- Performance metrics

## 🔄 Update Process

### Version Updates
1. Update version in `pubspec.yaml`
2. Push to repository
3. Codemagic builds automatically
4. Uploads to TestFlight
5. Submit for App Store review

### Hotfixes
1. Create hotfix branch
2. Fix the issue
3. Merge to main
4. Build and deploy

## 📋 Pre-Launch Checklist

- [ ] App created in App Store Connect
- [ ] API key configured in Codemagic
- [ ] Code signing set up
- [ ] App description completed
- [ ] Screenshots uploaded
- [ ] App icon uploaded
- [ ] Privacy policy URL added
- [ ] Terms of service URL added
- [ ] Age rating completed
- [ ] TestFlight build uploaded
- [ ] Beta testing completed
- [ ] App Store submission ready

## 🆘 Troubleshooting

### Common Issues

1. **API Key Issues**
   - Verify key has correct permissions
   - Check key is not expired
   - Ensure issuer ID is correct

2. **Code Signing Issues**
   - Verify certificates are valid
   - Check provisioning profiles
   - Ensure bundle ID matches

3. **Upload Issues**
   - Check app version is unique
   - Verify app is configured correctly
   - Check network connectivity

### Getting Help

- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [Codemagic Documentation](https://docs.codemagic.io)
- [Apple Developer Forums](https://developer.apple.com/forums/)

## 📞 Support

For issues with:
- **App Store Connect**: Contact Apple Developer Support
- **Codemagic**: Contact Codemagic Support
- **App Development**: Check Flutter documentation
