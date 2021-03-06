// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.barback.sources;

import 'dart:async';

import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;
import 'package:watcher/watcher.dart';

import '../entrypoint.dart';
import '../io.dart';
import '../package.dart';
import '../package_graph.dart';

/// Adds all of the source assets in the provided packages to barback and
/// then watches the public directories for changes.
///
/// Returns a Future that completes when the sources are loaded and the
/// watchers are active.
Future watchSources(PackageGraph graph, Barback barback) {
  return Future.wait(graph.packages.values.map((package) {
    // If this package comes from a cached source, its contents won't change so
    // we don't need to monitor it. `packageId` will be null for the application
    // package, since that's not locked.
    var packageId = graph.lockFile.packages[package.name];
    if (packageId != null &&
        graph.entrypoint.cache.sources[packageId.source].shouldCache) {
      barback.updateSources(_listAssets(graph.entrypoint, package));
      return new Future.value();
    }

    // Watch the visible package directories for changes.
    return Future.wait(_getPublicDirectories(graph.entrypoint, package)
        .map((name) {
      var subdirectory = path.join(package.dir, name);
      if (!dirExists(subdirectory)) return new Future.value();

      // TODO(nweiz): close these watchers when [barback] is closed.
      var watcher = new DirectoryWatcher(subdirectory);
      watcher.events.listen((event) {
        // Don't watch files symlinked into these directories.
        // TODO(rnystrom): If pub gets rid of symlinks, remove this.
        var parts = path.split(event.path);
        if (parts.contains("packages") || parts.contains("assets")) return;

        var id = new AssetId(package.name,
            path.relative(event.path, from: package.dir));
        if (event.type == ChangeType.REMOVE) {
          barback.removeSources([id]);
        } else {
          barback.updateSources([id]);
        }
      });
      return watcher.ready;
    })).then((_) {
      barback.updateSources(_listAssets(graph.entrypoint, package));
    });
  }));
}

/// Adds all of the source assets in the provided packages to barback.
void loadSources(PackageGraph graph, Barback barback) {
  for (var package in graph.packages.values) {
    barback.updateSources(_listAssets(graph.entrypoint, package));
  }
}

/// Lists all of the visible files in [package].
///
/// This is the recursive contents of the "asset" and "lib" directories (if
/// present). If [package] is the entrypoint package, it also includes the
/// contents of "web".
List<AssetId> _listAssets(Entrypoint entrypoint, Package package) {
  var files = <AssetId>[];

  for (var dirPath in _getPublicDirectories(entrypoint, package)) {
    var dir = path.join(package.dir, dirPath);
    if (!dirExists(dir)) continue;
    for (var entry in listDir(dir, recursive: true)) {
      // Ignore "packages" symlinks if there.
      if (path.split(entry).contains("packages")) continue;

      // Skip directories.
      if (!fileExists(entry)) continue;

      var id = new AssetId(package.name,
          path.relative(entry, from: package.dir));
      files.add(id);
    }
  }

  return files;
}

/// Gets the names of the top-level directories in [package] whose contents
/// should be provided as source assets.
Iterable<String> _getPublicDirectories(Entrypoint entrypoint, Package package) {
  var directories = ["asset", "lib"];
  if (package.name == entrypoint.root.name) directories.add("web");
  return directories;
}
