import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Hive Type Adapters for IconData and Color
class IconDataAdapter extends TypeAdapter<IconData> {
  @override
  final int typeId = 2;

  @override
  IconData read(BinaryReader reader) {
    final codePoint = reader.readInt();
    return IconData(codePoint, fontFamily: 'MaterialIcons');
  }

  @override
  void write(BinaryWriter writer, IconData obj) {
    writer.writeInt(obj.codePoint);
  }
}

class ColorAdapter extends TypeAdapter<Color> {
  @override
  final int typeId = 3;

  @override
  Color read(BinaryReader reader) {
    final value = reader.readInt();
    return Color(value);
  }

  @override
  void write(BinaryWriter writer, Color obj) {
    // Convert Color to ARGB32 integer
    final argb = (obj.a.toInt() << 24) |
                 (obj.r.toInt() << 16) |
                 (obj.g.toInt() << 8) |
                 obj.b.toInt();
    writer.writeInt(argb);
  }
}

