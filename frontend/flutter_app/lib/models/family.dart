import 'package:flutter/material.dart';

/// A character a child can pick for their robot. The ids match `backend/codebud/family.py`.
class RobotCharacter {
  const RobotCharacter(this.id, this.label, this.icon);
  final String id;
  final String label;
  final IconData icon;

  static const all = [
    RobotCharacter('robot', 'Robo', Icons.smart_toy),
    RobotCharacter('rocket', 'Rocket', Icons.rocket_launch),
    RobotCharacter('bunny', 'Bunny', Icons.cruelty_free),
    RobotCharacter('bird', 'Birdie', Icons.flutter_dash),
    RobotCharacter('puppy', 'Puppy', Icons.pets),
    RobotCharacter('bee', 'Buzzy', Icons.emoji_nature),
  ];

  static RobotCharacter byId(String? id) => all.firstWhere((c) => c.id == id, orElse: () => all.first);
}

/// A robot colour. The ids match `backend/codebud/family.py`.
class RobotColor {
  const RobotColor(this.id, this.label, this.color);
  final String id;
  final String label;
  final Color color;

  static const all = [
    RobotColor('teal', 'Teal', Color(0xFF0D9488)),
    RobotColor('sky', 'Sky', Color(0xFF0284C7)),
    RobotColor('violet', 'Violet', Color(0xFF7C3AED)),
    RobotColor('pink', 'Pink', Color(0xFFDB2777)),
    RobotColor('red', 'Red', Color(0xFFE11D48)),
    RobotColor('orange', 'Orange', Color(0xFFEA580C)),
    RobotColor('yellow', 'Gold', Color(0xFFD97706)),
    RobotColor('lime', 'Lime', Color(0xFF65A30D)),
  ];

  static RobotColor byId(String? id) => all.firstWhere((c) => c.id == id, orElse: () => all.first);
}

/// How a child has customised their robot.
@immutable
class RobotLook {
  const RobotLook({this.character = 'robot', this.color = 'teal', this.nickname = ''});

  final String character;
  final String color;
  final String nickname;

  static const maxNickname = 20;

  RobotCharacter get characterInfo => RobotCharacter.byId(character);
  Color get colorValue => RobotColor.byId(color).color;
  IconData get icon => characterInfo.icon;

  /// The nickname, or the character's own name if the child hasn't picked one.
  String get displayName => nickname.isEmpty ? characterInfo.label : nickname;

  RobotLook copyWith({String? character, String? color, String? nickname}) => RobotLook(
        character: character ?? this.character,
        color: color ?? this.color,
        nickname: nickname ?? this.nickname,
      );

  factory RobotLook.fromJson(Map<String, dynamic>? j) => RobotLook(
        character: j?['character'] as String? ?? 'robot',
        color: j?['color'] as String? ?? 'teal',
        nickname: j?['nickname'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'character': character, 'color': color, 'nickname': nickname};

  @override
  bool operator ==(Object other) =>
      other is RobotLook && other.character == character && other.color == color && other.nickname == nickname;

  @override
  int get hashCode => Object.hash(character, color, nickname);
}

/// One child in the family.
@immutable
class Child {
  const Child({required this.id, required this.name, this.age, this.robot = const RobotLook()});

  final String id;
  final String name;
  final int? age;
  final RobotLook robot;

  static const minAge = 3;
  static const maxAge = 12;

  Child copyWith({String? name, int? age, RobotLook? robot}) =>
      Child(id: id, name: name ?? this.name, age: age ?? this.age, robot: robot ?? this.robot);

  factory Child.fromJson(Map<String, dynamic> j) => Child(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        age: j['age'] as int?,
        robot: RobotLook.fromJson(j['robot'] as Map<String, dynamic>?),
      );
}

/// The parent account, as returned by `GET /api/me`.
@immutable
class Family {
  const Family({required this.username, required this.children, this.parentName, this.email});

  final String username;
  final String? parentName;
  final String? email;
  final List<Child> children;

  static const maxChildren = 6;

  factory Family.fromJson(Map<String, dynamic> j) => Family(
        username: j['username'] as String? ?? '',
        parentName: j['parent_name'] as String?,
        email: j['email'] as String?,
        children: (j['children'] as List? ?? const []).map((c) => Child.fromJson(c as Map<String, dynamic>)).toList(),
      );

  Family copyWith({String? parentName, String? email, List<Child>? children}) => Family(
        username: username,
        parentName: parentName ?? this.parentName,
        email: email ?? this.email,
        children: children ?? this.children,
      );
}
