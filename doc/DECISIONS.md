# Решения ble_peer_session 0.5.0

Формат: BPS-NN. Статусы: Accepted.

## BPS-01 — FGS ownership

| | |
|--|--|
| **Status** | Accepted |
| **Decision** | Android foreground service для удержания BLE-сессии принадлежит пакету. Хост задаёт только branding (`title` / `body` / `smallIcon`) через `BlePeerConfig.androidForeground`. |
| **Implication** | Приложение не дублирует Service, MethodChannel и activate/deactivate. `androidForeground == null` → пакет никогда не стартует FGS (обратная совместимость). |

## BPS-02 — task-removal semantics

| | |
|--|--|
| **Status** | Accepted |
| **Decision** | `android:stopWithTask="false"` + `onTaskRemoved` → native callback в Dart → transport teardown (`cancelPendingConnection` + `disconnect` обеих ролей) → `stopSelf` и снятие notification. |
| **Why not stopWithTask=true** | Он останавливает только Service. GATT принадлежит `bluetooth_low_energy`, не FGS. Без Dart teardown линк может пережить swipe, пока процесс жив. |
| **If Dart already dead** | `stopSelf` всё равно выполняется; смерть процесса закрывает `BluetoothGatt`. |

## BPS-03 — FGS start boundary

| | |
|--|--|
| **Status** | Accepted |
| **Decision** | FGS стартует на user-initiated transport establishment, пока start из foreground ещё разрешён: host — `startAdvertising`; client — начало `connectToDevice`. Держится через `connected`. Stop: cancel / fail / disconnect / stopAdvertising без сессии / dispose / task removal. |
| **Why not connected-only** | GATT 6–8 с; к моменту `connected` приложение уже может быть в background → `ForegroundServiceStartNotAllowedException`. |
| **Failure** | Ошибка старта не глотается: `PeerException(unexpected)` с `PlatformException` в `cause`. |

## BPS-04 — one Peer with FGS per process

| | |
|--|--|
| **Status** | Accepted |
| **Decision** | Несколько `Peer` в процессе допустимы. Если задан `androidForeground`, одновременно владеть FGS может только один `Peer` (StateError на второй `Peer.create`). |
| **Rationale** | 1:1 transport; tete_games держит один `Peer` через `PeerLifecycle`. Refcount нескольких брендированных FGS не нужен. |

## BPS-05 — discovery stream semantics

| | |
|--|--|
| **Status** | Accepted |
| **Decision** | `nearbyHostsStream` / `discoveredDevicesStream` — snapshot текущего live-набора, не union ever-seen и не add-only события. |

## BPS-06 — discovery TTL

| | |
|--|--|
| **Status** | Accepted |
| **Decision** | `BlePeerConfig.discoveryStaleAfter` (default 3s), `discoverySweepInterval` (default 400ms). Monotonic `Stopwatch`. Каждый валидный observation обновляет `lastSeen` и metadata. Старые `peripheral.uuid` истекают независимо; merge по `deviceName` запрещён. |

## BPS-07 — connect cancellation ownership

| | |
|--|--|
| **Status** | Accepted |
| **Decision** | `PeerClient.cancelPendingConnection()` абортит in-flight GATT через `CentralManager.disconnect` (в `bluetooth_low_energy_android` это `gatt.disconnect()` и complete connect callback с failure). |
| **Proof path** | `connect()` регистрирует callback до возврата; concurrent `disconnect()` закрывает GATT и завершает Future. |

## BPS-08 — stale callback protection

| | |
|--|--|
| **Status** | Accepted |
| **Decision** | Пакет: generation gate на in-flight connect. Хост (tete_games): отдельный `operationGeneration` — late callback не мутирует product FSM. Generation не заменяет GATT cancel. |

## BPS-09 — Android notification branding

| | |
|--|--|
| **Status** | Accepted |
| **Decision** | Preferred: пакет содержит нейтральную monochrome иконку `ic_stat_ble_peer`. `smallIcon == null` → она. Хост может передать `@drawable/…` / `@mipmap/…`. Невалидный resource → `PlatformException`, не native crash. |

## BPS-10 — migration strategy

| | |
|--|--|
| **Status** | Accepted |
| **Decision** | 0.5.0: Dart package → Flutter plugin (Android). Сначала пакет + path-dep + package FGS, затем удаление дубля в приложении. Публикация на pub.dev — только по отдельной команде. |
