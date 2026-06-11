# Backlog — ble_peer_session

Задачи на следующие версии пакета.

## v0.2

### Framing для сообщений > MTU

**Проблема:** сейчас один GATT write/notify = одно JSON-сообщение. Если payload больше effective MTU (~20–500 байт), данные обрезаются или не парсятся.

**Цель:** поддержать логические сообщения произвольного размера через разбиение на кадры и сборку на приёмнике.

**Где реализовать:** слой Link (`BleLinkBase`), не Messenger.

**Черновик формата кадра:**
- length-prefix: `[uint32 BE length][payload bytes…]`, или
- chunking: `[frameId][seq][total][chunk…]`

**Критерии готовности:**
- [ ] `BleFrameCodec` encode/decode в `lib/src/codec/`
- [ ] интеграция в `BleLinkClientImpl` / `BleLinkServerImpl`
- [ ] unit-тесты: split/join, oversized payload, corrupt length
- [ ] лимит размера сообщения и поведение при превышении — в README

---

## Примеры и документация

### example/minimal_chat

**Цель:** reference-приложение в пакете, демонстрирующее end-to-end сценарий без batuga.

**Экраны / сценарии:**
- [ ] выбор роли: server (advertise) / client (discover)
- [ ] список найденных устройств (`discoveredDevicesStream`)
- [ ] handshake: invitation → accept/reject
- [ ] двусторонний чат через `PeerMessage(type: 'chat.text')`
- [ ] вкладка benchmark: ping/pong, min/avg/max RTT (ms)

**Критерии готовности:**
- [ ] `example/minimal_chat/` — отдельное Flutter-приложение
- [ ] README: раздел «Example» со ссылкой и шагами запуска на двух устройствах

---

## Позже (не в v0.2)

- Reliability: опциональный ACK/retry для критичных сообщений
- Reconnect policy при обрыве BLE-сессии
- Mesh до 6 участников (отдельный ADR)
