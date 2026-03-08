/// Real-time bot event from WebSocket.
class BotEvent {
  final String type;
  final String botId;
  final int userId;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  const BotEvent({
    required this.type,
    required this.botId,
    required this.userId,
    required this.timestamp,
    this.data,
  });

  factory BotEvent.fromJson(Map<String, dynamic> json) => BotEvent(
    type: json['type'] as String,
    botId: json['botId'] as String,
    userId: json['userId'] as int,
    timestamp: DateTime.parse(json['timestamp'] as String),
    data: json['data'] as Map<String, dynamic>?,
  );

  bool get isPositionOpened => type == 'position:opened';
  bool get isPositionClosed => type == 'position:closed';
  bool get isBotStarted => type == 'engine:started';
  bool get isBotStopped => type == 'engine:stopped';
  bool get isBotError => type == 'engine:error';
  bool get isScanCompleted => type == 'scan:completed';
}
