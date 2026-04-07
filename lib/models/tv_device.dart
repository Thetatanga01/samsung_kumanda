class TVDevice {
  final String ip;
  final String name;
  final String token;

  const TVDevice({required this.ip, required this.name, required this.token});

  String get wsUrl =>
      'ws://$ip:8001/api/v2/channels/samsung.remote.control';

  factory TVDevice.fromJson(Map<String, dynamic> json) => TVDevice(
        ip: json['ip'] as String,
        name: json['name'] as String? ?? 'Samsung TV',
        token: json['token'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'ip': ip,
        'name': name,
        'token': token,
      };

  TVDevice copyWith({String? token}) =>
      TVDevice(ip: ip, name: name, token: token ?? this.token);
}
