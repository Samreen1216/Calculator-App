enum UnitCategory {
  length('Length'),
  mass('Mass'),
  temperature('Temperature'),
  speed('Speed'),
  area('Area'),
  volume('Volume');

  final String label;
  const UnitCategory(this.label);
}

class ConversionUnit {
  final String id;
  final String name;
  final String symbol;
  final double factorToBase;

  const ConversionUnit({
    required this.id,
    required this.name,
    required this.symbol,
    required this.factorToBase,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversionUnit && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class UnitConverterService {
  static final Map<UnitCategory, List<ConversionUnit>> unitsByCategory = {
    UnitCategory.length: const [
      ConversionUnit(id: 'm', name: 'Meters', symbol: 'm', factorToBase: 1.0),
      ConversionUnit(id: 'km', name: 'Kilometers', symbol: 'km', factorToBase: 1000.0),
      ConversionUnit(id: 'cm', name: 'Centimeters', symbol: 'cm', factorToBase: 0.01),
      ConversionUnit(id: 'mm', name: 'Millimeters', symbol: 'mm', factorToBase: 0.001),
      ConversionUnit(id: 'mi', name: 'Miles', symbol: 'mi', factorToBase: 1609.344),
      ConversionUnit(id: 'yd', name: 'Yards', symbol: 'yd', factorToBase: 0.9144),
      ConversionUnit(id: 'ft', name: 'Feet', symbol: 'ft', factorToBase: 0.3048),
      ConversionUnit(id: 'in', name: 'Inches', symbol: 'in', factorToBase: 0.0254),
    ],
    UnitCategory.mass: const [
      ConversionUnit(id: 'kg', name: 'Kilograms', symbol: 'kg', factorToBase: 1.0),
      ConversionUnit(id: 'g', name: 'Grams', symbol: 'g', factorToBase: 0.001),
      ConversionUnit(id: 'mg', name: 'Milligrams', symbol: 'mg', factorToBase: 0.000001),
      ConversionUnit(id: 'lb', name: 'Pounds', symbol: 'lb', factorToBase: 0.45359237),
      ConversionUnit(id: 'oz', name: 'Ounces', symbol: 'oz', factorToBase: 0.028349523),
    ],
    UnitCategory.temperature: const [
      ConversionUnit(id: 'c', name: 'Celsius', symbol: '°C', factorToBase: 1.0),
      ConversionUnit(id: 'f', name: 'Fahrenheit', symbol: '°F', factorToBase: 1.0),
      ConversionUnit(id: 'k', name: 'Kelvin', symbol: 'K', factorToBase: 1.0),
    ],
    UnitCategory.speed: const [
      ConversionUnit(id: 'kmh', name: 'Kilometers / hour', symbol: 'km/h', factorToBase: 0.27777778),
      ConversionUnit(id: 'ms', name: 'Meters / second', symbol: 'm/s', factorToBase: 1.0),
      ConversionUnit(id: 'mph', name: 'Miles / hour', symbol: 'mph', factorToBase: 0.44704),
      ConversionUnit(id: 'knot', name: 'Knots', symbol: 'kn', factorToBase: 0.514444),
    ],
    UnitCategory.area: const [
      ConversionUnit(id: 'sqm', name: 'Square Meters', symbol: 'm²', factorToBase: 1.0),
      ConversionUnit(id: 'sqkm', name: 'Square Kilometers', symbol: 'km²', factorToBase: 1000000.0),
      ConversionUnit(id: 'sqft', name: 'Square Feet', symbol: 'ft²', factorToBase: 0.092903),
      ConversionUnit(id: 'acre', name: 'Acres', symbol: 'ac', factorToBase: 4046.8564),
      ConversionUnit(id: 'ha', name: 'Hectares', symbol: 'ha', factorToBase: 10000.0),
    ],
    UnitCategory.volume: const [
      ConversionUnit(id: 'l', name: 'Liters', symbol: 'L', factorToBase: 1.0),
      ConversionUnit(id: 'ml', name: 'Milliliters', symbol: 'mL', factorToBase: 0.001),
      ConversionUnit(id: 'gal', name: 'Gallons (US)', symbol: 'gal', factorToBase: 3.78541),
      ConversionUnit(id: 'cup', name: 'Cups', symbol: 'cup', factorToBase: 0.24),
      ConversionUnit(id: 'floz', name: 'Fluid Ounces', symbol: 'fl oz', factorToBase: 0.0295735),
    ],
  };

  static double convert(double value, ConversionUnit from, ConversionUnit to, UnitCategory category) {
    if (from.id == to.id) return value;

    if (category == UnitCategory.temperature) {
      return _convertTemperature(value, from.id, to.id);
    }

    // Convert from -> base, then base -> to
    final double inBase = value * from.factorToBase;
    return inBase / to.factorToBase;
  }

  static double _convertTemperature(double value, String fromId, String toId) {
    // Convert to Celsius first
    double inCelsius;
    if (fromId == 'c') {
      inCelsius = value;
    } else if (fromId == 'f') {
      inCelsius = (value - 32.0) * 5.0 / 9.0;
    } else {
      inCelsius = value - 273.15;
    }

    // Convert from Celsius to target
    if (toId == 'c') {
      return inCelsius;
    } else if (toId == 'f') {
      return (inCelsius * 9.0 / 5.0) + 32.0;
    } else {
      return inCelsius + 273.15;
    }
  }

  static String format(double value) {
    if (value.isNaN) return 'Error';
    if (value == value.truncateToDouble() && value.abs() < 1e12) {
      return value.toInt().toString();
    }
    String str = value.toStringAsPrecision(8);
    if (str.contains('.')) {
      str = str.replaceAll(RegExp(r'0+$'), '');
      str = str.replaceAll(RegExp(r'\.$'), '');
    }
    return str;
  }
}
