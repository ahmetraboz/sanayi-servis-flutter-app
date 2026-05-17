import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api_client.dart';
import '../../../shared/models/vehicle_model.dart';

final vehicleApiProvider = Provider<VehicleApiService>((ref) {
  return VehicleApiService(ref.watch(apiClientProvider));
});

class VehicleApiService {
  final ApiClient _client;

  VehicleApiService(this._client);

  Future<Map<String, dynamic>> lookupVin(String vin) async {
    final response = await _client.get('/api/vehicles/vin-decode', queryParameters: {'vin': vin});
    return response.data as Map<String, dynamic>;
  }

  Future<List<VehicleModel>> getVehicles() async {
    final response = await _client.get('/api/vehicles');
    final data = response.data as List;
    return data.map((json) => VehicleModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<VehicleModel> getVehicle(int id) async {
    final response = await _client.get('/api/vehicles/$id');
    return VehicleModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<VehicleModel> addVehicle(Map<String, dynamic> data) async {
    final response = await _client.post('/api/vehicles', data: data);
    return VehicleModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<VehicleModel> updateVehicle(int id, Map<String, dynamic> data) async {
    final response = await _client.put('/api/vehicles/$id', data: data);
    return VehicleModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteVehicle(int id) async {
    await _client.delete('/api/vehicles/$id');
  }
}
