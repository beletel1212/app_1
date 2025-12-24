// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_contact.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveContactAdapter extends TypeAdapter<HiveContact> {
  @override
  final int typeId = 0;

  @override
  HiveContact read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveContact(
      name: fields[0] as String,
      uid: fields[1] as String,
      profilePic: fields[2] as String,
      isOnline: fields[3] as bool,
      phoneNumber: fields[4] as String,
      groupId: (fields[5] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, HiveContact obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.uid)
      ..writeByte(2)
      ..write(obj.profilePic)
      ..writeByte(3)
      ..write(obj.isOnline)
      ..writeByte(4)
      ..write(obj.phoneNumber)
      ..writeByte(5)
      ..write(obj.groupId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveContactAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
