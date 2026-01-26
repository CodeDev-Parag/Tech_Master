import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

// In-memory storage for demonstration
final List<Map<String, dynamic>> _collectedData = [];

// Robust CORS middleware
Middleware corsMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers':
              'Origin, Content-Type, Accept, Authorization',
        });
      }
      final response = await innerHandler(request);
      return response.change(headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers':
            'Origin, Content-Type, Accept, Authorization',
      });
    };
  };
}

void main() async {
  final router = Router();

  // Handle OPTIONS requests for CORS (pre-flight checks)
  router.options('/<ignored|.*>', (Request request) {
    return Response.ok('', headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Origin, Content-Type',
    });
  });

  // Endpoint to receive training data
  router.post('/collect', (Request request) async {
    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload);

      // Store data (timestamped)
      final record = {
        'timestamp': DateTime.now().toIso8601String(),
        'data': data,
      };

      _collectedData.add(record);

      print('Received data packet! Total records: ${_collectedData.length}');
      if (data is Map && data['data'] != null) {
        print('Sample: ${(data['data'] as List).first}');
      }

      return Response.ok(
          jsonEncode({'status': 'success', 'count': _collectedData.length}));
    } catch (e) {
      print('Error processing request: $e');
      return Response.internalServerError(body: 'Invalid JSON');
    }
  });

  // Endpoint to view collected data
  router.get('/view', (Request request) {
    return Response.ok(jsonEncode(_collectedData),
        headers: {'Content-Type': 'application/json'});
  });

  router.get('/', (Request request) {
    return Response.ok('Task Master Data Collection Server Running...');
  });

  // Combine headers and handlers
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsMiddleware()) // Use our manual middleware
      .addHandler(router.call);

  // Bind to any IPv4 address
  // Use PORT environment variable if available (required for Cloud Run/Render etc)
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
  print('Data Collection Server listening on port ${server.port}');
}
