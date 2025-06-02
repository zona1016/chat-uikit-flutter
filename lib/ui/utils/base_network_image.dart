import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:path/path.dart' as p;


class BaseNetworkImage extends StatelessWidget {
  final String imageURL;
  final double radius;
  final String placeholder;
  final double? height;
  final double? width;
  final BoxFit fit;
  final Color? color;
  final bool isTransparent;

  const BaseNetworkImage({
    super.key,
    required this.imageURL,
    this.radius = 0,
    this.placeholder = "assets/image/base/logo.png",
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.isTransparent = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
      ),
      clipBehavior: Clip.hardEdge,
      height: height,
      width: width,
      child: p.extension(imageURL).toLowerCase() == '.svg'
          ? SvgPicture.network(
              imageURL,
              fit: fit,
              color: color,
              placeholderBuilder: (BuildContext context) =>
                  Image.asset(placeholder),
            )
          : ExtendedImage.network(
              imageURL,
              fit: fit,
              cache: true,
              gaplessPlayback: true,
              color: color,
              enableMemoryCache: true,
              loadStateChanged: (ExtendedImageState state) {
                switch (state.extendedImageLoadState) {
                  case LoadState.loading:
                    return Container();
                  case LoadState.completed:
                    return null;
                  case LoadState.failed:
                    return isTransparent
                        ? Container()
                        : Image.asset(
                            gaplessPlayback: true,
                            placeholder,
                            fit: fit,
                          );
                }
              },
            ),
    );
  }
}
