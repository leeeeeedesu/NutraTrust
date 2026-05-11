# Firebase Security Rules Setup Guide

## Instructions to Apply These Rules

### Step 1: Access Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your "e-commerce-92163" project
3. Navigate to **Realtime Database** → **Rules** tab

### Step 2: Copy and Paste Rules
Replace the existing rules with the content from `firebase_rules.json` in this repository.

### Step 3: Key Security Rules Implemented

#### Products Node
```
- READ: Allowed for all authenticated users
- WRITE: Allowed only for users with 'admin' role
- Validation: Ensures name, price, and stock are present
- Field validation: Ensures price and stock are non-negative numbers
```

#### Likes Node
```
- READ/WRITE: Allowed for authenticated users
- User-specific privacy: Users can only read/write their own likes unless they are admins
- Prevents unauthorized access to other users' likes
```

#### Reviews Node
```
- READ/WRITE: Allowed for authenticated users
- Validation: Ensures rating is between 1-5
- Ensures productId and uid are present
```

### Step 4: Enable App Check (Optional but Recommended)

For additional security on physical devices:

1. In Firebase Console, go to **App Check**
2. Click **Enable App Check**
3. Select your Android and iOS apps
4. Follow the configuration steps for each platform
5. In [main.dart](lib/main.dart), add App Check initialization:

```dart
await Firebase.initializeApp();
await FirebaseAppCheck.instance.activate(
  webRecaptchaSiteKey: null, // For Android/iOS
  androidProvider: AndroidProvider.playIntegrity,
  appleProvider: AppleProvider.appAttest,
);
```

## Debugging on Physical Device

### Print Logs for Testing
The updated code includes comprehensive debug logging:

```dart
// View logs while app is running:
// - Connect device via USB
// - Run: flutter run -v
// - Search for "ProductsStream:", "ProductList:", "Product.fromMap" in output
```

### Common Issues and Solutions

#### Issue: "Permission denied" on physical device
**Causes:**
- User not authenticated
- Firebase rules not updated yet
- User role not set to 'admin' for admin operations

**Solution:**
- Ensure user is logged in
- Check Firebase Console → Database → Rules are deployed
- Verify user has proper role in `/users/{uid}/role`

#### Issue: Products show "Out of stock" unexpectedly
**Solution:**
- Check console logs for "invalid stock" warnings
- Verify product data in Firebase Console
- Ensure stock field is a positive number, not a string

#### Issue: Product list displays but empty on physical device
**Solutions:**
- Check "ProductsStream" debug logs
- Verify `/products` node exists in Firebase Realtime Database
- Ensure authenticated user has read permission
- Check device has internet connectivity

## Product List Widget Usage

The new `ProductList` widget provides:
- ✅ Null safety for all product fields
- ✅ Default values for missing fields
- ✅ Text overflow prevention with Flexible/Expanded
- ✅ Debug logging for each product loaded
- ✅ Error handling with helpful messages
- ✅ Image error fallback to placeholder icon

### Example Usage in home_page.dart:

```dart
StreamBuilder<List<Product>>(
  stream: RealtimeDatabaseService.productsStream(),
  builder: (context, snapshot) {
    return ProductList(
      products: snapshot.data ?? [],
      isLoading: snapshot.connectionState == ConnectionState.waiting,
      hasError: snapshot.hasError,
      errorMessage: snapshot.error?.toString(),
    );
  },
)
```

## Testing Checklist

- [ ] App works on Android emulator
- [ ] App works on iOS simulator
- [ ] App works on physical Android device
- [ ] App works on physical iOS device
- [ ] Products display with all fields visible
- [ ] No text overflow on smaller screens
- [ ] Like button works on both emulator and device
- [ ] Product images load correctly
- [ ] Error messages display clearly if database unavailable
- [ ] Console logs show product loading details

## Firebase Rules Deployment Checklist

- [ ] Rules updated in Firebase Console
- [ ] Rules published (saved)
- [ ] App Check enabled (if using physically-signed APKs)
- [ ] Tested on emulator first (rules may be less strict in test mode)
- [ ] Tested on physical device
- [ ] Monitor Firebase Real-time Database for any permission errors

## Performance Tips

1. **Reduce Log Output**: Comment out `debugPrint` statements in production builds
2. **Optimize Image Loading**: Consider image caching with `CachedNetworkImage` package
3. **Filter Products**: Use `searchProducts()` for specific queries instead of loading all
4. **Database Indexing**: Add indexes in Firebase for frequently filtered fields

## Support

For issues with:
- **App not starting**: Check Flutter version compatibility
- **Products not loading**: Verify internet connection and Firebase rules
- **Crashes on device**: Check console logs with `flutter run -v`
- **Permission errors**: Check Firebase Console Rules tab for syntax errors

