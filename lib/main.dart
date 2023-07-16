import 'dart:developer';

import 'package:audio_player/nowPlaying.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> main() async {
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Beats_Player",
      theme: ThemeData.dark(),
      home: AllSongs(),
    );
  }
}

class AllSongs extends StatefulWidget {
  const AllSongs({Key? key}) : super(key: key);

  @override
  State<AllSongs> createState() => _AllSongsState();
}

class _AllSongsState extends State<AllSongs> {
  final _audioQuery = OnAudioQuery();
  final AudioPlayer _audioPlayer = AudioPlayer();
  late List<SongModel> _songs;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    requestPermission();
    loadSongs();
  }

  void requestPermission() {
    Permission.storage.request();
  }

  void loadSongs() async {
    final songs = await _audioQuery.querySongs(
      sortType: null,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );
    setState(() {
      _songs = songs;
    });
  }

  void playSong(int index) {
    final song = _songs[index];
    try {
      _audioPlayer.setAudioSource(
        AudioSource.uri(
          Uri.parse(song.uri!),
          tag: MediaItem(
            id: '${song.id}',
            album: "${song.album}",
            title: song.displayNameWOExt,
            artUri: Uri.parse('https://example.com/albumart.jpg'),
          ),
        ),
      );
      _audioPlayer.play();
      _currentIndex = index;
    } on Exception {
      log("Error Parsing Song");
    }
  }

  void playNextSong() {
    if (_currentIndex < _songs.length - 1) {
      playSong(_currentIndex + 1);
    }
  }

  void playPreviousSong() {
    if (_currentIndex > 0) {
      playSong(_currentIndex - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_songs == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_songs.isEmpty) {
      return const Center(child: Text("No Songs Found"));
    }

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Beats Music Player"),
          backgroundColor: Colors.blue,
          actions: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.search),
            ),
          ],
        ),
        body: ListView.builder(
          itemCount: _songs.length,
          itemBuilder: (context, index) {
            final song = _songs[index];
            return ListTile(
              title: Text(song.displayNameWOExt),
              subtitle: Text(song.artist.toString()),
              trailing: const Icon(Icons.more_horiz),
              leading: const CircleAvatar(
                child: Icon(Icons.music_note,color: Colors.blue),
              ),
              onTap: () {
                playSong(index);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NowPlaying(
                      songName: song,
                      audioPlayer: _audioPlayer,
                      onNext: playNextSong,
                      onPrevious: playPreviousSong, songList: [],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}