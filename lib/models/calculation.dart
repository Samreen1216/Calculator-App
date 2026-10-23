class Calculation {
  final String expression;
  final String result;
  final DateTime timestamp;
  final String? category;
  final String? fromUnit;
  final String? toUnit;
  final String? inputValue;
  final String? outputValue;
  final bool isConversion;

  const Calculation({
    required this.expression,
    required this.result,
    required this.timestamp,
    this.category,
    this.fromUnit,
    this.toUnit,
    this.inputValue,
    this.outputValue,
    this.isConversion = false,
  });

  Map<String, dynamic> toJson() => {
        'expression': expression,
        'result': result,
        'timestamp': timestamp.toIso8601String(),
        if (category != null) 'category': category,
        if (fromUnit != null) 'fromUnit': fromUnit,
        if (toUnit != null) 'toUnit': toUnit,
        if (inputValue != null) 'inputValue': inputValue,
        if (outputValue != null) 'outputValue': outputValue,
        if (isConversion) 'isConversion': isConversion,
      };

  factory Calculation.fromJson(Map<String, dynamic> json) => Calculation(
        expression: json['expression'] as String,
        result: json['result'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        category: json['category'] as String?,
        fromUnit: json['fromUnit'] as String?,
        toUnit: json['toUnit'] as String?,
        inputValue: json['inputValue'] as String?,
        outputValue: json['outputValue'] as String?,
        isConversion: json['isConversion'] as bool? ?? false,
      );

  @override
  String toString() => '$expression = $result';
}
