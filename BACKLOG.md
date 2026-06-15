# Backlog — ble_peer_session

Tasks for upcoming package versions.

See [README](README.md) for current API docs.

---

## v0.3.1 — done

### Framing for messages > MTU

- [x] `BleFrameCodec` encode/decode in `lib/src/codec/`
- [x] integration in `BleLinkClientImpl` / `BleLinkServerImpl`
- [x] unit tests: split/join, oversized payload, corrupt length
- [x] max message size documented in README §6 Internals

### example/minimal_chat

- [x] role pick: host / client
- [x] discovered hosts list (client)
- [x] handshake: invite → accept
- [x] bidirectional chat via `sendText` / `textMessages`
- [x] example README

### Documentation

- [x] README: TL;DR first, single connection flow, grouped sections (Quick start → Core → API → Platform → Internals)
- [x] `doc/README.md` index, cross-links across guides
- [x] ERROR_CODES: fix `payloadTooLarge` note (framing shipped in 0.3.1)
- [x] Migration guides aligned with Level 1 / Level 2 terminology

---

## Later

- Reliability: optional ACK/retry for critical messages
- Reconnect policy on BLE drop
- Example benchmark tab: ping/pong RTT
- ~~Mesh up to 6 participants~~ — **out of scope**; package targets 1:1 only
