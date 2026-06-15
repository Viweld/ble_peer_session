import 'dart:async';

import 'package:ble_peer_session/ble_peer_session.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MinimalChatApp());
}

final class MinimalChatApp extends StatelessWidget {
  const MinimalChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BLE Minimal Chat',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const RolePickerScreen(),
    );
  }
}

enum ChatRole { host, client }

final class RolePickerScreen extends StatefulWidget {
  const RolePickerScreen({super.key});

  @override
  State<RolePickerScreen> createState() => _RolePickerScreenState();
}

final class _RolePickerScreenState extends State<RolePickerScreen> {
  final TextEditingController _nameController = TextEditingController(text: 'Player');
  bool _starting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _start(ChatRole role) async {
    final String name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a display name.');
      return;
    }

    setState(() {
      _starting = true;
      _error = null;
    });

    try {
      final Peer peer = Peer.create(appName: 'MinimalChat');
      await peer.permissions.checkPermissions();

      if (!mounted) {
        await peer.dispose();
        return;
      }

      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => ChatScreen(
            peer: peer,
            role: role,
            localUser: PeerUser(id: name.toLowerCase(), displayName: name),
          ),
        ),
      );

      await peer.dispose();
    } on PeerException catch (error) {
      setState(() => _error = error.toString());
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _starting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BLE Minimal Chat')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Two phones, same app name, no internet.\nPick a role on each device.',
              style: TextStyle(height: 1.4),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Display name',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _starting ? null : () => _start(ChatRole.host),
              child: const Text('Host — wait for friend'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _starting ? null : () => _start(ChatRole.client),
              child: const Text('Client — find host'),
            ),
            if (_starting) ...<Widget>[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
            ],
            if (_error != null) ...<Widget>[
              const SizedBox(height: 16),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ),
      ),
    );
  }
}

final class ChatScreen extends StatefulWidget {
  const ChatScreen({required this.peer, required this.role, required this.localUser, super.key});

  final Peer peer;
  final ChatRole role;
  final PeerUser localUser;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

final class _ChatScreenState extends State<ChatScreen> {
  PeerHost? _host;
  PeerClient? _client;
  PeerConnectionPhase _phase = PeerConnectionPhase.idle;
  String? _remoteName;
  final List<_ChatLine> _lines = <_ChatLine>[];
  final TextEditingController _messageController = TextEditingController();
  final List<StreamSubscription<Object?>> _subscriptions = <StreamSubscription<Object?>>[];
  List<PeerNearby> _nearbyHosts = <PeerNearby>[];
  String? _status;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    if (widget.role == ChatRole.host) {
      final PeerHost host = await widget.peer.host(localUser: widget.localUser);
      _host = host;
      _listenHost(host);
      setState(() {
        _phase = PeerConnectionPhase.waitingForPeer;
        _status = 'Advertising — waiting for invite…';
      });
      return;
    }

    final PeerClient client = await widget.peer.client(localUser: widget.localUser);
    _client = client;
    _listenClient(client);
    setState(() {
      _phase = PeerConnectionPhase.waitingForPeer;
      _status = 'Scanning for nearby hosts…';
    });
  }

  void _listenHost(PeerHost host) {
    _subscriptions
      ..add(
        host.connectionStream.listen((PeerConnectionInfo? info) {
          if (!mounted || info == null) {
            return;
          }
          setState(() {
            _phase = info.phase;
            _remoteName = info.remotePeer?.identity.displayName;
            _status = _phaseLabel(info.phase);
          });
        }),
      )
      ..add(
        host.messagesStream.listen((PeerMessage message) {
          if (message.type == PeerMessageTypes.sessionInvite) {
            unawaited(_acceptInvite(host));
          }
        }),
      )
      ..add(
        host.textMessages.listen((String text) {
          _appendIncoming(text);
        }),
      );
  }

  void _listenClient(PeerClient client) {
    _subscriptions
      ..add(
        client.connectionStream.listen((PeerConnectionInfo? info) {
          if (!mounted || info == null) {
            return;
          }
          setState(() {
            _phase = info.phase;
            _remoteName = info.remotePeer?.identity.displayName;
            _status = _phaseLabel(info.phase);
          });
        }),
      )
      ..add(
        client.nearbyHostsStream.listen((List<PeerNearby> hosts) {
          if (!mounted) {
            return;
          }
          setState(() => _nearbyHosts = hosts);
        }),
      )
      ..add(
        client.textMessages.listen((String text) {
          _appendIncoming(text);
        }),
      );
  }

  Future<void> _acceptInvite(PeerHost host) async {
    if (_busy || _phase != PeerConnectionPhase.awaitingUserDecision) {
      return;
    }

    setState(() {
      _busy = true;
      _status = 'Accepting invite…';
    });

    try {
      await host.accept();
    } on PeerException catch (error) {
      setState(() => _status = error.toString());
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _invite(PeerNearby host) async {
    final PeerClient? client = _client;
    if (client == null || _busy) {
      return;
    }

    setState(() {
      _busy = true;
      _status = 'Inviting ${host.displayName}…';
    });

    try {
      await client.invite(host);
    } on PeerException catch (error) {
      setState(() => _status = error.toString());
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _appendIncoming(String text) {
    if (!mounted) {
      return;
    }
    setState(() {
      _lines.add(_ChatLine(text: text, outgoing: false));
    });
  }

  Future<void> _sendMessage() async {
    final String text = _messageController.text.trim();
    if (text.isEmpty || _phase != PeerConnectionPhase.connected) {
      return;
    }

    _messageController.clear();
    setState(() {
      _lines.add(_ChatLine(text: text, outgoing: true));
    });

    try {
      if (_host != null) {
        await _host!.sendText(text);
      } else {
        await _client!.sendText(text);
      }
    } on PeerException catch (error) {
      setState(() => _status = error.toString());
    }
  }

  String _phaseLabel(PeerConnectionPhase phase) {
    return switch (phase) {
      PeerConnectionPhase.idle => 'Idle',
      PeerConnectionPhase.waitingForPeer =>
        widget.role == ChatRole.host ? 'Waiting for invite…' : 'Pick a host below',
      PeerConnectionPhase.awaitingUserDecision => 'Invite received — accepting…',
      PeerConnectionPhase.awaitingRemoteDecision => 'Waiting for host response…',
      PeerConnectionPhase.connected => 'Connected',
    };
  }

  @override
  void dispose() {
    for (final StreamSubscription<Object?> subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _messageController.dispose();
    unawaited(_host?.stop());
    unawaited(_client?.stopDiscovery());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool connected = _phase == PeerConnectionPhase.connected;
    final String title = widget.role == ChatRole.host ? 'Host' : 'Client';

    return Scaffold(
      appBar: AppBar(title: Text('$title${_remoteName == null ? '' : ' · $_remoteName'}')),
      body: Column(
        children: <Widget>[
          if (_status != null)
            Material(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: <Widget>[
                    Expanded(child: Text(_status!)),
                    if (_busy)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
            ),
          if (widget.role == ChatRole.client &&
              !connected &&
              _phase == PeerConnectionPhase.waitingForPeer)
            Expanded(
              child: _nearbyHosts.isEmpty
                  ? const Center(child: Text('No hosts nearby yet'))
                  : ListView.separated(
                      itemCount: _nearbyHosts.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (BuildContext context, int index) {
                        final PeerNearby host = _nearbyHosts[index];
                        return ListTile(
                          title: Text(host.displayName),
                          subtitle: Text(host.device.id),
                          trailing: const Icon(Icons.link),
                          onTap: _busy ? null : () => _invite(host),
                        );
                      },
                    ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _lines.length,
                itemBuilder: (BuildContext context, int index) {
                  final _ChatLine line = _lines[index];
                  return Align(
                    alignment: line.outgoing ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: line.outgoing
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(line.text),
                    ),
                  );
                },
              ),
            ),
          if (_phase == PeerConnectionPhase.awaitingUserDecision && widget.role == ChatRole.host)
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: _busy ? null : () => unawaited(_acceptInvite(_host!)),
                child: const Text('Accept invite'),
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      enabled: connected,
                      decoration: const InputDecoration(
                        hintText: 'Message',
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: connected ? (_) => unawaited(_sendMessage()) : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: connected ? () => unawaited(_sendMessage()) : null,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _ChatLine {
  const _ChatLine({required this.text, required this.outgoing});

  final String text;
  final bool outgoing;
}
