import 'package:flutter/material.dart';
import 'scan_storage_service.dart';

class SessionService extends ChangeNotifier {
  // Singleton Pattern
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  // Sesi default yang aktif saat aplikasi pertama kali dibuka
  String _currentSession = 'Sesi Utama';

  String get currentSession => _currentSession;

  /// 1. MENGAMBIL DAFTAR SEMUA SESI (Gabungan dari database + default)
  List<String> getAvailableSessions() {
    // Mengambil daftar nama sesi yang sudah terekam di Hive melalui ScanStorageService kamu
    final savedSessions = ScanStorageService.sessions;
    
    // Pastikan sesi default atau sesi aktif saat ini selalu masuk ke dalam daftar pilhan
    final Set<String> allSessions = {_currentSession, 'Sesi Utama', ...savedSessions};
    
    final sortedList = allSessions.toList();
    sortedList.sort();
    return sortedList;
  }

  /// 2. MENGUBAH SESI AKTIF SAAT INI
  void changeSession(String newSession) {
    if (newSession.trim().isEmpty) return;
    
    _currentSession = newSession.trim();
    
    // Beritahu UI (Consumer/Provider) untuk memperbarui tampilan dropdown sesi jika ada perubahan
    notifyListeners();
  }

  /// 3. MEMBUAT SESI BARU
  /// Digunakan ketika user memilih opsi "Tambah Sesi Baru" di dialog popup UI
  void createNewSession(String sessionName) {
    if (sessionName.trim().isEmpty) return;
    
    _currentSession = sessionName.trim();
    
    // Notifikasi UI untuk merender dropdown dengan pilihan baru yang otomatis terpilih
    notifyListeners();
  }
}
