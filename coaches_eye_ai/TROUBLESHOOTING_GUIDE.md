# 🛠️ Troubleshooting Guide - Smart Cricket Bat App

## Overview

This comprehensive troubleshooting guide helps you resolve common issues with the Smart Cricket Bat app, from basic setup problems to advanced hardware integration issues.

---

## 🚨 Quick Fixes

### App Won't Start
**Symptoms**: App crashes on startup or shows blank screen

**Quick Solutions**:
1. **Restart the app**: Close completely and reopen
2. **Restart your device**: Power off and on
3. **Check storage**: Ensure sufficient storage space
4. **Update app**: Check for app updates
5. **Reinstall**: Uninstall and reinstall the app

**Advanced Solutions**:
```bash
# Clear app data (Android)
adb shell pm clear com.coacheseyeai.smartcricketbat

# Reset app permissions
# Go to Settings > Apps > Coach's Eye AI > Permissions
# Reset all permissions and re-grant them
```

### Can't Connect to Smart Bat
**Symptoms**: App shows "Not Connected" or connection fails

**Quick Solutions**:
1. **Check Bluetooth**: Ensure Bluetooth is enabled
2. **Check battery**: Verify Smart Bat is charged
3. **Restart connection**: Turn Smart Bat off/on
4. **Check distance**: Stay within 10 meters
5. **Restart app**: Close and reopen the app

**Advanced Solutions**:
```dart
// Reset BLE service
final bleService = BLEService();
await bleService.dispose();
// Reinitialize and try again
```

---

## 📱 App Issues

### Authentication Problems

#### Can't Sign In
**Symptoms**: Login fails with error messages

**Solutions**:
1. **Check credentials**: Verify email and password
2. **Reset password**: Use "Forgot Password" feature
3. **Check internet**: Ensure stable internet connection
4. **Clear cache**: Clear app cache and data
5. **Contact support**: If problem persists

**Error Messages**:
- **"User not found"**: Email doesn't exist in system
- **"Wrong password"**: Incorrect password entered
- **"Too many attempts"**: Wait 15 minutes before retrying
- **"Network error"**: Check internet connection

#### Can't Sign Up
**Symptoms**: Registration fails or account creation errors

**Solutions**:
1. **Check email format**: Ensure valid email address
2. **Strong password**: Use 8+ characters with numbers/symbols
3. **Check internet**: Stable connection required
4. **Try different email**: Email might already exist
5. **Contact support**: For persistent issues

### Session Issues

#### Session Won't Start
**Symptoms**: Can't begin new training session

**Solutions**:
1. **Check permissions**: Grant camera and storage permissions
2. **Check storage**: Ensure sufficient storage space
3. **Restart app**: Close and reopen
4. **Check internet**: Required for session initialization
5. **Try simulator mode**: Use hardware simulator if available

#### Session Data Not Saving
**Symptoms**: Session data disappears or doesn't save

**Solutions**:
1. **Check internet**: Stable connection required
2. **Check Firebase**: Verify Firebase connection
3. **Restart session**: End and start new session
4. **Check storage**: Ensure sufficient storage
5. **Contact support**: For data recovery

### Video Recording Issues

#### Camera Won't Start
**Symptoms**: Camera fails to initialize or record

**Solutions**:
1. **Grant permissions**: Allow camera access
2. **Check storage**: Ensure sufficient storage space
3. **Restart camera**: Close and reopen camera
4. **Check other apps**: Close other camera apps
5. **Restart device**: Power cycle if needed

#### Video Quality Issues
**Symptoms**: Poor video quality or recording problems

**Solutions**:
1. **Check settings**: Adjust video quality in settings
2. **Check storage**: Low storage affects quality
3. **Clean lens**: Clean camera lens
4. **Check lighting**: Ensure adequate lighting
5. **Update app**: Check for app updates

---

## 🔗 Bluetooth & Hardware Issues

### BLE Connection Problems

#### Device Not Found
**Symptoms**: Smart Bat doesn't appear in scan results

**Solutions**:
1. **Check power**: Ensure Smart Bat is powered on
2. **Check battery**: Low battery affects discovery
3. **Check distance**: Stay within 10 meters
4. **Restart scan**: Stop and restart scanning
5. **Check interference**: Avoid areas with many Bluetooth devices

**Advanced Troubleshooting**:
```dart
// Check Bluetooth availability
final bleService = BLEService();
final isAvailable = await bleService.isBluetoothAvailable();
print('Bluetooth available: $isAvailable');

// Check permissions
final hasPermissions = await bleService.requestPermissions();
print('Permissions granted: $hasPermissions');
```

#### Connection Timeout
**Symptoms**: Connection attempt times out

**Solutions**:
1. **Check distance**: Move closer to Smart Bat
2. **Check battery**: Ensure sufficient charge
3. **Restart both**: Turn off Smart Bat and restart app
4. **Check interference**: Move to different location
5. **Update firmware**: Check for Smart Bat firmware updates

#### Frequent Disconnections
**Symptoms**: Connection drops frequently during use

**Solutions**:
1. **Check distance**: Stay within 5 meters
2. **Check battery**: Low battery causes disconnections
3. **Check interference**: Avoid WiFi routers, microwaves
4. **Restart connection**: Reconnect when needed
5. **Check firmware**: Update Smart Bat firmware

### Hardware Issues

#### No Shot Detection
**Symptoms**: App doesn't detect cricket shots

**Solutions**:
1. **Check mounting**: Ensure sensor is properly attached
2. **Check calibration**: Recalibrate sensors
3. **Check sensitivity**: Adjust detection sensitivity
4. **Check battery**: Low battery affects sensors
5. **Test hardware**: Use hardware test mode

#### Inaccurate Data
**Symptoms**: Shot data seems incorrect or unrealistic

**Solutions**:
1. **Recalibrate**: Recalibrate Smart Bat sensors
2. **Check mounting**: Ensure proper sensor alignment
3. **Check firmware**: Update to latest firmware
4. **Check environment**: Avoid magnetic interference
5. **Contact support**: For hardware issues

#### Battery Issues
**Symptoms**: Smart Bat battery drains quickly or won't charge

**Solutions**:
1. **Check charger**: Verify charger is working
2. **Check cable**: Try different USB cable
3. **Check port**: Clean charging port
4. **Check battery**: Battery may need replacement
5. **Contact support**: For hardware warranty

---

## 🔥 Firebase Issues

### Authentication Errors

#### Firebase Auth Not Working
**Symptoms**: Can't authenticate with Firebase

**Solutions**:
1. **Check internet**: Stable connection required
2. **Check Firebase config**: Verify configuration
3. **Check API keys**: Ensure valid API keys
4. **Check project**: Verify Firebase project is active
5. **Contact support**: For configuration issues

#### Firestore Errors
**Symptoms**: Data not saving or loading from Firestore

**Solutions**:
1. **Check internet**: Stable connection required
2. **Check rules**: Verify Firestore security rules
3. **Check permissions**: Ensure proper user permissions
4. **Check project**: Verify Firestore is enabled
5. **Check quotas**: Ensure not exceeding limits

### Storage Issues

#### File Upload Fails
**Symptoms**: Videos or photos won't upload

**Solutions**:
1. **Check internet**: Stable connection required
2. **Check storage**: Ensure sufficient Firebase storage
3. **Check file size**: Large files may timeout
4. **Check permissions**: Verify storage permissions
5. **Retry upload**: Try uploading again

#### File Download Issues
**Symptoms**: Can't download saved files

**Solutions**:
1. **Check internet**: Stable connection required
2. **Check permissions**: Verify file access permissions
3. **Check file exists**: Ensure file wasn't deleted
4. **Check storage**: Ensure sufficient local storage
5. **Contact support**: For file recovery

---

## 📊 Performance Issues

### App Performance

#### Slow Performance
**Symptoms**: App runs slowly or freezes

**Solutions**:
1. **Close other apps**: Free up device memory
2. **Restart device**: Clear memory and cache
3. **Check storage**: Ensure sufficient storage space
4. **Update app**: Install latest version
5. **Check device**: Ensure device meets requirements

#### High Battery Usage
**Symptoms**: App drains battery quickly

**Solutions**:
1. **Close app**: When not in use
2. **Disable BLE**: Turn off Bluetooth when not needed
3. **Reduce video quality**: Lower recording quality
4. **Check background**: Disable background processing
5. **Update app**: Latest version may be more efficient

### Memory Issues

#### Out of Memory
**Symptoms**: App crashes with memory errors

**Solutions**:
1. **Close other apps**: Free up device memory
2. **Restart device**: Clear memory
3. **Check storage**: Ensure sufficient storage
4. **Reduce video quality**: Lower recording quality
5. **Update app**: Latest version may be optimized

#### Memory Leaks
**Symptoms**: App becomes slower over time

**Solutions**:
1. **Restart app**: Close and reopen regularly
2. **Update app**: Latest version may fix leaks
3. **Check usage**: Monitor memory usage
4. **Contact support**: Report persistent issues
5. **Reinstall**: Fresh installation may help

---

## 🌐 Network Issues

### Internet Connection

#### No Internet Connection
**Symptoms**: App can't connect to internet

**Solutions**:
1. **Check WiFi**: Ensure WiFi is connected
2. **Check mobile data**: Enable mobile data if needed
3. **Check signal**: Ensure strong signal
4. **Restart network**: Turn off/on WiFi or mobile data
5. **Check router**: Restart router if using WiFi

#### Slow Internet
**Symptoms**: App loads slowly or times out

**Solutions**:
1. **Check speed**: Test internet speed
2. **Move closer**: Get closer to WiFi router
3. **Check interference**: Avoid interference sources
4. **Switch networks**: Try different WiFi or mobile data
5. **Contact ISP**: For persistent slow speeds

### API Issues

#### API Timeout
**Symptoms**: API calls timeout or fail

**Solutions**:
1. **Check internet**: Ensure stable connection
2. **Retry request**: Try again after delay
3. **Check server**: Verify server is running
4. **Check API limits**: Ensure not exceeding limits
5. **Contact support**: For persistent API issues

#### API Errors
**Symptoms**: API returns error codes

**Solutions**:
1. **Check error code**: Look up specific error
2. **Check parameters**: Verify request parameters
3. **Check authentication**: Ensure valid credentials
4. **Check permissions**: Verify API permissions
5. **Contact support**: For API configuration issues

---

## 🔧 Advanced Troubleshooting

### Debug Mode

#### Enable Debug Logging
```dart
// Enable debug mode
const bool debugMode = true;

// Add debug logging
if (debugMode) {
  print('BLE Connection State: $connectionState');
  print('Shot Data: $shotData');
  print('Error: $error');
}
```

#### Check Debug Information
1. **Enable developer options** on your device
2. **Enable USB debugging** (Android)
3. **Check logcat** for error messages
4. **Use Flutter inspector** for UI debugging
5. **Check Firebase console** for backend errors

### Hardware Testing

#### Test BLE Connection
```dart
// Test BLE service
final bleService = BLEService();

// Test scanning
final devices = await bleService.scanForDevices();
print('Found devices: ${devices.length}');

// Test connection
if (devices.isNotEmpty) {
  await bleService.connectToDevice(devices.first);
  print('Connection state: ${bleService.isConnected}');
}
```

#### Test Sensor Data
```dart
// Test sensor data parsing
final testData = "12.34,-5.67,8.90,123.45,-67.89,45.12";
final sensorData = bleService.parseSensorData(testData);
print('Parsed data: $sensorData');

// Test shot detection
final isShot = bleService.isShotDetected(sensorData);
print('Shot detected: $isShot');
```

### Performance Testing

#### Memory Usage
```dart
// Check memory usage
import 'dart:developer' as developer;

void checkMemoryUsage() {
  developer.Timeline.startSync('memory_check');
  // Your code here
  developer.Timeline.finishSync();
}
```

#### Performance Monitoring
```dart
// Monitor performance
final monitor = PerformanceMonitor();

monitor.startOperation('ble_connection');
try {
  await bleService.connectToDevice(device);
} finally {
  monitor.endOperation('ble_connection');
}

final metrics = monitor.getMetrics();
print('BLE connection time: ${metrics['ble_connection']}');
```

---

## 📞 Getting Help

### Self-Help Resources

1. **User Guide**: Check the comprehensive user guide
2. **FAQ**: Review frequently asked questions
3. **Video Tutorials**: Watch setup and usage videos
4. **Community Forum**: Ask questions in user community
5. **Knowledge Base**: Search our knowledge base

### Contact Support

#### Email Support
- **General Support**: support@coacheseyeai.com
- **Technical Issues**: tech@coacheseyeai.com
- **Hardware Issues**: hardware@coacheseyeai.com
- **Billing Questions**: billing@coacheseyeai.com

#### Live Support
- **In-App Chat**: Available in app settings
- **Phone Support**: 1-800-COACH-AI
- **Business Hours**: Monday-Friday, 9 AM - 6 PM EST

#### Emergency Support
- **Critical Issues**: emergency@coacheseyeai.com
- **24/7 Hotline**: 1-800-EMERGENCY
- **Response Time**: Within 2 hours

### Reporting Issues

#### Bug Reports
When reporting bugs, include:
1. **Device Information**: Model, OS version
2. **App Version**: Current app version
3. **Steps to Reproduce**: Detailed steps
4. **Expected Behavior**: What should happen
5. **Actual Behavior**: What actually happens
6. **Screenshots**: If applicable
7. **Log Files**: If available

#### Feature Requests
When requesting features, include:
1. **Feature Description**: Detailed description
2. **Use Case**: Why you need this feature
3. **Priority**: How important it is
4. **Alternatives**: Current workarounds
5. **Impact**: How it would help you

---

## 🔄 Maintenance & Updates

### Regular Maintenance

#### Weekly Tasks
- **Check for updates**: App and firmware updates
- **Clear cache**: Clear app cache
- **Check storage**: Ensure sufficient storage
- **Review settings**: Update preferences as needed

#### Monthly Tasks
- **Deep clean**: Clear all app data
- **Update firmware**: Check for hardware updates
- **Review performance**: Check app performance
- **Backup data**: Ensure data is backed up

#### Quarterly Tasks
- **Full reset**: Complete app reset
- **Hardware check**: Inspect Smart Bat hardware
- **Performance review**: Analyze performance trends
- **Feature review**: Check for new features

### Update Procedures

#### App Updates
1. **Check for updates**: In app store
2. **Read release notes**: Understand changes
3. **Backup data**: Ensure data is safe
4. **Install update**: Follow update process
5. **Test functionality**: Verify everything works

#### Firmware Updates
1. **Check for updates**: In app settings
2. **Follow instructions**: Read update guide
3. **Ensure battery**: Keep Smart Bat charged
4. **Update firmware**: Follow update process
5. **Test hardware**: Verify sensors work

---

## 📋 Troubleshooting Checklist

### Before Contacting Support

- [ ] **Restarted the app**
- [ ] **Restarted the device**
- [ ] **Checked internet connection**
- [ ] **Checked Bluetooth settings**
- [ ] **Checked app permissions**
- [ ] **Checked storage space**
- [ ] **Updated to latest app version**
- [ ] **Checked Smart Bat battery**
- [ ] **Tried hardware simulator mode**
- [ ] **Read relevant documentation**

### Information to Provide

- [ ] **Device model and OS version**
- [ ] **App version number**
- [ ] **Smart Bat firmware version**
- [ ] **Error messages (if any)**
- [ ] **Steps to reproduce the issue**
- [ ] **Screenshots or videos**
- [ ] **Log files (if available)**
- [ ] **Previous working state**
- [ ] **Recent changes made**

---

This troubleshooting guide should help you resolve most issues with the Smart Cricket Bat app. If you continue to experience problems, don't hesitate to contact our support team for assistance.
