// Configuration for Google Drive API

class GoogleDriveConfig {
  // Load Service Account JSON from environment variable at compile time
  static const String serviceAccountKey = String.fromEnvironment(
    'GOOGLE_DRIVE_SERVICE_ACCOUNT',
    defaultValue: '',
  );

  // Specify a specific folder ID in Google Drive to search within
  static const String targetFolderId = String.fromEnvironment(
    'GOOGLE_DRIVE_FOLDER_ID',
    defaultValue: '',
  );

  // Optional: Configure search parameters
  static const int maxResults = 50;
  static const List<String> allowedVideoTypes = [
    'video/mp4',
    'video/mpeg',
    'video/quicktime',
    'video/x-msvideo',
    'video/webm'
  ];
}

