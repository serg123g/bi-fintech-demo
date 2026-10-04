import 'package:equatable/equatable.dart';

import 'customer_segment.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.segment,
  });

  final String id;
  final String email;
  final String fullName;
  final CustomerSegment segment;

  String get firstName => fullName.trim().split(RegExp(r'\s+')).first;

  @override
  List<Object?> get props => [id, email, fullName, segment];
}
