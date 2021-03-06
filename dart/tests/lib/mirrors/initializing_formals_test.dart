// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.initializing_formals;

import 'dart:mirrors';
import 'package:expect/expect.dart';

class Class<T> {
  int intField;
  bool boolField;
  String stringField;
  T tField;
  dynamic _privateField;

  Class.nongeneric(this.intField);
  Class.named({this.boolField});
  Class.optPos([this.stringField = 'default']);
  Class.generic(this.tField);
  Class.private(this._privateField);

  Class.explicitType(num this.intField);
  Class.withVar(var this.intField);
  Class.withDynamic(dynamic this.intField);
}

class Constant {
  final num value;
  const Constant(this.value);
  const Constant.marked(final this.value);
}

main() {
  ParameterMirror pm;

  pm = reflectClass(Class).constructors[#Class.nongeneric].parameters.single;
  Expect.equals(#intField, pm.simpleName);
  Expect.equals(reflectClass(int), pm.type);
  Expect.isFalse(pm.isNamed);  /// 01: ok
  Expect.isFalse(pm.isFinal);  /// 01: ok
  Expect.isFalse(pm.isOptional);  /// 01: ok
  Expect.isFalse(pm.hasDefaultValue);  /// 01: ok
  Expect.isFalse(pm.isPrivate);
  Expect.isFalse(pm.isStatic);
  Expect.isFalse(pm.isTopLevel);
  
  pm = reflectClass(Class).constructors[#Class.named].parameters.single;
  Expect.equals(#boolField, pm.simpleName);
  Expect.equals(reflectClass(bool), pm.type);
  Expect.isTrue(pm.isNamed);  /// 01: ok
  Expect.isFalse(pm.isFinal);  /// 01: ok
  Expect.isTrue(pm.isOptional);  /// 01: ok
  Expect.isFalse(pm.hasDefaultValue);  /// 01: ok
  Expect.isFalse(pm.isPrivate);
  Expect.isFalse(pm.isStatic);
  Expect.isFalse(pm.isTopLevel);

  pm = reflectClass(Class).constructors[#Class.optPos].parameters.single;
  Expect.equals(#stringField, pm.simpleName);
  Expect.equals(reflectClass(String), pm.type);
  Expect.isFalse(pm.isNamed);  /// 01: ok
  Expect.isFalse(pm.isFinal);  /// 01: ok
  Expect.isTrue(pm.isOptional);  /// 01: ok
  Expect.isTrue(pm.hasDefaultValue);  /// 01: ok
  Expect.equals('default', pm.defaultValue.reflectee);  /// 01: ok
  Expect.isFalse(pm.isPrivate);
  Expect.isFalse(pm.isStatic);
  Expect.isFalse(pm.isTopLevel);
  
  pm = reflectClass(Class).constructors[#Class.generic].parameters.single;
  Expect.equals(#tField, pm.simpleName);
  Expect.equals(reflectClass(Class).typeVariables.single, pm.type);  /// 02: ok
  Expect.isFalse(pm.isNamed);  /// 01: ok
  Expect.isFalse(pm.isFinal);  /// 01: ok
  Expect.isFalse(pm.isOptional);  /// 01: ok
  Expect.isFalse(pm.hasDefaultValue);  /// 01: ok
  Expect.isFalse(pm.isPrivate);
  Expect.isFalse(pm.isStatic);
  Expect.isFalse(pm.isTopLevel);

  pm = reflectClass(Class).constructors[#Class.private].parameters.single;
  Expect.equals(#_privateField, pm.simpleName);  /// 03: ok
  Expect.equals(currentMirrorSystem().dynamicType, pm.type);
  Expect.isFalse(pm.isNamed);  /// 01: ok
  Expect.isFalse(pm.isFinal);  /// 01: ok
  Expect.isFalse(pm.isOptional);  /// 01: ok
  Expect.isFalse(pm.hasDefaultValue);  /// 01: ok
  Expect.isTrue(pm.isPrivate);
  Expect.isFalse(pm.isStatic);
  Expect.isFalse(pm.isTopLevel);

  pm = reflectClass(Class).constructors[#Class.explicitType].parameters.single;
  Expect.equals(#intField, pm.simpleName);
  Expect.equals(reflectClass(num), pm.type);
  Expect.isFalse(pm.isNamed);  /// 01: ok
  Expect.isFalse(pm.isFinal);  /// 01: ok
  Expect.isFalse(pm.isOptional);  /// 01: ok
  Expect.isFalse(pm.hasDefaultValue);  /// 01: ok
  Expect.isFalse(pm.isPrivate);
  Expect.isFalse(pm.isStatic);
  Expect.isFalse(pm.isTopLevel);

  pm = reflectClass(Class).constructors[#Class.withVar].parameters.single;
  Expect.equals(#intField, pm.simpleName);
  Expect.equals(reflectClass(int), pm.type);  // N.B.   /// 02: ok
  Expect.isFalse(pm.isNamed);  /// 01: ok
  Expect.isFalse(pm.isFinal);  /// 01: ok
  Expect.isFalse(pm.isOptional);  /// 01: ok
  Expect.isFalse(pm.hasDefaultValue);  /// 01: ok
  Expect.isFalse(pm.isPrivate);
  Expect.isFalse(pm.isStatic);
  Expect.isFalse(pm.isTopLevel);

  pm = reflectClass(Class).constructors[#Class.withDynamic].parameters.single;
  Expect.equals(#intField, pm.simpleName);
  Expect.equals(currentMirrorSystem().dynamicType, pm.type);  // N.B.
  Expect.isFalse(pm.isNamed);  /// 01: ok
  Expect.isFalse(pm.isFinal);  /// 01: ok
  Expect.isFalse(pm.isOptional);  /// 01: ok
  Expect.isFalse(pm.hasDefaultValue);  /// 01: ok
  Expect.isFalse(pm.isPrivate);
  Expect.isFalse(pm.isStatic);
  Expect.isFalse(pm.isTopLevel);

  pm = reflectClass(Constant).constructors[#Constant].parameters.single;
  Expect.equals(#value, pm.simpleName);
  Expect.equals(reflectClass(num), pm.type);
  Expect.isFalse(pm.isNamed);  /// 01: ok
  Expect.isFalse(pm.isFinal);  // N.B.  /// 01: ok
  Expect.isFalse(pm.isOptional);  /// 01: ok
  Expect.isFalse(pm.hasDefaultValue);  /// 01: ok
  Expect.isFalse(pm.isPrivate);
  Expect.isFalse(pm.isStatic);
  Expect.isFalse(pm.isTopLevel);

  pm = reflectClass(Constant).constructors[#Constant.marked].parameters.single;
  Expect.equals(#value, pm.simpleName);
  Expect.equals(reflectClass(num), pm.type);
  Expect.isFalse(pm.isNamed);  /// 01: ok
  Expect.isTrue(pm.isFinal);  // N.B.  /// 01: ok
  Expect.isFalse(pm.isOptional);  /// 01: ok
  Expect.isFalse(pm.hasDefaultValue);  /// 01: ok
  Expect.isFalse(pm.isPrivate);
  Expect.isFalse(pm.isStatic);
  Expect.isFalse(pm.isTopLevel);
}
