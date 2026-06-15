import 'dart:typed_data';

import 'package:ble_peer_session/src/codec/ble_frame_codec.dart';
import 'package:ble_peer_session/src/domain/exceptions/peer_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const codec = BleFrameCodec(maxChunkPayloadSize: 10, maxMessageSize: 100);

  group('BleFrameCodec.fragment', () {
    test('single-chunk message roundtrip', () {
      final Uint8List message = Uint8List.fromList(List<int>.generate(5, (int i) => i));
      final List<Uint8List> frames = codec.fragment(message, messageId: 1);

      expect(frames, hasLength(1));
      expect(frames.first[0], BleFrameCodec.protocolVersion);
      expect(frames.first[4], 0);
      expect(frames.first[5], 0);
      expect(frames.first[6], 0);
      expect(frames.first[7], 1);

      final BleFrameAssembler assembler = BleFrameAssembler(codec: codec);
      expect(assembler.addFrame(frames.first), message);
    });

    test('multi-chunk message roundtrip', () {
      final Uint8List message = Uint8List.fromList(List<int>.generate(25, (int i) => i));
      final List<Uint8List> frames = codec.fragment(message, messageId: 42);

      expect(frames, hasLength(3));

      final BleFrameAssembler assembler = BleFrameAssembler(codec: codec);
      expect(assembler.addFrame(frames[0]), isNull);
      expect(assembler.addFrame(frames[2]), isNull);
      expect(assembler.addFrame(frames[1]), message);
    });

    test('rejects oversized logical message', () {
      final Uint8List message = Uint8List(101);
      expect(() => codec.fragment(message, messageId: 1), throwsA(isA<PeerException>()));
    });
  });

  group('BleFrameAssembler', () {
    test('rejects corrupt total chunk count', () {
      final BleFrameAssembler assembler = BleFrameAssembler(codec: codec);
      final Uint8List corrupt = Uint8List.fromList(<int>[
        BleFrameCodec.protocolVersion,
        0,
        0,
        1,
        0,
        0,
        0,
        0,
        1,
      ]);

      expect(() => assembler.addFrame(corrupt), throwsA(isA<PeerException>()));
    });

    test('passes through legacy unframed payload', () {
      final BleFrameAssembler assembler = BleFrameAssembler(codec: codec);
      final Uint8List legacy = Uint8List.fromList('{'.codeUnits);

      expect(assembler.addFrame(legacy), legacy);
    });

    test('reset clears partial state', () {
      final Uint8List message = Uint8List.fromList(List<int>.generate(25, (int i) => i));
      final List<Uint8List> frames = codec.fragment(message, messageId: 7);
      final BleFrameAssembler assembler = BleFrameAssembler(codec: codec);

      expect(assembler.addFrame(frames.first), isNull);
      assembler.reset();
      expect(assembler.addFrame(frames.first), isNull);
      expect(assembler.addFrame(frames[1]), isNull);
      expect(assembler.addFrame(frames[2]), message);
    });
  });
}
