class Lyric {
  final Duration time;
  final String text;

  Lyric({required this.time, required this.text});

  factory Lyric.fromJson(Map<String, dynamic> json) {
    return Lyric(
      time: Duration(milliseconds: json['time_ms'] ?? 0),
      text: json['text'] ?? '',
    );
  }
}