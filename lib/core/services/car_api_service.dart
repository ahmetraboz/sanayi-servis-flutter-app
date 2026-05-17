import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';

class CarMake {
  final int id;
  final String name;
  final String? imageUrl;

  const CarMake({required this.id, required this.name, this.imageUrl});

  factory CarMake.fromJson(Map<String, dynamic> json) => CarMake(
        id: json['id'] as int,
        name: json['name'] as String,
        imageUrl: json['imageUrl'] as String?,
      );
}

class CarModel {
  final int id;
  final String name;

  const CarModel({required this.id, required this.name});

  factory CarModel.fromJson(Map<String, dynamic> json) => CarModel(
        id: json['id'] as int,
        name: json['name'] as String,
      );
}

class CarApiService {
  static List<CarMake>? _makesCache;
  static final Map<String, String> _imageCache = {};
  static final Map<String, Future<String>> _inflight = {};

  final ApiClient _api;

  CarApiService(this._api);

  Future<List<CarMake>> getAllMakes() async {
    if (_makesCache != null) return _makesCache!;
    try {
      final res = await _api.get('/api/cars/makes');
      final data = res.data as Map<String, dynamic>;
      _makesCache = (data['makes'] as List)
          .map((e) => CarMake.fromJson(e as Map<String, dynamic>))
          .toList();
      return _makesCache!;
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'Markalar yüklenemedi');
    }
  }

  Future<List<CarModel>> getModelsForMake(int makeId) async {
    try {
      final res = await _api.get('/api/cars/$makeId/models');
      final data = res.data as Map<String, dynamic>;
      return (data['models'] as List)
          .map((e) => CarModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'Modeller yüklenemedi');
    }
  }

  Future<String?> getVehicleImage(String make, String model, int? year) async {
    final key = '$make-$model-${year ?? ""}';
    if (_imageCache.containsKey(key)) return _imageCache[key];
    if (_inflight.containsKey(key)) return _inflight[key];

    final future = _api
        .get('/api/cars/image', queryParameters: {
          'make': make,
          'model': model,
          if (year != null) 'year': year,
        })
        .then((r) {
          final url = r.data['url'] as String?;
          if (url != null && url.isNotEmpty) _imageCache[key] = url;
          return url ?? '';
        })
        .catchError((_) => '');

    _inflight[key] = future;
    final result = await future;
    _inflight.remove(key);
    return result.isEmpty ? null : result;
  }

  Future<Map<String, String?>> getVehicleImagesBatch(
    List<Map<String, dynamic>> vehicles,
  ) async {
    try {
      final res = await _api.post(
        '/api/cars/images',
        data: {'vehicles': vehicles},
      );
      final data = res.data as Map<String, dynamic>;
      return data.map((key, value) {
        final url = (value as Map<String, dynamic>)['url'] as String?;
        return MapEntry(key, url?.isNotEmpty == true ? url : null);
      });
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'Araç görselleri yüklenemedi');
    }
  }

  List<CarMake> filterMakes(String query) {
    if (query.isEmpty) return _makesCache ?? [];
    final q = query.toLowerCase();
    return (_makesCache ?? [])
        .where((m) => m.name.toLowerCase().contains(q))
        .take(50)
        .toList();
  }

  static void clearCache() {
    _makesCache = null;
    _imageCache.clear();
    _inflight.clear();
  }
}

final carApiServiceProvider = Provider<CarApiService>((ref) {
  return CarApiService(ref.read(apiClientProvider));
});

final carMakesProvider = FutureProvider<List<CarMake>>((ref) {
  return ref.read(carApiServiceProvider).getAllMakes();
});

final carModelsProvider = FutureProvider.family<List<CarModel>, int>((ref, makeId) {
  return ref.read(carApiServiceProvider).getModelsForMake(makeId);
});
