// Configuration for Google Drive API
// Replace this with your actual service account key JSON

class GoogleDriveConfig {
  // IMPORTANT: Replace this entire JSON with your actual service account key
  // Download the JSON key file from Google Cloud Console and paste its contents here
  static const String serviceAccountKey = '''
{
  "type": "service_account",
  "project_id": "peaceful-nature-426522-u8",
  "private_key_id": "1705b6452d48f3bf550cc8b714c6b9cd488adeeb",
  "private_key": "-----BEGIN PRIVATE KEY-----\\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQD32LNPAnljGMgW\\nxCi3z694qCfI9kZ14x3Fla1DLSS9EDeXUMexCU1KgiU0f5YGGzryXjZfcw0X77bO\\n4tFYvTN5gsQkrL+2vm0+7WofuZgcDZr4qfKzQbJraELuXjgKh7p9hMwi8lMNKlxs\\n/nR9+UYTZFMtDpK16jVjp+wg+rEnCHyCQydHlzZmRUSWGkocvWZNcovGctIb3Rz/\\nP5C6WK3QGz4rmSXQ720f0WVkNn/eP15gvbnt8mvy5+ph+rOCxemaIBzjhTdaAriI\\nvebkN8+3AciMDuo6CP0O360U0YFUsZ8BfwheAfiouFV97U47h6PwW62PWjjItff2\\nuGn6EFWXAgMBAAECggEAJKRD9iVeftkWE8+SWYJ55bOulhZa2mjmaOS1Bd5xtQXl\\nwhguPa0rYR2WlIlcS7DQ6S4mibv/ro9BDpsX6i+moYtEpktn2IOUsR32d5Q/ub4F\\nMEgn2nqW/ywd4RHK5TulxZLRf0UmJCckHPUNkeY9hvZpGZsy83QZyo7z6PhHIobj\\nLD3s/Bqb6EFmzGs6AZ16Hx7vrlZve79NTKYdQaPi2D/D/cQXNQUHdQKZ5YjFb7tf\\nIizgAFTLsARDCzIbQLbBD5ARVipb3YlXL5GKiKMjaeXSK2TGqB4RHeJRgkDDJoH5\\n52liWbO7zZx14uYiE37GwU1WsVGbY0ZKYCUIrVPG+QKBgQD/2ziB3j4dqIcI++r7\\nAYt/A01Mulkwr9lOXHXhmHpFCx1aMnFC7Gqo5UZEN/6XU5FqwSO35HtYZ/5khmUh\\nUFNWdr8qO7egm7LRSjEB3wjy3p3BVcxZ/x6000wv2mX6UaXkBM0eHytHBHCvdxKl\\nBq20rapQrce9l7JKT4U98C193QKBgQD3/FQKKB+hDezCkbPoipN8Xx9wUQgDEl8l\\nU6uXn5sgcx8EWiyXDzW6AKAjJplug1Aa82/+JcSmZkRA4o49i/AOtEWhZw0vYml1\\n3wRD5VqCj7LKHojljHW60zLoTOGzePZsc5XIPQotLjh+6cNpFzyIqbVnzWeNvh1l\\nWhBn38+MAwKBgQC7gFBc/B3RZlvvfY6q/GraXfUcMcSDJZu/DYtmFHQmfQq5uxW9\\n0bwooj1oaRCunZOIBJrEfTDXjP6ldMhQLamlR8i4jqL3lKLrNc/Ma0MHmZVKxjHI\\nEmrSYbcHqqnpVESaYdpgJL92gA6EyGJlhgtuyYZzMaebjbwfMT+YMJdmEQKBgDKF\\nzfljw03ksF/Tn3u4/+NO3fDcEW3OyGOqcEMr2Ub7LU6NsJf2GVQT3IxMyOWjCyby\\ngdadizr7itxNS/1uDTJxt93ySNVmj2XcUdojWBVRgXN8VRevTi0J6k05nKIb+tiN\\nk+5/wRsDV69DoPRAL60IJlVHm9lc6lBD0SPYjUhRAoGABROUt0qF+BXUEKE+pr4L\\n808Z4fSPk3kHcrOuzP5YXx9zi0sRM0+/rSl8+1236qEWKNIB264ow3DFfwYP675P\\neR1AbqoVmXThYrQXxPnlIn9HkW0UqrzXZQPqdC0HWv+ASQBRMiNuTxDdawwf2xV/\\nZsaRdZkQ//T+bTVoWhH7ZrI=\\n-----END PRIVATE KEY-----",
  "client_email": "signify1234@peaceful-nature-426522-u8.iam.gserviceaccount.com",
  "client_id": "103820920488904981278",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/signify1234%40peaceful-nature-426522-u8.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
}
''';

  // Optional: Specify a specific folder ID in Google Drive to search within
  // If empty, it will search all accessible files
  static const String? targetFolderId = '1AX-cUvTzVOpIhQmkUQyXwFCX67vWm_wU'; // ISL Dictionary folder
  // static const String? targetFolderId = null; // Temporarily disabled to test global search

  
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
