class Note {
  final int pitch;
  final double startTime;
  final double duration;
  final int velocity;

  const Note({
    required this.pitch,
    required this.startTime,
    required this.duration,
    this.velocity = 100,
  });

  Note copyWith({
    int? pitch,
    double? startTime,
    double? duration,
    int? velocity,
  }) {
    return Note(
      pitch: pitch ?? this.pitch,
      startTime: startTime ?? this.startTime,
      duration: duration ?? this.duration,
      velocity: velocity ?? this.velocity,
    );
  }

  Map<String, dynamic> toJson() => {
        'pitch': pitch,
        'startTime': startTime,
        'duration': duration,
        'velocity': velocity,
      };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        pitch: json['pitch'] as int? ?? 60,
        startTime: (json['startTime'] as num?)?.toDouble() ?? 0,
        duration: (json['duration'] as num?)?.toDouble() ?? 1,
        velocity: json['velocity'] as int? ?? 100,
      );
}
