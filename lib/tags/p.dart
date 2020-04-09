import 'package:flutter/material.dart';
import 'package:markdown/markdown.dart' as m;
import 'input.dart';
import 'a.dart';
import 'img.dart';
import 'code.dart';
import 'video.dart';
import 'markdown_tags.dart';
import '../config/platform.dart';
import '../config/html_support.dart';
import '../config/style_config.dart';

class P {
  P._internal();

  static P _instance;

  factory P() {
    _instance ??= P._internal();
    return _instance;
  }

  ///Tag:  p
  Widget getPWidget(List<m.Node> children,
          {TextStyle textStyle, bool selectable = true}) =>
      isWeb()
          ? buildWebRichText(children, textStyle, selectable)
          : buildRichText(children, textStyle, selectable);

  bool isWeb() {
    return !PlatformDetector().isMobile();
  }

  ///see this issue:https://github.com/flutter/flutter/issues/42086
  ///flutter web can't use WidgetSpan now.so this is another solution
  ///you can also use this in mobile，but it will finally be replaced by [buildRichText]
  Widget buildWebRichText(
    List<m.Node> nodes,
    TextStyle style,
    bool selectable,
  ) {
    if (nodes == null) return Container();
    List<Widget> children = [];
    final config = StyleConfig()?.pConfig;
    buildBlockWidgets(
        nodes,
        style ?? config?.textStyle ?? defaultPStyle,
        children,
        selectable);
    return Wrap(
      children: children,
      crossAxisAlignment: config?.wrapCrossAlignment ?? WrapCrossAlignment.center,
    );
  }

  RichText buildRichText(
          List<m.Node> children, TextStyle textStyle, bool selectable) =>
      RichText(
        softWrap: false,
        text: getBlockSpan(
          children,
          textStyle ?? StyleConfig()?.pConfig?.textStyle ?? defaultPStyle,
          selectable: selectable,
        ),
      );

  InlineSpan getBlockSpan(List<m.Node> nodes, TextStyle parentStyle,
      {bool selectable = true}) {
    if (nodes == null || nodes.isEmpty) return TextSpan();
    return TextSpan(
      children: List.generate(
        nodes.length,
        (index) {
          final node = nodes[index];
          if (node is m.Text)
            return buildTextSpan(selectable, node, parentStyle);
          else if (node is m.Element) {
            if (node.tag == code) return getCodeSpan(node, defaultCodeStyle);
            if (node.tag == img) return getImageSpan(node);
            if (node.tag == video) return getVideoSpan(node);
            if (node.tag == a) return getLinkSpan(node);
            if (node.tag == input) return getInputSpan(node);
            return getBlockSpan(
                node.children, parentStyle.merge(getTextStyle(node.tag)));
          }
          return TextSpan();
        },
      ),
    );
  }

  InlineSpan buildTextSpan(
      bool selectable, m.Text node, TextStyle parentStyle) {
    final nodes = parseHtml(node);
    if (nodes.isEmpty) {
      return selectable
          ? WidgetSpan(child: SelectableText(node.text, style: parentStyle))
          : TextSpan(text: node.text, style: parentStyle);
    } else {
      return getBlockSpan(nodes, parentStyle, selectable: selectable);
    }
  }

  void buildBlockWidgets(List<m.Node> nodes, TextStyle parentStyle,
      List<Widget> widgets, bool selectable) {
    if (nodes == null || nodes.isEmpty) return;
    nodes.forEach((node) {
      if (node is m.Text)
        buildWebTextWidget(widgets, selectable, node, parentStyle);
      else if (node is m.Element) {
        if (node.tag == code)
          widgets.add(defaultCodeWidget(node, defaultCodeStyle));
        else if (node.tag == img)
          widgets.add(defaultImageWidget(node.attributes));
        else if (node.tag == video)
          widgets.add(defaultVideoWidget(node.attributes));
        else if (node.tag == a)
          widgets.add(defaultAWidget(node));
        else if (node.tag == input)
          widgets.add(defaultCheckBox(node.attributes));
        else
          buildBlockWidgets(node.children,
              parentStyle.merge(getTextStyle(node.tag)), widgets, selectable);
      }
    });
  }

  void buildWebTextWidget(List<Widget> widgets, bool selectable, m.Text node,
      TextStyle parentStyle) {
    final nodes = parseHtml(node);
    if (nodes.isEmpty) {
      widgets.add(selectable
          ? SelectableText(node.text, style: parentStyle)
          : Text(node.text, style: parentStyle));
    } else {
      widgets.add(
          getPWidget(nodes, textStyle: parentStyle, selectable: selectable));
    }
  }
}

class PConfig {
  final TextStyle textStyle;
  final TextStyle linkStyle;
  final TextStyle codeStyle;
  final TextStyle delStyle;
  final TextStyle emStyle;
  final TextStyle strongStyle;

  final CodeWidget codeWidget;
  final OnLinkTap onLinkTap;
  final WrapCrossAlignment wrapCrossAlignment;

  PConfig({
    this.textStyle,
    this.linkStyle,
    this.codeStyle,
    this.codeWidget,
    this.delStyle,
    this.emStyle,
    this.strongStyle,
    this.onLinkTap,
    this.wrapCrossAlignment,
  });
}

typedef Widget CodeWidget(String text);
typedef void OnLinkTap(
  String url,
);
