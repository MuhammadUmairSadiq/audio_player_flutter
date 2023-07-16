import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';

class NowPlaying extends StatefulWidget {
  NowPlaying({
    Key? key,
    required this.songName,
    required this.audioPlayer,
    required this.onNext,
    required this.onPrevious,
    required this.songList, // Added songList parameter
  }) : super(key: key);

  SongModel songName;
  final AudioPlayer audioPlayer;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final List<SongModel> songList; // Added songList

  @override
  State<NowPlaying> createState() => _NowPlayingState();
}

class _NowPlayingState extends State<NowPlaying> {
  Duration _duration = const Duration();
  Duration _position = const Duration();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    playSong();
  }

  void playSong() {
    try {
      widget.audioPlayer.setAudioSource(
        AudioSource.uri(
          Uri.parse(widget.songName.uri!),
          tag: MediaItem(
            id: '${widget.songName.id}',
            album: "${widget.songName.album}",
            title: widget.songName.displayNameWOExt,
            artUri: Uri.parse('https://example.com/albumart.jpg'),
          ),
        ),
      );
      widget.audioPlayer.play();
      _isPlaying = true;
    } on Exception {
      log("Error Parsing Song");
    }

    widget.audioPlayer.durationStream.listen((d) {
      setState(() {
        _duration = d!;
      });
    });
    widget.audioPlayer.positionStream.listen((p) {
      setState(() {
        _position = p!;
      });
    });
  }

  void updateSong(final song) {
    setState(() {
      widget.songName = song;
    });
  }

  @override
  Widget build(BuildContext context) {
    int currentIndex = widget.songList.indexOf(widget.songName); // Get the current song index
    return SafeArea(
      child: Scaffold(
        body: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back_ios),
              ),
              const SizedBox(
                height: 50.0,
              ),
              Center(
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 100.0,
                      child: Icon(Icons.music_note, size: 100.0, color: Colors.blue),
                    ),
                    const SizedBox(
                      height: 30.0,
                    ),
                    Text(
                      widget.songName.displayNameWOExt,
                      overflow: TextOverflow.fade,
                      maxLines: 2,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 30.0,
                      ),
                    ),
                    const SizedBox(
                      height: 15.0,
                    ),
                    Text(
                      widget.songName.artist.toString() == "<unknown>"
                          ? "Unknown Artist"
                          : widget.songName.artist.toString(),
                      overflow: TextOverflow.fade,
                      maxLines: 1,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20.0,
                      ),
                    ),
                    const SizedBox(
                      height: 15.0,
                    ),
                    Row(
                      children: [
                        Text(_position.toString().split(".")[0]),
                        Expanded(
                          child: Slider(
                            min: Duration(microseconds: 0).inSeconds.toDouble(),
                            value: _position.inSeconds.toDouble(),
                            max: _duration.inSeconds.toDouble(),
                            onChanged: (value) {
                              setState(() {
                                changeToSeconds(value.toInt());
                                value = value;
                              });
                            },
                          ),
                        ),
                        Text(_duration.toString().split(".")[0]),
                      ],
                    ),
                    const SizedBox(
                      height: 15.0,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        IconButton(
                          onPressed: () {
                            widget.onPrevious();
                            // Call updateSong to update the songName when previous icon is pressed
                            int previousIndex = currentIndex - 1;
                            if (previousIndex < 0) {
                              // If it goes below 0, wrap around to the last song
                              previousIndex = widget.songList.length - 1;
                            }
                            SongModel previousSong = widget.songList[previousIndex];
                            updateSong(previousSong);
                          },
                          icon: const Icon(Icons.skip_previous, size: 40.0),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              if (_isPlaying) {
                                widget.audioPlayer.pause();
                              } else {
                                widget.audioPlayer.play();
                              }
                              _isPlaying = !_isPlaying;
                            });
                          },
                          icon: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            size: 40.0,
                            color: Colors.orangeAccent,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            widget.onNext();
                            // Call updateSong to update the songName when next icon is pressed
                            int nextIndex = currentIndex + 1;
                            if (nextIndex >= widget.songList.length) {
                              // If it exceeds the list length, wrap around to the first song
                              nextIndex = 0;
                            }
                            SongModel nextSong = widget.songList[nextIndex];
                            updateSong(nextSong);
                          },
                          icon: const Icon(Icons.skip_next, size: 40.0),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void changeToSeconds(int seconds) {
    Duration duration = Duration(seconds: seconds);
    widget.audioPlayer.seek(duration);
  }
}

