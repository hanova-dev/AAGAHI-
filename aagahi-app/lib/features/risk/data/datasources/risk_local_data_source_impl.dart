import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/error/exceptions.dart';
import '../models/risk_assessment_model.dart';
import 'risk_local_data_source.dart';

/// Drift/SQLCipher-backed implementation of [RiskLocalDataSource]
/// (NFR-SEC-002). Assessments are cached as JSON (see [AppDatabase]'s
/// `payload` column doc comment); briefing audio is cached as plain files
/// under the app's support directory, not in the database.
final class RiskLocalDataSourceImpl implements RiskLocalDataSource {
  RiskLocalDataSourceImpl(this._db);

  final AppDatabase _db;

  @override
  Future<RiskAssessmentModel?> readAssessment(String parcelId) async {
    try {
      final row = await (_db.select(_db.riskAssessmentRows)
            ..where((t) => t.parcelId.equals(parcelId)))
          .getSingleOrNull();
      if (row == null) return null;
      return RiskAssessmentModel.fromJson(
        jsonDecode(row.payload) as Map<String, dynamic>,
      );
    } catch (error) {
      throw CacheException(
          'Failed to read cached assessment for $parcelId: $error');
    }
  }

  @override
  Future<void> writeAssessment(
      String parcelId, RiskAssessmentModel model) async {
    try {
      await _db.into(_db.riskAssessmentRows).insertOnConflictUpdate(
            RiskAssessmentRowsCompanion.insert(
              parcelId: parcelId,
              assessedOn: model.entity.assessedOn,
              payload: jsonEncode(model.toJson()),
            ),
          );
    } catch (error) {
      throw CacheException(
          'Failed to write cached assessment for $parcelId: $error');
    }
  }

  @override
  Stream<RiskAssessmentModel> watchAssessment(String parcelId) {
    return (_db.select(_db.riskAssessmentRows)
          ..where((t) => t.parcelId.equals(parcelId)))
        .watchSingleOrNull()
        .where((row) => row != null)
        .map(
          (row) => RiskAssessmentModel.fromJson(
            jsonDecode(row!.payload) as Map<String, dynamic>,
          ),
        );
  }

  @override
  Future<String?> briefingPath(String assessmentId) async {
    final file = await _briefingFile(assessmentId);
    return file.existsSync() ? file.path : null;
  }

  @override
  Future<String> writeBriefing(String assessmentId, List<int> bytes) async {
    try {
      final file = await _briefingFile(assessmentId);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (error) {
      throw CacheException(
          'Failed to write briefing for $assessmentId: $error');
    }
  }

  Future<File> _briefingFile(String assessmentId) async {
    final directory = await getApplicationSupportDirectory();
    return File(p.join(directory.path, 'briefings', '$assessmentId.audio'));
  }
}
