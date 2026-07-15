// lib/core/utils/app_message.dart

class AppMessage {
  AppMessage._();

  static const Map<String, String> _exactMessages = {
    // Autentikasi
    'login successful': 'Login berhasil.',
    'login success': 'Login berhasil.',
    'login failed': 'Login gagal. Silakan periksa email dan kata sandi Anda.',
    'logout successful': 'Logout berhasil.',
    'logout success': 'Logout berhasil.',
    'registration successful': 'Registrasi berhasil.',
    'register successful': 'Registrasi berhasil.',
    'invalid credentials': 'Email atau kata sandi tidak sesuai.',
    'the provided credentials are incorrect':
        'Email atau kata sandi tidak sesuai.',
    'unauthenticated': 'Sesi login telah berakhir. Silakan login kembali.',
    'unauthorized': 'Anda tidak memiliki izin untuk mengakses fitur ini.',
    'forbidden': 'Anda tidak memiliki izin untuk mengakses data ini.',

    // Jaringan dan server
    'network error':
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
    'connection failed':
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
    'request timeout': 'Koneksi terlalu lama. Silakan coba lagi.',
    'connection timeout': 'Koneksi terlalu lama. Silakan coba lagi.',
    'internal server error':
        'Terjadi kesalahan pada server. Silakan coba lagi.',
    'server error': 'Terjadi kesalahan pada server. Silakan coba lagi.',
    'not found': 'Data yang diminta tidak ditemukan.',
    'data not found': 'Data tidak ditemukan.',
    'validation failed': 'Data yang dimasukkan belum sesuai.',

    // Presensi
    'attendance successful': 'Presensi berhasil.',
    'attendance submitted successfully': 'Presensi berhasil disimpan.',
    'check in successful': 'Presensi masuk berhasil.',
    'check-in successful': 'Presensi masuk berhasil.',
    'check out successful': 'Presensi keluar berhasil.',
    'check-out successful': 'Presensi keluar berhasil.',
    'updating gps location...': 'Memperbarui lokasi GPS...',
    'location permission denied': 'Izin lokasi ditolak.',
    'location permission permanently denied':
        'Izin lokasi ditolak permanen. Aktifkan izin melalui pengaturan.',
    'location services are disabled':
        'Layanan lokasi belum aktif. Silakan aktifkan GPS.',
    'outside attendance area':
        'Anda berada di luar zona presensi yang diizinkan.',
    'mock location detected':
        'Lokasi palsu terdeteksi. Presensi tidak dapat dilakukan.',

    // Cuti
    'leave submitted successfully': 'Pengajuan cuti berhasil dikirim.',
    'leave request submitted successfully': 'Pengajuan cuti berhasil dikirim.',
    'leave approved successfully': 'Pengajuan cuti berhasil disetujui.',
    'leave rejected successfully': 'Pengajuan cuti berhasil ditolak.',

    // Umum
    'success': 'Proses berhasil.',
    'failed': 'Proses gagal. Silakan coba lagi.',
    'something went wrong': 'Terjadi kesalahan. Silakan coba lagi.',
    'unknown error': 'Terjadi kesalahan yang tidak diketahui.',
  };

  static String toIndonesia(
    Object? rawMessage, {
    String fallback = 'Terjadi kesalahan. Silakan coba lagi.',
  }) {
    var message = rawMessage?.toString().trim() ?? '';

    if (message.isEmpty) {
      return fallback;
    }

    message = message
        .replaceFirst(
          RegExp(
            r'^(exception|api exception|apiexception):\s*',
            caseSensitive: false,
          ),
          '',
        )
        .trim();

    final normalizedMessage = message.toLowerCase();

    final exactTranslation = _exactMessages[normalizedMessage];

    if (exactTranslation != null) {
      return exactTranslation;
    }

    // Contoh:
    // "The email field is required."
    final requiredMatch = RegExp(
      r'^the (.+) field is required\.?$',
      caseSensitive: false,
    ).firstMatch(message);

    if (requiredMatch != null) {
      final fieldName = _translateFieldName(requiredMatch.group(1));
      return '$fieldName wajib diisi.';
    }

    // Contoh:
    // "The selected leave type is invalid."
    final invalidSelectionMatch = RegExp(
      r'^the selected (.+) is invalid\.?$',
      caseSensitive: false,
    ).firstMatch(message);

    if (invalidSelectionMatch != null) {
      final fieldName = _translateFieldName(invalidSelectionMatch.group(1));

      return '$fieldName yang dipilih tidak valid.';
    }

    if (normalizedMessage.contains('credentials')) {
      return 'Email atau kata sandi tidak sesuai.';
    }

    if (normalizedMessage.contains('unauthenticated')) {
      return 'Sesi login telah berakhir. Silakan login kembali.';
    }

    if (normalizedMessage.contains('unauthorized') ||
        normalizedMessage.contains('forbidden')) {
      return 'Anda tidak memiliki izin untuk mengakses data ini.';
    }

    if (normalizedMessage.contains('socketexception') ||
        normalizedMessage.contains('failed host lookup') ||
        normalizedMessage.contains('connection refused') ||
        normalizedMessage.contains('network is unreachable')) {
      return 'Tidak dapat terhubung ke server. '
          'Periksa koneksi internet Anda.';
    }

    if (normalizedMessage.contains('timed out') ||
        normalizedMessage.contains('timeout')) {
      return 'Koneksi terlalu lama. Silakan coba lagi.';
    }

    if (normalizedMessage.contains('server error') ||
        normalizedMessage.contains('status code 500')) {
      return 'Terjadi kesalahan pada server. Silakan coba lagi.';
    }

    return message;
  }

  static String _translateFieldName(String? rawField) {
    final field = rawField?.replaceAll('_', ' ').trim().toLowerCase() ?? 'Data';

    const fieldNames = {
      'email': 'Email',
      'password': 'Kata sandi',
      'password confirmation': 'Konfirmasi kata sandi',
      'name': 'Nama',
      'full name': 'Nama lengkap',
      'reason': 'Alasan',
      'start date': 'Tanggal mulai',
      'end date': 'Tanggal selesai',
      'apply days': 'Jumlah hari',
      'leave type': 'Jenis cuti',
      'leave type id': 'Jenis cuti',
      'attachment': 'Lampiran',
      'latitude': 'Latitude',
      'longitude': 'Longitude',
    };

    return fieldNames[field] ?? _capitalize(field);
  }

  static String _capitalize(String value) {
    if (value.isEmpty) {
      return 'Data';
    }

    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}
