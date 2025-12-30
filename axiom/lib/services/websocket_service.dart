import 'package:socket_io_client/socket_io_client.dart' as IO;

class WebSocketService {
  IO.Socket? _socket;
  String? _currentProjectId;

  void connect() {
    _socket = IO.io('https://axiom-mmd4.onrender.com', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    _socket!.onConnect((_) {
      print('✅ WebSocket connected');
    });

    _socket!.onDisconnect((_) {
      print('❌ WebSocket disconnected');
    });
  }

  void joinProject(String projectId) {
    _currentProjectId = projectId;
    _socket?.emit('join-project', projectId);
  }

  void sendWidgetUpdate(String projectId, Map<String, dynamic> widgetData) {
    _socket?.emit('widget-update', {
      'projectId': projectId,
      'widget': widgetData,
    });
  }

  void sendCursorMove(String projectId, double x, double y, String userId) {
    _socket?.emit('cursor-move', {
      'projectId': projectId,
      'x': x,
      'y': y,
      'userId': userId,
    });
  }

  void onWidgetUpdated(Function(Map<String, dynamic>) callback) {
    _socket?.on('widget-updated', (data) {
      callback(data as Map<String, dynamic>);
    });
  }

  void onCursorMoved(Function(Map<String, dynamic>) callback) {
    _socket?.on('cursor-moved', (data) {
      callback(data as Map<String, dynamic>);
    });
  }

  void disconnect() {
    _socket?.disconnect();
  }
}