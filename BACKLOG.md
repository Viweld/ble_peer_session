# Backlog — ble_peer_session

Tasks for upcoming package versions.

## v0.3

### Framing for messages > MTU

**Problem:** one GATT write/notify equals one JSON message. Payloads larger than the effective MTU (~20–500 bytes) are truncated or fail to parse.

**Goal:** support logical messages of arbitrary size via frame splitting and reassembly.

**Where:** Link layer (`BleLinkBase`), not Messenger.

**Draft frame format:**
- length-prefix: `[uint32 BE length][payload bytes…]`, or
- chunking: `[frameId][seq][total][chunk…]`

**Done when:**
- [ ] `BleFrameCodec` encode/decode in `lib/src/codec/`
- [ ] integration in `BleLinkClientImpl` / `BleLinkServerImpl`
- [ ] unit tests: split/join, oversized payload, corrupt length
- [ ] max message size and overflow behavior documented in README

---

## Examples and documentation

### example/minimal_chat

**Goal:** reference app demonstrating end-to-end flow without a host app.

**Screens / flows:**
- [ ] role pick: host (advertise) / client (discover)
- [ ] discovered devices list
- [ ] handshake: invite → accept/reject
- [ ] bidirectional chat via `PeerMessage(type: 'chat.text')`
- [ ] benchmark tab: ping/pong RTT

**Done when:**
- [ ] `example/minimal_chat/` Flutter app
- [ ] README «Example» section with two-device run steps

---

## Later

- Reliability: optional ACK/retry for critical messages
- Reconnect policy on BLE drop
- ~~Mesh up to 6 participants~~ — **out of scope**; package targets 1:1 only
