// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timetable.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ClassSessionAdapter extends TypeAdapter<ClassSession> {
  @override
  final int typeId = 8;

  @override
  ClassSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ClassSession(
      id: fields[0] as String,
      subjectName: fields[1] as String,
      professorName: fields[2] as String?,
      roomNumber: fields[3] as String?,
      startTimeHour: fields[4] as int,
      startTimeMinute: fields[5] as int,
      endTimeHour: fields[6] as int,
      endTimeMinute: fields[7] as int,
      dayOfWeek: fields[8] as int,
      colorValue: fields[9] as int,
    );
  }

  @override
  void write(BinaryWriter writer, ClassSession obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.subjectName)
      ..writeByte(2)
      ..write(obj.professorName)
      ..writeByte(3)
      ..write(obj.roomNumber)
      ..writeByte(4)
      ..write(obj.startTimeHour)
      ..writeByte(5)
      ..write(obj.startTimeMinute)
      ..writeByte(6)
      ..write(obj.endTimeHour)
      ..writeByte(7)
      ..write(obj.endTimeMinute)
      ..writeByte(8)
      ..write(obj.dayOfWeek)
      ..writeByte(9)
      ..write(obj.colorValue);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClassSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
