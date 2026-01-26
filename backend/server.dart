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

      // Trigger simple aggregation log
      _aggregateModel();

      return Response.ok(
          jsonEncode({'status': 'success', 'count': _collectedData.length}));
    } catch (e) {
      print('Error processing request: $e');
      return Response.internalServerError(body: 'Invalid JSON');
    }
  });

  // Endpoint to get the Global Aggregated Model
  router.get('/model', (Request request) {
    final globalModel = _aggregateModel();
    return Response.ok(jsonEncode(globalModel),
        headers: {'Content-Type': 'application/json'});
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

// Simple Federated Averaging / Aggregation Logic
Map<String, dynamic> _aggregateModel() {
  final categoryCounts = <String, Map<String, int>>{};
  final priorityCounts = <String, Map<String, int>>{};

  for (var record in _collectedData) {
    try {
      final rawData = record['data'];
      if (rawData is! Map) continue;

      final items = rawData['data'] as List;
      for (var item in items) {
        if (item['type'] == 'category_model') {
          final cat = item['category'];
          final word = item['word'];
          final count = item['count'] as int;

          categoryCounts.putIfAbsent(cat, () => {});
          categoryCounts[cat]!
              .update(word, (val) => val + count, ifAbsent: () => count);
        } else if (item['type'] == 'priority_model') {
          final prio = item['priority'];
          final word = item['word'];
          final count = item['count'] as int;

          priorityCounts.putIfAbsent(prio, () => {});
          priorityCounts[prio]!
              .update(word, (val) => val + count, ifAbsent: () => count);
        }
      }
    } catch (e) {
      print('Skipping malformed record during aggregation');
    }
  }

  // print('Aggregated Knowledge: ${categoryCounts.keys.length} categories, ${priorityCounts.keys.length} priorities.');

  return {
    'version': '1.0-global',
    'generated_at': DateTime.now().toIso8601String(),
    'categories': categoryCounts,
    'priorities': priorityCounts,
  };
}
