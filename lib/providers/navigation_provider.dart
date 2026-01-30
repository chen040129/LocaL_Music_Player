import 'package:flutter/material.dart';
import '../constants/app_pages.dart';

class NavigationProvider extends ChangeNotifier {
  AppPage _currentPage = AppPage.songs;
  String? _navigateToArtistName;
  String? _navigateToAlbumName;

  AppPage get currentPage => _currentPage;
  String? get navigateToArtistName => _navigateToArtistName;
  String? get navigateToAlbumName => _navigateToAlbumName;

  void navigateToArtist(String artistName) {
    _navigateToArtistName = artistName;
    _currentPage = AppPage.artists;
    notifyListeners();
  }

  void navigateToAlbum(String albumName) {
    _navigateToAlbumName = albumName;
    _currentPage = AppPage.albums;
    notifyListeners();
  }

  void changePage(AppPage page) {
    _currentPage = page;
    notifyListeners();
  }
}
