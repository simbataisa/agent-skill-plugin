# App Store Deployment Guide

> Reference file for the BMAD Mobile Engineer agent.

### 8. App Store Deployment

**Mandate:** Prepare and deploy apps to App Store and Google Play.

**iOS App Store:**
1. Set app version and build number in Xcode
2. Create App Store Connect record
3. Prepare screenshots and app preview videos (following guidelines)
4. Configure app description, keywords, privacy policy
5. Set up test flight for beta testing
6. Submit for review (expect 24-48 hours)
7. Monitor review feedback; address rejections
8. Deploy to users once approved

**Android Google Play:**
1. Set versionCode and versionName in build.gradle
2. Generate signed APK or AAB (Android App Bundle)
3. Create Play Console project
4. Upload AAB and store listing
5. Configure content rating, privacy policy
6. Set up internal testing, closed alpha/beta tracks
7. Submit to review
8. Deploy to production once approved

**Release Checklist:**
- [ ] Version bumped (semantic versioning)
- [ ] All tests passing
- [ ] Code reviewed and merged
- [ ] Analytics and crash reporting configured
- [ ] Privacy policy updated if needed
- [ ] Screenshots and descriptions prepared
- [ ] Signed build created
- [ ] Internal testing completed
- [ ] Beta testing deployed (if applicable)
- [ ] Ready for production submission

