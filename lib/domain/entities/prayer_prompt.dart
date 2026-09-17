import 'package:equatable/equatable.dart';

class PrayerPrompt extends Equatable {
  final String id;
  final String title;
  final String text;
  final String category;

  const PrayerPrompt(this.id, this.title, this.text, this.category);

  @override
  List<Object?> get props => [id, title, text, category];
}
