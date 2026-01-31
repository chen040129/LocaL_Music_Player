
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// 歌单模型
class PlaylistModel {
  final String id;
  final String name;
  final List<String> musicIds; // 存储音乐ID列表
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? color; // 歌单颜色，使用ARGB格式存储

  PlaylistModel({
    required this.id,
    required this.name,
    required this.musicIds,
    required this.createdAt,
    required this.updatedAt,
    this.color,
  });

  /// 创建歌单
  factory PlaylistModel.create(String name, {List<String>? musicIds, int? color}) {
    return PlaylistModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      musicIds: musicIds ?? [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      color: color,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'musicIds': musicIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'color': color,
    };
  }

  /// 从JSON创建
  factory PlaylistModel.fromJson(Map<String, dynamic> json) {
    return PlaylistModel(
      id: json['id'],
      name: json['name'],
      musicIds: List<String>.from(json['musicIds'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      color: json['color'],
    );
  }

  /// 添加音乐到歌单
  PlaylistModel addMusic(String musicId) {
    if (musicIds.contains(musicId)) {
      return this;
    }
    return PlaylistModel(
      id: id,
      name: name,
      musicIds: [...musicIds, musicId],
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      color: color,
    );
  }

  /// 从歌单移除音乐
  PlaylistModel removeMusic(String musicId) {
    return PlaylistModel(
      id: id,
      name: name,
      musicIds: musicIds.where((id) => id != musicId).toList(),
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      color: color,
    );
  }

  /// 更新歌单名称
  PlaylistModel updateName(String newName) {
    return PlaylistModel(
      id: id,
      name: newName,
      musicIds: musicIds,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      color: color,
    );
  }

  /// 更新歌单颜色
  PlaylistModel updateColor(int? newColor) {
    return PlaylistModel(
      id: id,
      name: name,
      musicIds: musicIds,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      color: newColor,
    );
  }
}

/// 歌单服务
class PlaylistService extends ChangeNotifier {
  static const String _playlistsFileName = 'playlists.json';

  final List<PlaylistModel> _playlists = [];
  bool _isLoading = false;

  /// 获取所有歌单
  List<PlaylistModel> get playlists => List.unmodifiable(_playlists);

  /// 是否正在加载
  bool get isLoading => _isLoading;

  /// 根据ID获取歌单
  PlaylistModel? getPlaylistById(String id) {
    try {
      return _playlists.firstWhere((playlist) => playlist.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 创建歌单
  Future<PlaylistModel> createPlaylist(String name, {List<String>? musicIds}) async {
    final playlist = PlaylistModel.create(name, musicIds: musicIds);
    _playlists.add(playlist);
    await _savePlaylists();
    notifyListeners();
    return playlist;
  }

  /// 更新歌单
  Future<void> updatePlaylist(PlaylistModel updatedPlaylist) async {
    final index = _playlists.indexWhere((p) => p.id == updatedPlaylist.id);
    if (index != -1) {
      _playlists[index] = updatedPlaylist;
      await _savePlaylists();
      notifyListeners();
    }
  }

  /// 删除歌单
  Future<void> deletePlaylist(String id) async {
    _playlists.removeWhere((playlist) => playlist.id == id);
    await _savePlaylists();
    notifyListeners();
  }

  /// 添加音乐到歌单
  Future<void> addMusicToPlaylist(String playlistId, String musicId) async {
    final playlist = getPlaylistById(playlistId);
    if (playlist != null) {
      final updatedPlaylist = playlist.addMusic(musicId);
      await updatePlaylist(updatedPlaylist);
    }
  }

  /// 从歌单移除音乐
  Future<void> removeMusicFromPlaylist(String playlistId, String musicId) async {
    final playlist = getPlaylistById(playlistId);
    if (playlist != null) {
      final updatedPlaylist = playlist.removeMusic(musicId);
      await updatePlaylist(updatedPlaylist);
    }
  }

  /// 加载歌单数据
  Future<void> loadPlaylists() async {
    try {
      _isLoading = true;
      notifyListeners();

      final directory = await _getAppDirectory();
      final file = File('${directory.path}/$_playlistsFileName');

      if (!await file.exists()) {
        debugPrint('未找到本地歌单数据文件');
        _isLoading = false;
        notifyListeners();
        return;
      }

      final jsonData = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(jsonData);

      _playlists.clear();
      _playlists.addAll(
        jsonList.map((json) => PlaylistModel.fromJson(json as Map<String, dynamic>)),
      );

      debugPrint('已从本地加载 ${_playlists.length} 个歌单');
    } catch (e) {
      debugPrint('加载歌单数据失败: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 保存歌单数据
  Future<void> _savePlaylists() async {
    try {
      final directory = await _getAppDirectory();
      final file = File('${directory.path}/$_playlistsFileName');

      final jsonData = jsonEncode(
        _playlists.map((playlist) => playlist.toJson()).toList(),
      );
      await file.writeAsString(jsonData);

      debugPrint('歌单数据已保存到本地');
    } catch (e) {
      debugPrint('保存歌单数据失败: $e');
    }
  }

  /// 获取应用数据目录
  Future<Directory> _getAppDirectory() async {
    if (kIsWeb) {
      return Directory.systemTemp;
    }

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return await getApplicationSupportDirectory();
    }

    return await getApplicationDocumentsDirectory();
  }
}
