// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library observatory_element;

import 'package:polymer/polymer.dart';
import 'package:observatory/observatory.dart';
export 'package:observatory/observatory.dart';

/// Base class for all custom elements. Holds an observable
/// [ObservableApplication] and applies author styles.
@CustomTag('observatory-element')
class ObservatoryElement extends PolymerElement {
  @published ObservatoryApplication get app => __$app; ObservatoryApplication __$app; set app(ObservatoryApplication value) { __$app = notifyPropertyChange(#app, __$app, value); }
  bool get applyAuthorStyles => true;
}