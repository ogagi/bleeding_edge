// Copyright (c) 2013, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that secure connections that fail due to
// unauthenticated certificates throw exceptions in HttpClient.

import "package:expect/expect.dart";
import "package:path/path.dart";
import "dart:async";
import "dart:io";

const HOST_NAME = "localhost";
const CERTIFICATE = "localhost_cert";

Future<SecureServerSocket> runServer() {
  SecureSocket.initialize(
      database: join(dirname(Platform.script), 'pkcert'),
      password: 'dartdart');

  return HttpServer.bindSecure(
      HOST_NAME, 0, backlog: 5, certificateName: 'localhost_cert')
  .then((server) {
    server.listen((HttpRequest request) {
      request.listen((_) { }, onDone: () { request.response.close(); });
    }, onError: (e) { if (e is! HandshakeException) throw e; });
    return server;
  });
}

void main() {
  var clientScript = join(dirname(Platform.script),
                          'https_unauthorized_client.dart');

  Future clientProcess(int port) {
    return Process.run(Platform.executable,
        [clientScript, port.toString()])
    .then((ProcessResult result) {
      if (result.exitCode != 0 || !result.stdout.contains('SUCCESS')) {
        print("Client failed");
        print("  stdout:");
        print(result.stdout);
        print("  stderr:");
        print(result.stderr);
        Expect.fail('Client subprocess exit code: ${result.exitCode}');
      }
    });
  }

  runServer().then((server) {
    clientProcess(server.port).then((_) {
      server.close();
    });
  });
}
