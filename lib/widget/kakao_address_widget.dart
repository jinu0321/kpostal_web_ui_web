import 'dart:async';
import 'dart:html' as html;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:js/js_util.dart' as js;
import 'package:kpostal_web/model/kakao_address.dart';
import 'package:kpostal_web/util/js_util.dart';
import 'package:uuid/v1.dart';
import 'package:uuid/v4.dart';

class KakaoAddressWidget extends StatefulWidget {
  final ValueChanged<KakaoAddress> onComplete;
  final VoidCallback onClose;

  const KakaoAddressWidget({
    super.key,
    required this.onComplete,
    required this.onClose,
  });

  @override
  State<KakaoAddressWidget> createState() => _KakaoAddressWidgetState();
}

class _KakaoAddressWidgetState extends State<KakaoAddressWidget> {
  html.DivElement? divElement;

  Timer? timer;

  @override
  void initState() {
    super.initState();

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      'div-kpostal_layer',
      (int viewId) {
        final divElementLocal = html.DivElement();
        divElementLocal.id = 'kpostal_layer';
        divElementLocal.style.display = 'none';
        divElementLocal.style.position = 'fixed';
        divElementLocal.style.overflow = 'hidden';
        divElementLocal.style.zIndex = '1';

        divElement = divElementLocal;
        return divElementLocal;
      },
    );

    timer = Timer(const Duration(seconds: 1), () async {
      final jsUtil = JsUtil();
      await jsUtil.importUrl(
          url: '//t1.daumcdn.net/mapjsapi/bundle/postcode/prod/postcode.v2.js');

      try {
        js.setProperty(
            js.globalThis, 'onSelectAddress', js.allowInterop(onComplete));
      } catch (e) {}
      const jsCode = '''
  var element_layer = document.getElementById('kpostal_layer');
  function showDaumPostCode() {
      new daum.Postcode({
          oncomplete: function(data) {
              onSelectAddress(data);
          },
          width : '100%',
          height : '100%',
          maxSuggestItems : 5
      }).embed(element_layer);
  
      // iframe을 넣은 element를 보이게 한다.
      element_layer.style.display = 'block';
  }
    ''';
      jsUtil.eval(jsCode);
      jsUtil.call(methodName: 'showDaumPostCode');
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    timer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const HtmlElementView(viewType: 'div-kpostal_layer');
  }

  void onComplete(dynamic data) {
    widget.onClose();
    widget.onComplete(KakaoAddress.fromJson(js.dartify(data) as Map));
  }
}
