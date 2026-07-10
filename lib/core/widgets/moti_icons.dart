import 'package:flutter/widgets.dart';

/// The MoTiroong custom line-icon set.
///
/// Every glyph is a direct port of the hand-drawn inline SVGs in
/// design_handoff_app_screens (stroke-based, rounded caps/joins) so the
/// exact geometric look is preserved instead of using Material/Cupertino
/// icons. All glyphs live on a 24×24 grid except [MotiGlyph.chevron]
/// (8×14, like the source).
enum MotiGlyph {
  home,
  clock,
  exception,
  person,
  mail,
  phone,
  fingerprint,
  pin,
  appearance,
  shield,
  help,
  calendar,
  chevron,
  play,
  stop,
}

class MotiIcon extends StatelessWidget {
  const MotiIcon(
    this.glyph, {
    super.key,
    required this.color,
    this.size = 22,
    this.strokeWidth,
  });

  final MotiGlyph glyph;
  final Color color;
  final double size;
  final double? strokeWidth;

  @override
  Widget build(BuildContext context) {
    final bool isChevron = glyph == MotiGlyph.chevron;
    return CustomPaint(
      size: isChevron ? Size(size * 8 / 14, size) : Size.square(size),
      painter: _MotiIconPainter(glyph, color, strokeWidth ?? 1.8),
    );
  }
}

class _MotiIconPainter extends CustomPainter {
  const _MotiIconPainter(this.glyph, this.color, this.strokeWidth);

  final MotiGlyph glyph;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = glyph == MotiGlyph.chevron
        ? size.height / 14
        : size.width / 24;
    canvas.scale(s);

    final Paint stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final Paint fill = Paint()..color = color;

    switch (glyph) {
      case MotiGlyph.home:
        canvas.drawPath(
          Path()
            ..moveTo(4, 11.5)
            ..lineTo(12, 4)
            ..lineTo(20, 11.5),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(6, 10)
            ..lineTo(6, 19)
            ..quadraticBezierTo(6, 20, 7, 20)
            ..lineTo(11, 20)
            ..lineTo(11, 14)
            ..lineTo(13, 14)
            ..lineTo(13, 20)
            ..lineTo(17, 20)
            ..quadraticBezierTo(18, 20, 18, 19)
            ..lineTo(18, 10),
          stroke,
        );
      case MotiGlyph.clock:
        canvas.drawCircle(const Offset(12, 12), 8.5, stroke);
        canvas.drawPath(
          Path()
            ..moveTo(12, 7.5)
            ..lineTo(12, 12)
            ..lineTo(15.2, 14),
          stroke,
        );
      case MotiGlyph.exception:
        canvas.drawPath(
          Path()
            ..moveTo(12, 4.5)
            ..lineTo(21, 19.5)
            ..lineTo(3, 19.5)
            ..close(),
          stroke,
        );
        canvas.drawLine(const Offset(12, 10), const Offset(12, 14), stroke);
        canvas.drawCircle(const Offset(12, 16.8), 0.9, fill);
      case MotiGlyph.person:
        canvas.drawCircle(const Offset(12, 8.2), 3.4, stroke);
        canvas.drawPath(
          Path()
            ..moveTo(4.8, 19.5)
            ..cubicTo(6.0, 15.9, 8.8, 14.1, 12, 14.1)
            ..cubicTo(15.2, 14.1, 18, 15.9, 19.2, 19.5),
          stroke,
        );
      case MotiGlyph.mail:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(3, 5, 18, 14),
            const Radius.circular(2),
          ),
          stroke..strokeWidth = 1.7,
        );
        canvas.drawPath(
          Path()
            ..moveTo(4, 6.5)
            ..lineTo(12, 12.5)
            ..lineTo(20, 6.5),
          stroke,
        );
      case MotiGlyph.phone:
        canvas.drawPath(
          Path()
            ..moveTo(6, 3.5)
            ..cubicTo(7, 5.5, 7.7, 6.5, 9.2, 7.7)
            ..cubicTo(8.4, 9.1, 8.2, 9.7, 9.4, 11.1)
            ..cubicTo(10.6, 12.5, 11.2, 12.3, 12.6, 11.5)
            ..cubicTo(13.9, 12.7, 14.9, 13.4, 17, 14.4)
            ..cubicTo(17.4, 16, 17.1, 17, 16, 18)
            ..cubicTo(13.4, 18.8, 10, 17, 7.3, 14.3)
            ..cubicTo(4.6, 11.6, 2.8, 8.2, 3.6, 5.6)
            ..cubicTo(4.6, 4.5, 5.6, 4.2, 7.2, 4.6)
            ..close(),
          stroke..strokeWidth = 1.5,
        );
      case MotiGlyph.fingerprint:
        final Paint p = stroke..strokeWidth = 1.6;
        canvas.drawPath(
          Path()
            ..moveTo(12, 3.5)
            ..arcToPoint(
              const Offset(3.5, 12),
              radius: const Radius.circular(8.5),
              clockwise: false,
            )
            ..cubicTo(3.5, 14, 4, 15.5, 4.7, 17),
          p,
        );
        canvas.drawPath(
          Path()
            ..moveTo(12, 6.5)
            ..arcToPoint(
              const Offset(6.5, 12),
              radius: const Radius.circular(5.5),
              clockwise: false,
            )
            ..cubicTo(6.5, 14.6, 7.3, 16, 8.1, 17.2),
          p,
        );
        canvas.drawPath(
          Path()
            ..moveTo(12, 9.5)
            ..arcToPoint(
              const Offset(9.5, 12),
              radius: const Radius.circular(2.5),
              clockwise: false,
            )
            ..cubicTo(9.5, 15, 10.5, 17, 12, 19),
          p,
        );
        canvas.drawPath(
          Path()
            ..moveTo(15.5, 12)
            ..arcToPoint(
              const Offset(14.5, 14.5),
              radius: const Radius.circular(3.5),
            ),
          p,
        );
      case MotiGlyph.pin:
        canvas.drawPath(
          Path()
            ..moveTo(12, 21)
            ..cubicTo(12, 21, 19, 14.5, 19, 9.5)
            ..arcToPoint(
              const Offset(5, 9.5),
              radius: const Radius.circular(7),
              largeArc: true,
              clockwise: false,
            )
            ..cubicTo(5, 14.5, 12, 21, 12, 21)
            ..close(),
          stroke..strokeWidth = 1.6,
        );
        canvas.drawCircle(const Offset(12, 9.5), 2.3, stroke);
      case MotiGlyph.appearance:
        canvas.drawCircle(const Offset(12, 12), 8, stroke..strokeWidth = 1.7);
        canvas.drawPath(
          Path()
            ..moveTo(12, 4)
            ..arcToPoint(const Offset(12, 20), radius: const Radius.circular(8))
            ..close(),
          fill,
        );
      case MotiGlyph.shield:
        canvas.drawPath(
          Path()
            ..moveTo(12, 3.5)
            ..cubicTo(7.6, 8.5, 7.6, 8.5, 4, 7.5)
            ..cubicTo(5.5, 13, 8, 16.5, 12, 20)
            ..cubicTo(16, 16.5, 18.5, 13, 20, 7.5)
            ..cubicTo(16.4, 8.5, 16.4, 8.5, 12, 3.5)
            ..close(),
          stroke..strokeWidth = 1.6,
        );
      case MotiGlyph.help:
        canvas.drawCircle(const Offset(12, 12), 8.5, stroke..strokeWidth = 1.7);
        canvas.drawPath(
          Path()
            ..moveTo(9.7, 9.3)
            ..arcToPoint(
              const Offset(14.1, 10.2),
              radius: const Radius.circular(2.3),
            )
            ..cubicTo(14.1, 11.8, 12, 12, 12, 13.5),
          stroke,
        );
        canvas.drawCircle(const Offset(12, 16.7), 0.9, fill);
      case MotiGlyph.calendar:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(3, 5, 18, 16),
            const Radius.circular(2.5),
          ),
          stroke,
        );
        canvas.drawLine(const Offset(3, 10), const Offset(21, 10), stroke);
        canvas.drawLine(const Offset(8, 3), const Offset(8, 7), stroke);
        canvas.drawLine(const Offset(16, 3), const Offset(16, 7), stroke);
      case MotiGlyph.chevron:
        canvas.drawPath(
          Path()
            ..moveTo(1, 1)
            ..lineTo(7, 7)
            ..lineTo(1, 13),
          stroke,
        );
      case MotiGlyph.play:
        canvas.drawPath(
          Path()
            ..moveTo(9, 6)
            ..lineTo(18.5, 12)
            ..lineTo(9, 18)
            ..close(),
          fill,
        );
      case MotiGlyph.stop:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(5.5, 5.5, 13, 13),
            const Radius.circular(2.7),
          ),
          fill,
        );
    }
  }

  @override
  bool shouldRepaint(_MotiIconPainter oldDelegate) =>
      oldDelegate.glyph != glyph ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}
