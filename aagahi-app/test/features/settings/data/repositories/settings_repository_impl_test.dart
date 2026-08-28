import 'package:aagahi/core/error/exceptions.dart';
import 'package:aagahi/core/error/failures.dart';
import 'package:aagahi/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:aagahi/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:aagahi/features/settings/domain/entities/app_settings.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeLocalDataSource implements SettingsLocalDataSource {
  AppSettings current = AppSettings.defaults;
  bool wiped = false;
  bool shouldThrow = false;

  @override
  Stream<AppSettings> watch() => Stream.value(current);

  @override
  Future<void> save(AppSettings settings) async {
    if (shouldThrow) throw const CacheException('disk full');
    current = settings;
  }

  @override
  Future<void> wipeAllData() async {
    if (shouldThrow) throw const CacheException('disk full');
    wiped = true;
    current = AppSettings.defaults;
  }
}

void main() {
  late _FakeLocalDataSource local;
  late SettingsRepositoryImpl repository;

  setUp(() {
    local = _FakeLocalDataSource();
    repository = SettingsRepositoryImpl(local: local);
  });

  test('watchSettings reflects a real save, not a decorative default',
      () async {
    final changed = AppSettings.defaults.copyWith(phoneNumber: '3001234567');

    await repository.save(changed);

    expect(await repository.watchSettings().first, changed);
  });

  test('a local write failure surfaces as CacheFailure, never a silent drop',
      () async {
    local.shouldThrow = true;

    final result = await repository.save(AppSettings.defaults);

    expect(result, const Left<Failure, AppSettings>(CacheFailure()));
  });

  test('deleteAllData actually wipes the local store', () async {
    await repository
        .save(AppSettings.defaults.copyWith(phoneNumber: '3001234567'));

    final result = await repository.deleteAllData();

    expect(result, const Right<Failure, Unit>(unit));
    expect(local.wiped, isTrue);
    expect(await repository.watchSettings().first, AppSettings.defaults);
  });

  test('a wipe failure surfaces as CacheFailure', () async {
    local.shouldThrow = true;

    final result = await repository.deleteAllData();

    expect(result, const Left<Failure, Unit>(CacheFailure()));
  });
}
