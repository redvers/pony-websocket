use "net"
use "websocket"
use "collections"

use @printf[I32](fmt: Pointer[U8] tag, ...)

actor Main
  new create(env: Env) =>
    env.out.print("Start server")

    let listener = WebSocketListener(TCPListenAuth(env.root),
      BroadcastListenNotify, "127.0.0.1","8989")

actor ConnectionManager
  var _connections: SetIs[WebSocketConnection] =
    SetIs[WebSocketConnection].create()

  be add(conn: WebSocketConnection) =>
    @printf("Add connection\n".cstring())
    _connections.set(conn)

  be remove(conn: WebSocketConnection) =>
    @printf("Remove connection\n".cstring())
    _connections.unset(conn)

  be broadcast_text(text: String) =>
    for c in _connections.values() do
      c.send_text_be(text)
    end

  be broadcast_binary(data: Array[U8] val) =>
    for c in _connections.values() do
      c.send_binary_be(data)
    end

class BroadcastListenNotify is WebSocketListenNotify
  var _conn_manager: ConnectionManager = ConnectionManager.create()

  fun ref connected(): BroadcastConnectionNotify iso^ =>
    BroadcastConnectionNotify(_conn_manager)

  fun ref not_listening() =>
    @printf("Failed listening\n".cstring())

class BroadcastConnectionNotify is WebSocketConnectionNotify
  var _conn_manager: ConnectionManager

  new iso create(conn_manager: ConnectionManager) =>
    _conn_manager = conn_manager

  fun ref opened(conn: WebSocketConnection tag) =>
    _conn_manager.add(conn)

  fun ref text_received(conn: WebSocketConnection tag, text: String) =>
    _conn_manager.broadcast_text(text)

  fun ref binary_received(conn: WebSocketConnection tag, data: Array[U8] val) =>
    _conn_manager.broadcast_binary(data)

  fun ref closed(conn: WebSocketConnection tag) =>
    _conn_manager.remove(conn)
