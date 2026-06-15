# Backlog — ble_peer_session

Tasks for upcoming package versions.

## v0.3.1 — done

### Framing for messages > MTU

- [x] `BleFrameCodec` encode/decode in `lib/src/codec/`
- [x] integration in `BleLinkClientImpl` / `BleLinkServerImpl`
- [x] unit tests: split/join, oversized payload, corrupt length
- [x] max message size documented in README

### example/minimal_chat

- [x] role pick: host / client
- [x] discovered hosts list (client)
- [x] handshake: invite → accept
- [x] bidirectional chat via `sendText` / `textMessages`
- [x] README «Example» section

---

## Later

- Reliability: optional ACK/retry for critical messages
- Reconnect policy on BLE drop
- Example benchmark tab: ping/pong RTT
- ~~Mesh up to 6 participants~~ — **out of scope**; package targets 1:1 only
