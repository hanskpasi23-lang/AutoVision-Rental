class Vehicle {
  final int id;
  final String make;
  final String model;
  final int year;
  final double dailyRate;
  final String status;
  final String? imageUrl;

  Vehicle({
    required this.id,
    required this.make,
    required this.model,
    required this.year,
    required this.dailyRate,
    required this.status,
    this.imageUrl,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'],
      make: json['make'],
      model: json['model'],
      year: json['year'],
      dailyRate: (json['daily_rate'] ?? 0.0).toDouble(),
      status: json['status'],
      imageUrl: json['image_url'],
    );
  }
}
