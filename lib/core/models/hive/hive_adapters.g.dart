// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_adapters.dart';

// **************************************************************************
// AdaptersGenerator
// **************************************************************************

class ScreenshotEntryAdapter extends TypeAdapter<ScreenshotEntry> {
  @override
  final typeId = 0;

  @override
  ScreenshotEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScreenshotEntry(
      assetId: fields[0] as String,
      createdAt: fields[1] as DateTime,
      category: fields[2] as ScreenshotCategory?,
      tags: fields[3] == null ? const [] : (fields[3] as List).cast<String>(),
      ocrText: fields[4] as String?,
      analyzedAt: fields[5] as DateTime?,
      boardId: fields[6] as String?,
      aiCategory: fields[7] as ScreenshotCategory?,
    );
  }

  @override
  void write(BinaryWriter writer, ScreenshotEntry obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.assetId)
      ..writeByte(1)
      ..write(obj.createdAt)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.tags)
      ..writeByte(4)
      ..write(obj.ocrText)
      ..writeByte(5)
      ..write(obj.analyzedAt)
      ..writeByte(6)
      ..write(obj.boardId)
      ..writeByte(7)
      ..write(obj.aiCategory);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScreenshotEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BoardAdapter extends TypeAdapter<Board> {
  @override
  final typeId = 1;

  @override
  Board read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Board(
      id: fields[0] as String,
      name: fields[1] as String,
      createdAt: fields[2] as DateTime,
      sortOrder: fields[3] == null ? 0 : (fields[3] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, Board obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.sortOrder);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoardAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ScreenshotCategoryAdapter extends TypeAdapter<ScreenshotCategory> {
  @override
  final typeId = 2;

  @override
  ScreenshotCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ScreenshotCategory.lockScreen;
      case 1:
        return ScreenshotCategory.social;
      case 2:
        return ScreenshotCategory.shopping;
      case 3:
        return ScreenshotCategory.notesPasswords;
      case 4:
        return ScreenshotCategory.messages;
      case 5:
        return ScreenshotCategory.receipts;
      case 6:
        return ScreenshotCategory.other;
      case 7:
        return ScreenshotCategory.qrCodes;
      case 8:
        return ScreenshotCategory.recipes;
      case 9:
        return ScreenshotCategory.places;
      case 10:
        return ScreenshotCategory.inspiration;
      case 11:
        return ScreenshotCategory.memes;
      case 12:
        return ScreenshotCategory.outfits;
      case 13:
        return ScreenshotCategory.health;
      case 14:
        return ScreenshotCategory.tickets;
      case 15:
        return ScreenshotCategory.travel;
      case 16:
        return ScreenshotCategory.food;
      case 17:
        return ScreenshotCategory.finance;
      case 18:
        return ScreenshotCategory.documents;
      case 19:
        return ScreenshotCategory.education;
      case 20:
        return ScreenshotCategory.entertainment;
      default:
        return ScreenshotCategory.lockScreen;
    }
  }

  @override
  void write(BinaryWriter writer, ScreenshotCategory obj) {
    switch (obj) {
      case ScreenshotCategory.lockScreen:
        writer.writeByte(0);
      case ScreenshotCategory.social:
        writer.writeByte(1);
      case ScreenshotCategory.shopping:
        writer.writeByte(2);
      case ScreenshotCategory.notesPasswords:
        writer.writeByte(3);
      case ScreenshotCategory.messages:
        writer.writeByte(4);
      case ScreenshotCategory.receipts:
        writer.writeByte(5);
      case ScreenshotCategory.other:
        writer.writeByte(6);
      case ScreenshotCategory.qrCodes:
        writer.writeByte(7);
      case ScreenshotCategory.recipes:
        writer.writeByte(8);
      case ScreenshotCategory.places:
        writer.writeByte(9);
      case ScreenshotCategory.inspiration:
        writer.writeByte(10);
      case ScreenshotCategory.memes:
        writer.writeByte(11);
      case ScreenshotCategory.outfits:
        writer.writeByte(12);
      case ScreenshotCategory.health:
        writer.writeByte(13);
      case ScreenshotCategory.tickets:
        writer.writeByte(14);
      case ScreenshotCategory.travel:
        writer.writeByte(15);
      case ScreenshotCategory.food:
        writer.writeByte(16);
      case ScreenshotCategory.finance:
        writer.writeByte(17);
      case ScreenshotCategory.documents:
        writer.writeByte(18);
      case ScreenshotCategory.education:
        writer.writeByte(19);
      case ScreenshotCategory.entertainment:
        writer.writeByte(20);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScreenshotCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
