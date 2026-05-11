import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'realtime_database_service.dart';

class CloudinaryService {
  final String cloudName;
  final String uploadPreset;

  CloudinaryService({
    this.cloudName = 'dbwvd2j9x',
    this.uploadPreset = 'e-commerce',
  });

  Future<String> uploadImage(File imageFile) async {
    debugPrint('Uploading image with preset: $uploadPreset');

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    debugPrint('Cloudinary upload response: $responseBody');

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Cloudinary upload failed (${response.statusCode}): $responseBody',
      );
    }

    final jsonResponse = jsonDecode(responseBody);
    if (jsonResponse is! Map || jsonResponse['secure_url'] == null) {
      throw Exception('Cloudinary upload did not return a secure_url.');
    }

    final secureUrl = jsonResponse['secure_url'].toString();
    debugPrint('Upload success: secure_url = $secureUrl');

    return secureUrl;
  }

  /// Upload profile image and save to appropriate Firebase path
  /// Saves to /users/{uid}/profileImage for all users
  /// Also saves to /admins/{uid}/profileImage if user is admin
  Future<String> uploadProfileImage(
    File imageFile,
    String uid,
    bool isAdmin,
  ) async {
    // Upload to Cloudinary
    final secureUrl = await uploadImage(imageFile);

    // Save to user profile path
    try {
      await RealtimeDatabaseService.updateUserImages(
        uid,
        profileImageUrl: secureUrl,
      );
      debugPrint('Saved profileImage for user $uid: $secureUrl');
    } catch (e) {
      debugPrint('Failed to save profileImage for user $uid: $e');
    }

    // If admin, also save to admin path
    if (isAdmin) {
      try {
        final database = FirebaseDatabase.instanceFor(
          app: FirebaseAuth.instance.app,
          databaseURL: RealtimeDatabaseService.databaseUrl,
        );
        await database.ref('admins/$uid/profileImage').set(secureUrl);
        debugPrint('Saved profileImage for admin $uid: $secureUrl');
      } catch (e) {
        debugPrint('Failed to save profileImage for admin $uid: $e');
      }
    }

    return secureUrl;
  }
}
