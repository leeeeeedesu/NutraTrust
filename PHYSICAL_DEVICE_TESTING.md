# Physical Device Testing Guide

## Pre-Testing Checklist

### 1. Build APK/App for Physical Device
```bash
# For Android
flutter build apk --release
# Or for testing with debug info:
flutter build apk --debug

# For iOS
flutter build ios --release
```

### 2. Install on Device
```bash
# Android
flutter install

# iOS
# Use Xcode or:
flutter run -d <device_id>
```

## Testing Procedures

### Step 1: Monitor Console Logs
```bash
# Run app with verbose logging
flutter run -v

# Look for these debug messages:
# - "ProductsStream: Loading X products from database"
# - "ProductsStream: Loaded product - ID: ..."
# - "Product.fromMap - ID: ..., Name: ..., Price: ..."
# - "Permission denied" errors (if Firebase rules not applied)
```

### Step 2: Verify Product List Display

**On Home Page:**
- [ ] Products load and display correctly
- [ ] All product names are visible (not cut off)
- [ ] Prices display with ₱ symbol
- [ ] Stock status shows (e.g., "Stock: 5" or "Out of stock")
- [ ] No text overflow on smaller screens
- [ ] Product images load correctly (or show placeholder icon)

**Test on Different Device Sizes:**
- [ ] Small phone (5-inch screen)
- [ ] Medium phone (6-inch screen)
- [ ] Large phone (6.7+ inch screen)
- [ ] Tablet (if available)

### Step 3: Test Product Interactions

**Tap Product:**
- [ ] View product page opens
- [ ] All product details display correctly
- [ ] No crashes or error screens

**Like Button:**
- [ ] Click heart icon
- [ ] Heart fills (liked) or empties (unliked)
- [ ] Changes persist when navigating away and back

**Search:**
- [ ] Search page opens
- [ ] Type product name
- [ ] Results display correctly
- [ ] No overflow or display issues

### Step 4: Network & Permission Testing

**With Internet:**
- [ ] Products load on first app launch
- [ ] Refresh (kill and reopen app) reloads products
- [ ] No errors in console

**Without Internet (Airplane Mode):**
- [ ] App shows loading indicator
- [ ] After timeout, shows error message
- [ ] Error message is clear and helpful

**Permission Denied Tests:**
- If you see "Permission denied" errors:
  1. Go to [Firebase Console](https://console.firebase.google.com)
  2. Select your project
  3. Go to Realtime Database → Rules
  4. Ensure rules are updated from [firebase_rules.json](firebase_rules.json)
  5. Click "Publish"
  6. Wait 30 seconds for rules to deploy
  7. Restart app

### Step 5: Error Handling Tests

**Missing Product Image:**
- [ ] Shows placeholder shopping bag icon
- [ ] No crashes or black screen
- [ ] Product info still displays

**Missing Product Fields:**
- If database has product without name:
  - [ ] Shows "Uncategorized"
  - [ ] No crashes
- If product has zero or negative stock:
  - [ ] Shows "Out of stock" in red
  - [ ] No crashes

**Empty Product List:**
- [ ] Shows "No products available" message
- [ ] Message is centered and readable
- [ ] No crashes

### Step 6: Performance Testing

**Load Time:**
- [ ] Products appear within 3-5 seconds on first load
- [ ] Subsequent navigations load instantly

**Scrolling:**
- [ ] Product grid scrolls smoothly
- [ ] No lag or frame drops
- [ ] Images load as you scroll

**Memory:**
- [ ] App doesn't crash after scrolling many times
- [ ] No continuous growth in memory usage

## Common Issues & Solutions

### Issue: Products don't load, app is stuck loading
**Check:**
```bash
# 1. Check internet connection
flutter run -v
# Look for network errors

# 2. Verify Firebase database has products
# Go to: Firebase Console → Realtime Database → Data
# Check if /products node exists and has data

# 3. Check Firebase rules are deployed
# Go to: Firebase Console → Realtime Database → Rules
# Verify rules match firebase_rules.json
```

**Fix:**
- Ensure user is logged in
- Check Firebase Console for rules syntax errors (red indicator)
- Wait 30 seconds after publishing rules
- Restart app after fixing rules

### Issue: "Permission denied" error in console
**Root Cause:** Firebase rules don't allow authenticated users to read products

**Fix:**
```
In Firebase Console:
1. Go to Realtime Database → Rules
2. Find the "products" section
3. Ensure it has: ".read": "auth != null"
4. Click "Publish"
5. Restart app and wait 30 seconds
```

### Issue: Product names show as "Uncategorized" but they have names in database
**Root Cause:** Product data might be corrupted or missing `name` field

**Check:**
1. Open Firebase Console → Realtime Database
2. Click on a product and verify `name` field exists
3. Check console logs for: "Product.fromMap - ID: ..., Name: ..."
4. If name shows as empty, fix the product data in Firebase

### Issue: Text overflows on specific screen size
**Solution:** Text is already wrapped with Flexible widgets. If still occurring:
1. Check console for specific screen dimensions
2. Verify product names aren't extremely long (>50 characters)
3. Test on actual device (not just emulator)

### Issue: Images don't load (show placeholder icon)
**Check:**
1. Product has `imageUrl` field in database
2. URL is valid (accessible from device browser)
3. Check network connectivity
4. Console logs show: "Error loading network image for..."

**Fix:**
- Add image URLs to products in Firebase Console
- Ensure URLs are public (not requiring authentication)
- Consider using a CDN like Cloudinary for better performance

### Issue: Like button doesn't work
**Check:**
1. User is authenticated
2. Navigate to Likes page → products should appear there
3. Check console for errors related to likes

**Debug:**
```bash
# Add print statements to like_service.dart to track toggle calls
flutter run -v
# Look for like-related debug output
```

## Performance Tips

1. **Reduce Logs in Production:**
   - Comment out or remove `debugPrint()` statements
   - Use `kDebugMode` to conditionally log only in debug builds

2. **Cache Product Images:**
   - Consider using `cached_network_image` package
   - Reduces repeated downloads from CDN

3. **Optimize Database Reads:**
   - Use `searchProducts()` instead of `getAllProducts()` when possible
   - Implement pagination for large product lists

## Reporting Issues

If experiencing unexpected crashes or display issues:

1. **Collect Debug Info:**
   ```bash
   flutter run -v 2>&1 | tee debug.log
   ```

2. **Check These Log Sections:**
   - ProductsStream loading messages
   - Product.fromMap parsing messages
   - Network/Firebase errors
   - Widget rendering errors

3. **Device Info:**
   - Device model and Android/iOS version
   - Screen size and orientation
   - Network type (WiFi/4G)
   - App version

4. **Steps to Reproduce:**
   - Exact sequence to trigger the issue
   - Whether it happens on emulator, device, or both
   - Whether it's consistent or intermittent

## Quick Test Checklist (5-minute test)

- [ ] App launches on device
- [ ] Products load within 5 seconds
- [ ] All 5+ products display with names and prices
- [ ] No text overflows on home page
- [ ] Can tap product and view details
- [ ] Like button works
- [ ] No crashes or errors in console
- [ ] Back button works correctly
- [ ] Search page loads and works
- [ ] Responsive to screen rotation (if enabled)

✅ All checks pass = App is ready for production!

