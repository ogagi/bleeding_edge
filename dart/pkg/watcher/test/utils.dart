// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library watcher.test.utils;

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:scheduled_test/scheduled_test.dart';
import 'package:unittest/compact_vm_config.dart';
import 'package:watcher/watcher.dart';
import 'package:watcher/src/stat.dart';

/// The path to the temporary sandbox created for each test. All file
/// operations are implicitly relative to this directory.
String _sandboxDir;

/// The [DirectoryWatcher] being used for the current scheduled test.
DirectoryWatcher _watcher;

/// The index in [_watcher]'s event stream for the next event. When event
/// expectations are set using [expectEvent] (et. al.), they use this to
/// expect a series of events in order.
var _nextEvent = 0;

/// The mock modification times (in milliseconds since epoch) for each file.
///
/// The actual file system has pretty coarse granularity for file modification
/// times. This means using the real file system requires us to put delays in
/// the tests to ensure we wait long enough between operations for the mod time
/// to be different.
///
/// Instead, we'll just mock that out. Each time a file is written, we manually
/// increment the mod time for that file instantly.
Map<String, int> _mockFileModificationTimes;

void initConfig() {
  useCompactVMConfiguration();
  filterStacks = true;
}

/// Creates the sandbox directory the other functions in this library use and
/// ensures it's deleted when the test ends.
///
/// This should usually be called by [setUp].
void createSandbox() {
  var dir = Directory.systemTemp.createTempSync('watcher_test_');
  _sandboxDir = dir.path;

  _mockFileModificationTimes = new Map<String, int>();
  mockGetModificationTime((path) {
    path = p.normalize(p.relative(path, from: _sandboxDir));

    // Make sure we got a path in the sandbox.
    assert(p.isRelative(path)  && !path.startsWith(".."));

    return new DateTime.fromMillisecondsSinceEpoch(
        _mockFileModificationTimes[path]);
  });

  // Delete the sandbox when done.
  currentSchedule.onComplete.schedule(() {
    if (_sandboxDir != null) {
      new Directory(_sandboxDir).deleteSync(recursive: true);
      _sandboxDir = null;
    }

    _mockFileModificationTimes = null;
    mockGetModificationTime(null);
  }, "delete sandbox");
}

/// Creates a new [DirectoryWatcher] that watches a temporary directory.
///
/// Normally, this will pause the schedule until the watcher is done scanning
/// and is polling for changes. If you pass `false` for [waitForReady], it will
/// not schedule this delay.
///
/// If [dir] is provided, watches a subdirectory in the sandbox with that name.
DirectoryWatcher createWatcher({String dir, bool waitForReady}) {
  if (dir == null) {
    dir = _sandboxDir;
  } else {
    dir = p.join(_sandboxDir, dir);
  }

  // Use a short delay to make the tests run quickly.
  _watcher = new DirectoryWatcher(dir,
      pollingDelay: new Duration(milliseconds: 100));

  // Wait until the scan is finished so that we don't miss changes to files
  // that could occur before the scan completes.
  if (waitForReady != false) {
    schedule(() => _watcher.ready, "wait for watcher to be ready");
  }

  currentSchedule.onComplete.schedule(() {
    _nextEvent = 0;
    _watcher = null;
  }, "reset watcher");

  return _watcher;
}

/// Expects that the next set of events will all be changes of [type] on
/// [paths].
///
/// Validates that events are delivered for all paths in [paths], but allows
/// them in any order.
void expectEvents(ChangeType type, Iterable<String> paths) {
  var pathSet = paths
      .map((path) => p.join(_sandboxDir, path))
      .map(p.normalize)
      .toSet();

  // Create an expectation for as many paths as we have.
  var futures = [];

  for (var i = 0; i < paths.length; i++) {
    // Immediately create the futures. This ensures we don't register too
    // late and drop the event before we receive it.
    var future = _watcher.events.elementAt(_nextEvent++).then((event) {
      expect(event.type, equals(type));
      expect(pathSet, contains(event.path));

      pathSet.remove(event.path);
    });

    // Make sure the schedule is watching it in case it fails.
    currentSchedule.wrapFuture(future);

    futures.add(future);
  }

  // Schedule it so that later file modifications don't occur until after this
  // event is received.
  schedule(() => Future.wait(futures),
      "wait for $type events on ${paths.join(', ')}");
}

void expectAddEvent(String path) => expectEvents(ChangeType.ADD, [path]);
void expectModifyEvent(String path) => expectEvents(ChangeType.MODIFY, [path]);
void expectRemoveEvent(String path) => expectEvents(ChangeType.REMOVE, [path]);

void expectRemoveEvents(Iterable<String> paths) {
  expectEvents(ChangeType.REMOVE, paths);
}

/// Schedules writing a file in the sandbox at [path] with [contents].
///
/// If [contents] is omitted, creates an empty file. If [updatedModified] is
/// `false`, the mock file modification time is not changed.
void writeFile(String path, {String contents, bool updateModified}) {
  if (contents == null) contents = "";
  if (updateModified == null) updateModified = true;

  schedule(() {
    var fullPath = p.join(_sandboxDir, path);

    // Create any needed subdirectories.
    var dir = new Directory(p.dirname(fullPath));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    new File(fullPath).writeAsStringSync(contents);

    // Manually update the mock modification time for the file.
    if (updateModified) {
      // Make sure we always use the same separator on Windows.
      path = p.normalize(path);

      var milliseconds = _mockFileModificationTimes.putIfAbsent(path, () => 0);
      _mockFileModificationTimes[path]++;
    }
  }, "write file $path");
}

/// Schedules deleting a file in the sandbox at [path].
void deleteFile(String path) {
  schedule(() {
    new File(p.join(_sandboxDir, path)).deleteSync();
  }, "delete file $path");
}

/// Schedules renaming a file in the sandbox from [from] to [to].
///
/// If [contents] is omitted, creates an empty file.
void renameFile(String from, String to) {
  schedule(() {
    new File(p.join(_sandboxDir, from)).renameSync(p.join(_sandboxDir, to));

    // Make sure we always use the same separator on Windows.
    to = p.normalize(to);

    // Manually update the mock modification time for the file.
    var milliseconds = _mockFileModificationTimes.putIfAbsent(to, () => 0);
    _mockFileModificationTimes[to]++;
  }, "rename file $from to $to");
}

/// Schedules deleting a directory in the sandbox at [path].
void deleteDir(String path) {
  schedule(() {
    new Directory(p.join(_sandboxDir, path)).deleteSync(recursive: true);
  }, "delete directory $path");
}

/// A [Matcher] for [WatchEvent]s.
class _ChangeMatcher extends Matcher {
  /// The expected change.
  final ChangeType type;

  /// The expected path.
  final String path;

  _ChangeMatcher(this.type, this.path);

  Description describe(Description description) {
    description.add("$type $path");
  }

  bool matches(item, Map matchState) =>
      item is WatchEvent &&
      item.type == type &&
      p.normalize(item.path) == p.normalize(path);
}
