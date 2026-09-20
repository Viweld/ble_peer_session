import 'dart:typed_data';

import '../domain/exceptions/peer_exception.dart';

/// Splits logical messages into BLE-sized frames and reassembles them on receive.
///
/// Wire layout (big-endian):
/// ```
/// [version:1][flags:1][messageId:2][chunkIndex:2][totalChunks:2][payload…]
/// ```
final class BleFrameCodec {
  const BleFrameCodec({
    this.maxChunkPayloadSize = defaultMaxChunkPayloadSize,
    this.maxMessageSize = defaultMaxMessageSize,
  });

  static const int protocolVersion = 0x01;
  static const int headerSize = 8;
  static const int defaultMaxChunkPayloadSize = 480;
  static const int defaultMaxMessageSize = 256 * 1024;

  final int maxChunkPayloadSize;
  final int maxMessageSize;

  /// Splits [message] into one or more frames sharing the same [messageId].
  List<Uint8List> fragment(Uint8List message, {required int messageId}) {
    if (message.length > maxMessageSize) {
      throwPeer(PeerErrorCode.payloadTooLarge);
    }

    if (message.isEmpty) {
      return <Uint8List>[
        _buildFrame(
          messageId: messageId,
          chunkIndex: 0,
          totalChunks: 1,
          payload: message,
        ),
      ];
    }

    final int totalChunks =
        (message.length + maxChunkPayloadSize - 1) ~/ maxChunkPayloadSize;
    if (totalChunks > 0xFFFF) {
      throwPeer(PeerErrorCode.payloadTooLarge);
    }

    final List<Uint8List> frames = <Uint8List>[];
    for (var chunkIndex = 0; chunkIndex < totalChunks; chunkIndex++) {
      final int start = chunkIndex * maxChunkPayloadSize;
      final int end = (start + maxChunkPayloadSize).clamp(0, message.length);
      frames.add(
        _buildFrame(
          messageId: messageId,
          chunkIndex: chunkIndex,
          totalChunks: totalChunks,
          payload: message.sublist(start, end),
        ),
      );
    }
    return frames;
  }

  /// Parses a single frame header. Returns null when [data] is too short.
  BleFrameHeader? readHeader(Uint8List data) {
    if (data.length < headerSize) {
      return null;
    }

    if (data[0] != protocolVersion) {
      return null;
    }

    return BleFrameHeader(
      messageId: _readUint16(data, 2),
      chunkIndex: _readUint16(data, 4),
      totalChunks: _readUint16(data, 6),
      payloadLength: data.length - headerSize,
    );
  }

  Uint8List payloadFromFrame(Uint8List frame) {
    if (frame.length <= headerSize) {
      return Uint8List(0);
    }
    return frame.sublist(headerSize);
  }

  Uint8List _buildFrame({
    required int messageId,
    required int chunkIndex,
    required int totalChunks,
    required Uint8List payload,
  }) {
    final Uint8List frame = Uint8List(headerSize + payload.length);
    frame[0] = protocolVersion;
    frame[1] = 0;
    _writeUint16(frame, 2, messageId);
    _writeUint16(frame, 4, chunkIndex);
    _writeUint16(frame, 6, totalChunks);
    frame.setRange(headerSize, frame.length, payload);
    return frame;
  }

  static int _readUint16(Uint8List data, int offset) {
    return (data[offset] << 8) | data[offset + 1];
  }

  static void _writeUint16(Uint8List data, int offset, int value) {
    data[offset] = (value >> 8) & 0xFF;
    data[offset + 1] = value & 0xFF;
  }
}

final class BleFrameHeader {
  const BleFrameHeader({
    required this.messageId,
    required this.chunkIndex,
    required this.totalChunks,
    required this.payloadLength,
  });

  final int messageId;
  final int chunkIndex;
  final int totalChunks;
  final int payloadLength;
}

/// Accumulates frame payloads until a full logical message is ready.
final class BleFrameAssembler {
  BleFrameAssembler({BleFrameCodec codec = const BleFrameCodec()})
    : _codec = codec;

  final BleFrameCodec _codec;
  final Map<int, _PartialMessage> _partials = <int, _PartialMessage>{};

  /// Adds [frame]. Returns the reassembled message when complete.
  Uint8List? addFrame(Uint8List frame) {
    final BleFrameHeader? header = _codec.readHeader(frame);
    if (header == null) {
      return frame;
    }

    if (header.totalChunks == 0 ||
        header.chunkIndex >= header.totalChunks ||
        header.totalChunks > 0xFFFF) {
      throwPeer(PeerErrorCode.messageDecodeFailed);
    }

    final Uint8List payload = _codec.payloadFromFrame(frame);
    final _PartialMessage partial = _partials.putIfAbsent(
      header.messageId,
      () => _PartialMessage(totalChunks: header.totalChunks),
    );

    if (partial.totalChunks != header.totalChunks) {
      _partials.remove(header.messageId);
      throwPeer(PeerErrorCode.messageDecodeFailed);
    }

    partial.chunks[header.chunkIndex] = payload;

    if (!partial.isComplete) {
      return null;
    }

    _partials.remove(header.messageId);
    return partial.join();
  }

  void reset() => _partials.clear();
}

final class _PartialMessage {
  _PartialMessage({required this.totalChunks});

  final int totalChunks;
  final Map<int, Uint8List> chunks = <int, Uint8List>{};

  bool get isComplete => chunks.length == totalChunks;

  Uint8List join() {
    final BytesBuilder builder = BytesBuilder(copy: false);
    for (var index = 0; index < totalChunks; index++) {
      final Uint8List? chunk = chunks[index];
      if (chunk == null) {
        throwPeer(PeerErrorCode.messageDecodeFailed);
      }
      builder.add(chunk);
    }
    return builder.takeBytes();
  }
}
