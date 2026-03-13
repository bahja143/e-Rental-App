import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

class RemoteImage extends StatefulWidget {
  const RemoteImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;

  @override
  State<RemoteImage> createState() => _RemoteImageState();
}

class _RemoteImageState extends State<RemoteImage> {
  late Future<_RemoteImageData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant RemoteImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _future = _load();
    }
  }

  Future<_RemoteImageData> _load() async {
    final uri = Uri.parse(widget.url);
    final bytesData = await NetworkAssetBundle(uri).load(uri.toString());
    final bytes = bytesData.buffer.asUint8List();
    final probeLength = bytes.length > 300 ? 300 : bytes.length;
    final probe = utf8.decode(bytes.sublist(0, probeLength), allowMalformed: true).trimLeft();
    final isSvg = probe.startsWith('<svg') || probe.startsWith('<?xml');
    return _RemoteImageData(bytes: bytes, isSvg: isSvg);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_RemoteImageData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return widget.placeholder ??
              Container(
                width: widget.width,
                height: widget.height,
                color: const Color(0xFFF5F4F8),
              );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return widget.errorWidget ??
              Container(
                width: widget.width,
                height: widget.height,
                color: const Color(0xFFF5F4F8),
              );
        }

        final data = snapshot.data!;
        if (data.isSvg) {
          return SvgPicture.memory(
            data.bytes,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
          );
        }

        return Image.memory(
          data.bytes,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          gaplessPlayback: true,
        );
      },
    );
  }
}

class _RemoteImageData {
  const _RemoteImageData({
    required this.bytes,
    required this.isSvg,
  });

  final Uint8List bytes;
  final bool isSvg;
}
