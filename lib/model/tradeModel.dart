class Trade {
  final String id;
  final DateTime tradeDate;
  final DateTime entryTime;
  final DateTime exitTime;
  final String direction;
  final String bigTimePeriod;
  final String smallTimePeriod;
  final double entryPrice;
  final double exitPrice;
  final double profitLossUSDT;
  final String entryReason;
  final String stopConditions;
  final double riskRewardRatio;
  final String reflection;
  final String? imageUrl; // 改為 File 類型

  Trade({
    required this.id,
    required this.tradeDate,
    required this.entryTime,
    required this.exitTime,
    required this.direction,
    required this.bigTimePeriod,
    required this.smallTimePeriod,
    required this.entryPrice,
    required this.exitPrice,
    required this.profitLossUSDT,
    required this.entryReason,
    required this.stopConditions,
    required this.riskRewardRatio,
    required this.reflection,
    this.imageUrl,
  });

  factory Trade.fromJson(Map<String, dynamic> json) {
    return Trade(
      id: json['id'],
      tradeDate: DateTime.parse(json['tradeDate']),
      entryTime: DateTime.parse(json['entryTime']),
      exitTime: DateTime.parse(json['exitTime']),
      direction: json['direction'],
      bigTimePeriod: json['bigTimePeriod'],
      smallTimePeriod: json['smallTimePeriod'],
      entryPrice: json['entryPrice'].toDouble(),
      exitPrice: json['exitPrice'].toDouble(),
      profitLossUSDT: json['profitLossUSDT'].toDouble(),
      entryReason: json['entryReason'],
      stopConditions: json['stopConditions'],
      riskRewardRatio: json['riskRewardRatio'].toDouble(),
      reflection: json['reflection'],
      imageUrl: json['imageUrl'],
    );
  }

  Trade copyWith({
    String? id,
    DateTime? tradeDate,
    DateTime? entryTime,
    DateTime? exitTime,
    String? direction,
    String? bigTimePeriod,
    String? smallTimePeriod,
    double? entryPrice,
    double? exitPrice,
    double? profitLossUSDT,
    String? entryReason,
    String? stopConditions,
    double? riskRewardRatio,
    String? reflection,
    String? imageUrl, // 改為 File 類型
  }) {
    return Trade(
      id: id ?? this.id,
      tradeDate: tradeDate ?? this.tradeDate,
      entryTime: entryTime ?? this.entryTime,
      exitTime: exitTime ?? this.exitTime,
      direction: direction ?? this.direction,
      bigTimePeriod: bigTimePeriod ?? this.bigTimePeriod,
      smallTimePeriod: smallTimePeriod ?? this.smallTimePeriod,
      entryPrice: entryPrice ?? this.entryPrice,
      exitPrice: exitPrice ?? this.exitPrice,
      profitLossUSDT: profitLossUSDT ?? this.profitLossUSDT,
      entryReason: entryReason ?? this.entryReason,
      stopConditions: stopConditions ?? this.stopConditions,
      riskRewardRatio: riskRewardRatio ?? this.riskRewardRatio,
      reflection: reflection ?? this.reflection,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tradeDate': tradeDate.toIso8601String(),
      'entryTime': entryTime.toIso8601String(),
      'exitTime': exitTime.toIso8601String(),
      'direction': direction,
      'bigTimePeriod': bigTimePeriod,
      'smallTimePeriod': smallTimePeriod,
      'entryPrice': entryPrice,
      'exitPrice': exitPrice,
      'profitLossUSDT': profitLossUSDT,
      'entryReason': entryReason,
      'stopConditions': stopConditions,
      'riskRewardRatio': riskRewardRatio,
      'reflection': reflection,
      'imageUrl': imageUrl,
    };
  }
}
