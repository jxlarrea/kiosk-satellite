import 'dart:async';

import 'package:mqtt5_client/mqtt5_client.dart' as v5;
import 'package:mqtt5_client/mqtt5_server_client.dart' as v5s;
import 'package:mqtt_client/mqtt_client.dart' as v3;
import 'package:mqtt_client/mqtt_server_client.dart' as v3s;
import 'package:typed_data/typed_data.dart' show Uint8Buffer;

/// One MQTT connection behind a protocol-agnostic face.
///
/// Two implementations, one per protocol generation. MQTT 5 is what the
/// manager wants: its Will Delay Interval is the protocol's own answer to
/// availability flapping (issue #184) — the broker sits on the will for a
/// grace period and a client that reconnects within it never goes offline
/// at all, so a radio that naps once a minute with the screen off stops
/// flapping every entity in Home Assistant, while a genuinely dead device
/// is still marked offline when the delay runs out. MQTT 3.1.1 has no such
/// notion and stays as the fallback for brokers that never learned 5; the
/// manager tries 5 first and falls back once per session.
///
/// The will delay only works from inside a live session: the spec fires the
/// will when the SESSION ends, so a clean-start connection with no expiry
/// ends its session the instant the transport drops and the delay never
/// gets to matter. The v5 link therefore connects with clean start off and
/// a session expiry just past the will delay — a first-ever connect simply
/// finds no session and starts one, and every reconnect resumes it.
abstract class MqttLink {
  /// Which protocol this link speaks, for logs and the status surface.
  String get protocolName;

  bool get connected;

  /// The broker's advertised Maximum Packet Size (MQTT 5 CONNACK), null
  /// when it stated none (or the protocol has no such notion, as in
  /// 3.1.1). A publish larger than this is a protocol error the broker
  /// answers by dropping the whole connection, so callers should skip
  /// oversize payloads instead of sending them.
  int? get brokerMaximumPacketSize => null;

  /// Fires on the initial connect and on every automatic reconnect alike;
  /// the manager's bring-up is idempotent and treats both the same.
  void Function()? onConnected;
  void Function()? onDisconnected;

  Stream<MqttInbound> get messages;

  /// Null on success; on failure, why and whether retrying can help.
  Future<MqttLinkError?> connect(MqttLinkConfig config);

  void publishString(String topic, String payload, {required bool retain});
  void publishBytes(String topic, List<int> bytes, {required bool retain});

  /// An empty retained payload — how Home Assistant discovery retracts.
  void publishEmpty(String topic);

  void subscribe(String topic);

  /// Graceful: auto-reconnect disarmed first, so the package treats it as
  /// "the user hung up" and stays down.
  void disconnect();
}

/// Everything a connect needs, protocol-neutral. The v5-only fields are
/// ignored by the 3.1.1 link.
class MqttLinkConfig {
  const MqttLinkConfig({
    required this.host,
    required this.port,
    required this.tls,
    required this.clientId,
    this.username,
    this.password,
    this.keepAliveSeconds = 30,
    this.noResponseSeconds = 0,
    this.connectTimeoutMs,
    this.autoReconnect = false,
    this.willTopic,
    this.willPayload = '',
    this.willDelaySeconds = 0,
  });

  final String host;
  final int port;
  final bool tls;
  final String clientId;
  final String? username;
  final String? password;
  final int keepAliveSeconds;
  final int noResponseSeconds;
  final int? connectTimeoutMs;
  final bool autoReconnect;

  /// Retained will, published by the broker when the session dies.
  final String? willTopic;
  final String willPayload;

  /// MQTT 5 only: how long the broker sits on the will before publishing
  /// it, the window inside which a reconnect keeps availability unbroken.
  final int willDelaySeconds;
}

/// A received message, already decoded to what the manager consumes.
class MqttInbound {
  const MqttInbound(this.topic, this.text, {required this.retained});

  final String topic;
  final String text;

  /// The broker replaying a stored payload at (re)subscribe time — every
  /// subscription here is an imperative command topic, so these are dropped.
  final bool retained;
}

class MqttLinkError {
  const MqttLinkError(this.message, {required this.retryable});

  /// Human-readable, shown by the validation surface as-is.
  final String message;

  /// True for network-shaped failures worth retrying on a timer; false for
  /// a broker that answered and said no (credentials, ACL) — hammering a
  /// refusing broker helps nobody.
  final bool retryable;

  @override
  String toString() => message;
}

String _describeException(Object error, String host, int port) {
  final text = '$error';
  if (text.contains('SocketException') || text.contains('timed out')) {
    return 'Could not reach $host:$port.';
  }
  if (text.contains('HandshakeException') ||
      text.contains('CertificateException')) {
    return 'TLS handshake failed. Check the Use TLS setting and the '
        "broker's certificate.";
  }
  return 'Could not connect to $host:$port.';
}

/// The MQTT 5 link, the preferred one.
class Mqtt5Link extends MqttLink {
  v5s.MqttServerClient? _client;
  final _messages = StreamController<MqttInbound>.broadcast();
  StreamSubscription<List<v5.MqttReceivedMessage<v5.MqttMessage>>>? _sub;

  @override
  String get protocolName => 'MQTT 5';

  @override
  bool get connected =>
      _client?.connectionStatus?.state == v5.MqttConnectionState.connected;

  @override
  int? get brokerMaximumPacketSize {
    try {
      final size =
          _client?.connectionStatus?.connectAckMessage.maximumPacketSize;
      // The property is absent from the CONNACK when the broker imposes
      // no limit; the package parses that as 0.
      return (size == null || size <= 0) ? null : size;
    } catch (_) {
      // The connack field is `late` in the package and unset until the
      // first CONNACK arrives.
      return null;
    }
  }

  @override
  Stream<MqttInbound> get messages => _messages.stream;

  @override
  Future<MqttLinkError?> connect(MqttLinkConfig config) async {
    final client = v5s.MqttServerClient.withPort(
        config.host, config.clientId, config.port);
    client.secure = config.tls;
    client.keepAlivePeriod = config.keepAliveSeconds;
    client.disconnectOnNoResponsePeriod = config.noResponseSeconds;
    client.autoReconnect = config.autoReconnect;
    client.resubscribeOnAutoReconnect = true;
    client.logging(on: false);
    // Clean start OFF with an expiry just past the will delay: the will
    // delay works by the session outliving the connection (see the class
    // comment). The margin keeps "session ends" from racing "delay ends"
    // on brokers that tick coarsely.
    var message = v5.MqttConnectMessage().startSession(
        sessionExpiryInterval: config.willDelaySeconds + 30);
    final willTopic = config.willTopic;
    if (willTopic != null) {
      message = message
          .will()
          .withWillTopic(willTopic)
          .withWillPayload(
              Uint8Buffer()..addAll(config.willPayload.codeUnits))
          .withWillRetain()
          .withWillQos(v5.MqttQos.atLeastOnce)
          .withWillProperties(v5.MqttWillProperties()
            ..willDelayInterval = config.willDelaySeconds);
    }
    client.connectionMessage = message;
    client.onConnected = () => onConnected?.call();
    client.onAutoReconnected = () => onConnected?.call();
    client.onDisconnected = () => onDisconnected?.call();
    _client = client;
    try {
      // The package exposes no connect timeout of its own on this client;
      // the future timeout stands in for the probe's bounded wait.
      var attempt = client.connect(config.username, config.password);
      if (config.connectTimeoutMs != null) {
        attempt = attempt.timeout(
            Duration(milliseconds: config.connectTimeoutMs!));
      }
      await attempt;
    } catch (e) {
      // The package can still be mid-connect when this throws (the future
      // timeout above fires first): the attempt must be killed outright,
      // not just dropped. An abandoned client that completes its connect
      // in the background becomes a ghost session under the same client
      // id as the link that replaces it (the 3.1.1 fallback, a retry),
      // and the broker then kicks whichever connected last, forever: a
      // "reset by peer" and an availability flap on every keepalive cycle.
      _abandon(client);
      return MqttLinkError(
        _describeException(e, config.host, config.port),
        retryable: true,
      );
    }
    if (!connected) {
      final code = client.connectionStatus?.reasonCode;
      _abandon(client);
      return MqttLinkError(_refusal(code), retryable: false);
    }
    _sub = client.updates?.listen((batch) {
      for (final received in batch) {
        final payload = received.payload;
        if (payload is! v5.MqttPublishMessage) continue;
        _messages.add(MqttInbound(
          received.topic ?? '',
          v5.MqttUtilities.bytesToStringAsString(payload.payload.message!),
          retained: payload.header?.retain == true,
        ));
      }
    });
    return null;
  }

  String _refusal(v5.MqttConnectReasonCode? code) => switch (code) {
    v5.MqttConnectReasonCode.badUsernameOrPassword =>
      'The broker rejected the username or password.',
    v5.MqttConnectReasonCode.notAuthorized =>
      'The broker refused this client. Check its access control rules.',
    v5.MqttConnectReasonCode.clientIdentifierNotValid =>
      'The broker rejected the client id.',
    v5.MqttConnectReasonCode.serverUnavailable ||
    v5.MqttConnectReasonCode.serverBusy =>
      'The broker is unavailable.',
    v5.MqttConnectReasonCode.unsupportedProtocolVersion =>
      'The broker does not accept MQTT 5.',
    _ => 'The broker refused the connection.',
  };

  @override
  void publishString(String topic, String payload, {required bool retain}) {
    _client?.publishMessage(topic, v5.MqttQos.atLeastOnce,
        (v5.MqttPayloadBuilder()..addUTF8String(payload)).payload!,
        retain: retain);
  }

  @override
  void publishBytes(String topic, List<int> bytes, {required bool retain}) {
    _client?.publishMessage(
        topic, v5.MqttQos.atLeastOnce, Uint8Buffer()..addAll(bytes),
        retain: retain);
  }

  @override
  void publishEmpty(String topic) {
    _client?.publishMessage(
        topic, v5.MqttQos.atLeastOnce, v5.MqttPayloadBuilder().payload!,
        retain: true);
  }

  @override
  void subscribe(String topic) {
    _client?.subscribe(topic, v5.MqttQos.atLeastOnce);
  }

  @override
  void disconnect() {
    _client?.autoReconnect = false;
    _client?.disconnect();
    _teardown();
  }

  /// A failed attempt, put down for good: callbacks unhooked and
  /// auto-reconnect disarmed before the disconnect, so nothing of it can
  /// come back to life later.
  void _abandon(v5s.MqttServerClient client) {
    client.onConnected = null;
    client.onAutoReconnected = null;
    client.onDisconnected = null;
    client.autoReconnect = false;
    try {
      client.disconnect();
    } catch (_) {}
    _teardown();
  }

  void _teardown() {
    _sub?.cancel();
    _sub = null;
    _client = null;
  }
}

/// The MQTT 3.1.1 link, for brokers that never learned 5. No will delay
/// exists at this protocol level, so availability behaves as it always has.
class Mqtt311Link extends MqttLink {
  v3s.MqttServerClient? _client;
  final _messages = StreamController<MqttInbound>.broadcast();
  StreamSubscription<List<v3.MqttReceivedMessage<v3.MqttMessage>>>? _sub;

  @override
  String get protocolName => 'MQTT 3.1.1';

  @override
  bool get connected =>
      _client?.connectionStatus?.state == v3.MqttConnectionState.connected;

  @override
  Stream<MqttInbound> get messages => _messages.stream;

  @override
  Future<MqttLinkError?> connect(MqttLinkConfig config) async {
    final client = v3s.MqttServerClient.withPort(
        config.host, config.clientId, config.port);
    client.secure = config.tls;
    client.keepAlivePeriod = config.keepAliveSeconds;
    client.disconnectOnNoResponsePeriod = config.noResponseSeconds;
    client.autoReconnect = config.autoReconnect;
    client.resubscribeOnAutoReconnect = true;
    if (config.connectTimeoutMs != null) {
      client.connectTimeoutPeriod = config.connectTimeoutMs!;
    }
    client.setProtocolV311();
    client.logging(on: false);
    var message = v3.MqttConnectMessage().startClean();
    final willTopic = config.willTopic;
    if (willTopic != null) {
      message = message
          .withWillTopic(willTopic)
          .withWillMessage(config.willPayload)
          .withWillRetain()
          .withWillQos(v3.MqttQos.atLeastOnce);
    }
    client.connectionMessage = message;
    client.onConnected = () => onConnected?.call();
    client.onAutoReconnected = () => onConnected?.call();
    client.onDisconnected = () => onDisconnected?.call();
    _client = client;
    try {
      await client.connect(config.username, config.password);
    } catch (e) {
      // Same ghost rule as the v5 link: a failed attempt is killed
      // outright, never just dropped (see Mqtt5Link.connect).
      _abandon(client);
      return MqttLinkError(
        _describeException(e, config.host, config.port),
        retryable: true,
      );
    }
    if (!connected) {
      final code = client.connectionStatus?.returnCode;
      _abandon(client);
      return MqttLinkError(_refusal(code), retryable: false);
    }
    _sub = client.updates?.listen((batch) {
      for (final received in batch) {
        final payload = received.payload;
        if (payload is! v3.MqttPublishMessage) continue;
        _messages.add(MqttInbound(
          received.topic,
          v3.MqttPublishPayload.bytesToStringAsString(
              payload.payload.message),
          retained: payload.header?.retain == true,
        ));
      }
    });
    return null;
  }

  String _refusal(v3.MqttConnectReturnCode? code) => switch (code) {
    v3.MqttConnectReturnCode.badUsernameOrPassword =>
      'The broker rejected the username or password.',
    v3.MqttConnectReturnCode.notAuthorized =>
      'The broker refused this client. Check its access control rules.',
    v3.MqttConnectReturnCode.identifierRejected =>
      'The broker rejected the client id.',
    v3.MqttConnectReturnCode.brokerUnavailable => 'The broker is unavailable.',
    v3.MqttConnectReturnCode.unacceptedProtocolVersion =>
      'The broker does not accept MQTT 3.1.1.',
    _ => 'The broker refused the connection.',
  };

  @override
  void publishString(String topic, String payload, {required bool retain}) {
    _client?.publishMessage(topic, v3.MqttQos.atLeastOnce,
        (v3.MqttClientPayloadBuilder()..addUTF8String(payload)).payload!,
        retain: retain);
  }

  @override
  void publishBytes(String topic, List<int> bytes, {required bool retain}) {
    _client?.publishMessage(
        topic, v3.MqttQos.atLeastOnce, Uint8Buffer()..addAll(bytes),
        retain: retain);
  }

  @override
  void publishEmpty(String topic) {
    _client?.publishMessage(topic, v3.MqttQos.atLeastOnce,
        v3.MqttClientPayloadBuilder().payload!,
        retain: true);
  }

  @override
  void subscribe(String topic) {
    _client?.subscribe(topic, v3.MqttQos.atLeastOnce);
  }

  @override
  void disconnect() {
    _client?.autoReconnect = false;
    _client?.disconnect();
    _teardown();
  }

  /// See [Mqtt5Link._abandon]: a failed attempt, put down for good.
  void _abandon(v3s.MqttServerClient client) {
    client.onConnected = null;
    client.onAutoReconnected = null;
    client.onDisconnected = null;
    client.autoReconnect = false;
    try {
      client.disconnect();
    } catch (_) {}
    _teardown();
  }

  void _teardown() {
    _sub?.cancel();
    _sub = null;
    _client = null;
  }
}
