// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library template_binding.test.custom_element_bindings_test;

import 'dart:async';
import 'dart:html';
import 'package:custom_element/polyfill.dart';
import 'package:template_binding/template_binding.dart';
import 'package:observe/observe.dart' show toObservable;
import 'package:unittest/html_config.dart';
import 'package:unittest/unittest.dart';
import 'utils.dart';

Future _registered;

main() {
  useHtmlConfiguration();

  _registered = loadCustomElementPolyfill().then((_) {
    document.register('my-custom-element', MyCustomElement);
    document.register('with-attrs-custom-element', WithAttrsCustomElement);
  });

  group('Custom Element Bindings', customElementBindingsTest);
}

customElementBindingsTest() {
  setUp(() {
    document.body.append(testDiv = new DivElement());
    return _registered;
  });

  tearDown(() {
    testDiv.remove();
    testDiv = null;
  });

  observeTest('override bind/unbind/unbindAll', () {
    var element = new MyCustomElement();
    var model = toObservable({'a': new Point(123, 444), 'b': new Monster(100)});

    nodeBind(element)
        ..bind('my-point', model, 'a')
        ..bind('scary-monster', model, 'b');

    expect(element.attributes, isNot(contains('my-point')));
    expect(element.attributes, isNot(contains('scary-monster')));

    expect(element.myPoint, model['a']);
    expect(element.scaryMonster, model['b']);

    model['a'] = null;
    performMicrotaskCheckpoint();
    expect(element.myPoint, null);
    nodeBind(element).unbind('my-point');

    model['a'] = new Point(1, 2);
    model['b'] = new Monster(200);
    performMicrotaskCheckpoint();
    expect(element.scaryMonster, model['b']);
    expect(element.myPoint, null, reason: 'a was unbound');

    nodeBind(element).unbindAll();
    model['b'] = null;
    performMicrotaskCheckpoint();
    expect(element.scaryMonster.health, 200);
  });

  observeTest('override attribute setter', () {
    var element = new WithAttrsCustomElement();
    var model = toObservable({'a': 1, 'b': 2});
    nodeBind(element).bind('hidden?', model, 'a');
    nodeBind(element).bind('id', model, 'b');

    expect(element.attributes, contains('hidden'));
    expect(element.attributes['hidden'], '');
    expect(element.id, '2');

    model['a'] = null;
    performMicrotaskCheckpoint();
    expect(element.attributes, isNot(contains('hidden')),
        reason: 'null is false-y');

    model['a'] = false;
    performMicrotaskCheckpoint();
    expect(element.attributes, isNot(contains('hidden')));

    model['a'] = 'foo';
    // TODO(jmesserly): this is here to force an ordering between the two
    // changes. Otherwise the order depends on what order StreamController
    // chooses to fire the two listeners in.
    performMicrotaskCheckpoint();

    model['b'] = 'x';
    performMicrotaskCheckpoint();
    expect(element.attributes, contains('hidden'));
    expect(element.attributes['hidden'], '');
    expect(element.id, 'x');

    expect(element.attributes.log, [
      ['remove', 'hidden?'],
      ['[]=', 'hidden', ''],
      ['[]=', 'id', '2'],
      ['remove', 'hidden'],
      ['remove', 'hidden'],
      ['[]=', 'hidden', ''],
      ['[]=', 'id', 'x'],
    ]);
  });

  observeTest('template bind uses overridden custom element bind', () {

    var model = toObservable({'a': new Point(123, 444), 'b': new Monster(100)});
    var div = createTestHtml('<template bind>'
          '<my-custom-element my-point="{{a}}" scary-monster="{{b}}">'
          '</my-custom-element>'
        '</template>');

    templateBind(div.query('template')).model = model;
    performMicrotaskCheckpoint();

    var element = div.nodes[1];

    expect(element is MyCustomElement, true,
        reason: '${element} should be a MyCustomElement');

    expect(element.myPoint, model['a']);
    expect(element.scaryMonster, model['b']);

    expect(element.attributes, isNot(contains('my-point')));
    expect(element.attributes, isNot(contains('scary-monster')));

    model['a'] = null;
    performMicrotaskCheckpoint();
    expect(element.myPoint, null);

    templateBind(div.query('template')).model = null;
    performMicrotaskCheckpoint();

    expect(element.parentNode, null, reason: 'element was detached');

    model['a'] = new Point(1, 2);
    model['b'] = new Monster(200);
    performMicrotaskCheckpoint();

    expect(element.myPoint, null, reason: 'model was unbound');
    expect(element.scaryMonster.health, 100, reason: 'model was unbound');
  });

}

class Monster {
  int health;
  Monster(this.health);
}

/** Demonstrates a custom element overriding bind/unbind/unbindAll. */
class MyCustomElement extends HtmlElement implements NodeBindExtension {
  Point myPoint;
  Monster scaryMonster;

  factory MyCustomElement() => new Element.tag('my-custom-element');

  MyCustomElement.created() : super.created();

  NodeBinding bind(String name, model, [String path]) {
    switch (name) {
      case 'my-point':
      case 'scary-monster':
        attributes.remove(name);
        unbind(name);
        return bindings[name] = new _MyCustomBinding(this, name, model, path);
    }
    return nodeBindFallback(this).bind(name, model, path);
  }

  unbind(name) => nodeBindFallback(this).unbind(name);
  unbindAll() => nodeBindFallback(this).unbindAll();
  get bindings => nodeBindFallback(this).bindings;
}

class _MyCustomBinding extends NodeBinding {
  _MyCustomBinding(MyCustomElement node, property, model, path)
      : super(node, property, model, path) {

    node.attributes.remove(property);
  }

  MyCustomElement get node => super.node;

  void valueChanged(newValue) {
    if (property == 'my-point') node.myPoint = newValue;
    if (property == 'scary-monster') node.scaryMonster = newValue;
  }
}


/**
 * Demonstrates a custom element can override attributes []= and remove.
 * and see changes that the data binding system is making to the attributes.
 */
class WithAttrsCustomElement extends HtmlElement {
  AttributeMapWrapper _attributes;

  factory WithAttrsCustomElement() =>
      new Element.tag('with-attrs-custom-element');

  WithAttrsCustomElement.created() : super.created() {
    _attributes = new AttributeMapWrapper(super.attributes);
  }

  get attributes => _attributes;
}

// TODO(jmesserly): would be nice to use mocks when mirrors work on dart2js.
class AttributeMapWrapper<K, V> implements Map<K, V> {
  final List log = [];
  Map<K, V> _map;

  AttributeMapWrapper(this._map);

  bool containsValue(Object value) => _map.containsValue(value);
  bool containsKey(Object key) => _map.containsKey(key);
  V operator [](Object key) => _map[key];

  void operator []=(K key, V value) {
    log.add(['[]=', key, value]);
    _map[key] = value;
  }

  V putIfAbsent(K key, V ifAbsent()) => _map.putIfAbsent(key, ifAbsent);

  V remove(Object key) {
    log.add(['remove', key]);
    _map.remove(key);
  }

  void addAll(Map<K, V> other) => _map.addAll(other);
  void clear() => _map.clear();
  void forEach(void f(K key, V value)) => _map.forEach(f);
  Iterable<K> get keys => _map.keys;
  Iterable<V> get values => _map.values;
  int get length => _map.length;
  bool get isEmpty => _map.isEmpty;
  bool get isNotEmpty => _map.isNotEmpty;
}
