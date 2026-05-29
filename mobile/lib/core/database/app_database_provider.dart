// Riverpod entry point for the offline SQLite cache. Audit L1 Phase 1.
//
// Lives in its own file (not in app_database.dart) so the drift
// codegen target stays focused on table definitions + the
// `_$AppDatabase` mixin. Splitting also lets test bootstraps
// construct `AppDatabase.withExecutor(NativeDatabase.memory())`
// without pulling in the Riverpod-annotation build target.
//
// keepAlive because:
//   * The database opens a real file handle / sqlite3 connection;
//     disposing-and-reopening per provider-scope rebuild would
//     thrash. App-lifetime singleton is what every cache-through
//     repository expects.
//   * No data is at risk on dispose — drift's NativeDatabase
//     closes cleanly via the ref.onDispose hook below.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'app_database.dart';

part 'app_database_provider.g.dart';

@Riverpod(keepAlive: true)
AppDatabase appDatabase(AppDatabaseRef ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}
