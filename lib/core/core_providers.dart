import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'api/api_client.dart';
import 'storage/local_storage.dart';

/// Overridden in main.dart with the instance created during app bootstrap.
final localStorageProvider = Provider<LocalStorage>((ref) => throw UnimplementedError());

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(localStorageProvider);
  return ApiClient(storage);
});

final packageInfoProvider = FutureProvider<PackageInfo>((ref) => PackageInfo.fromPlatform());
