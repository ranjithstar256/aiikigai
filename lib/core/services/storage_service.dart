import 'dart:convert';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/error_handler.dart';

/// Provider for the Storage Service
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// Service for handling local and remote storage operations
class StorageService {
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Save data to shared preferences
  Future<void> saveToPrefs(
      {required String key, required dynamic value}) async {
    final prefs = await SharedPreferences.getInstance();

    if (value is String) {
      await prefs.setString(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is List<String>) {
      await prefs.setStringList(key, value);
    } else {
      // For complex objects, convert to JSON string
      await prefs.setString(key, jsonEncode(value));
    }
  }

  // Read string from shared preferences
  Future<String?> getStringFromPrefs(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  // Read int from shared preferences
  Future<int?> getIntFromPrefs(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key);
  }

  // Read bool from shared preferences
  Future<bool?> getBoolFromPrefs(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key);
  }

  // Read object from shared preferences
  Future<Map<String, dynamic>?> getObjectFromPrefs(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(key);

    if (jsonString != null) {
      try {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }

    return null;
  }

  // Remove from shared preferences
  Future<bool> removeFromPrefs(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.remove(key);
  }

  // Clear all shared preferences
  Future<bool> clearPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.clear();
  }

  // Save to secure storage
  Future<void> saveToSecureStorage(
      {required String key, required String value}) async {
    await _secureStorage.write(key: key, value: value);
  }

  // Read from secure storage
  Future<String?> getFromSecureStorage(String key) async {
    return await _secureStorage.read(key: key);
  }

  // Remove from secure storage
  Future<void> removeFromSecureStorage(String key) async {
    await _secureStorage.delete(key: key);
  }

  // Clear all secure storage
  Future<void> clearSecureStorage() async {
    await _secureStorage.deleteAll();
  }

  // Save file to local storage
  Future<File> saveFile({
    required String fileName,
    required List<int> bytes,
    String directory = 'documents',
  }) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dirPath = '${appDir.path}/$directory';

      // Create directory if it doesn't exist
      final dir = Directory(dirPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final file = File('$dirPath/$fileName');
      return await file.writeAsBytes(bytes);
    } catch (e) {
      throw StorageException('Failed to save file: $e');
    }
  }

  // Read file from local storage
  Future<File?> getFile({
    required String fileName,
    String directory = 'documents',
  }) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final filePath = '${appDir.path}/$directory/$fileName';

      final file = File(filePath);
      if (await file.exists()) {
        return file;
      }

      return null;
    } catch (e) {
      throw StorageException('Failed to read file: $e');
    }
  }

  // Delete file from local storage
  Future<bool> deleteFile({
    required String fileName,
    String directory = 'documents',
  }) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final filePath = '${appDir.path}/$directory/$fileName';

      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }

      return false;
    } catch (e) {
      throw StorageException('Failed to delete file: $e');
    }
  }

  // Upload file to Firebase Storage
  Future<String> uploadFile({
    required File file,
    required String path,
    String? userId,
  }) async {
    try {
      // Create reference to the file location in Firebase Storage
      final storageRef = _firebaseStorage.ref().child(
        userId != null ? 'users/$userId/$path' : path,
      );

      // Upload file
      final uploadTask = storageRef.putFile(file);

      // Wait for upload to complete and get download URL
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw StorageException('Failed to upload file: $e');
    }
  }

  // Download file from Firebase Storage
  Future<File> downloadFile({
    required String url,
    required String fileName,
    String directory = 'downloads',
  }) async {
    try {
      // Get reference from URL
      final storageRef = _firebaseStorage.refFromURL(url);

      // Get the download directory
      final appDir = await getApplicationDocumentsDirectory();
      final dirPath = '${appDir.path}/$directory';

      // Create directory if it doesn't exist
      final dir = Directory(dirPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // Create local file
      final file = File('$dirPath/$fileName');

      // Download to file
      await storageRef.writeToFile(file);

      return file;
    } catch (e) {
      throw StorageException('Failed to download file: $e');
    }
  }

  // Delete file from Firebase Storage
  Future<void> deleteFileFromStorage(String url) async {
    try {
      final storageRef = _firebaseStorage.refFromURL(url);
      await storageRef.delete();
    } catch (e) {
      throw StorageException('Failed to delete file from storage: $e');
    }
  }

// Get temporary directory
  Future<Directory> getTempDirectory() async {
    return await getTemporaryDirectory();
  }

  // Get application documents directory
  Future<Directory> getApplicationDirectory() async {
    return await getApplicationDocumentsDirectory();
  }

  // Get external storage directory (Android only)
  Future<Directory?> getExternalStorageDirectory() async {
    if (Platform.isAndroid) {
      return await getExternalStorageDirectory();
    }
    return null;
  }
}