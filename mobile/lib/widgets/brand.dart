import 'package:flutter/material.dart';

import '../models/session.dart';
import '../theme/app_theme.dart';

/// Logo de Consware (símbolo vectorial + nombre), dibujado para verse nítido en cualquier tamaño.
class ConswareLogo extends StatelessWidget {
  const ConswareLogo({super.key, this.height = 30, this.color = AppColors.navy});

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: Size(height * 1.56, height),
          painter: _LogoMarkPainter(color),
        ),
        SizedBox(width: height * 0.28),
        Text(
          'Consware',
          style: TextStyle(
            fontSize: height * 0.9,
            fontWeight: FontWeight.w600,
            color: color,
            letterSpacing: -0.4,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _LogoMarkPainter extends CustomPainter {
  const _LogoMarkPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Diseño en una cuadrícula de 156 x 100 escalada al tamaño pedido.
    canvas.scale(size.width / 156, size.height / 100);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final check = Path()
      ..moveTo(14, 40)
      ..lineTo(42, 84)
      ..lineTo(90, 30);
    canvas.drawPath(check, stroke);
    canvas.drawLine(const Offset(90, 86), const Offset(140, 28), stroke);
    canvas.drawCircle(const Offset(52, 11), 10, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_LogoMarkPainter oldDelegate) => oldDelegate.color != color;
}

/// Fondo azul claro con montañas y nubes en la esquina superior, como en el diseño.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE3EEFD), AppColors.background],
                stops: [0, 0.45],
              ),
            ),
          ),
        ),
        Positioned(
          top: 58,
          right: -16,
          child: IgnorePointer(
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Colors.transparent, Colors.white],
                stops: [0, 0.45],
              ).createShader(bounds),
              child: const CustomPaint(size: Size(300, 230), painter: _MountainPainter()),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _MountainPainter extends CustomPainter {
  const _MountainPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;

    Path polygon(List<(double, double)> points) {
      final path = Path()..moveTo(points.first.$1 * w, points.first.$2 * h);
      for (final (x, y) in points.skip(1)) {
        path.lineTo(x * w, y * h);
      }
      return path..close();
    }

    Shader vertical(List<Color> colors, [List<double>? stops]) => LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
          stops: stops,
        ).createShader(rect);

    final cloud = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.42, h * 0.18), width: w * 0.28, height: h * 0.08), cloud);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.86, h * 0.12), width: w * 0.3, height: h * 0.08), cloud);

    // Cordillera lejana.
    canvas.drawPath(
      polygon([(0.2, 1), (0.4, 0.6), (0.5, 0.66), (0.6, 0.52), (0.7, 0.58), (0.84, 0.44), (1, 0.52), (1, 1)]),
      Paint()..shader = vertical(const [Color(0xFFCBDDF6), Color(0x00CBDDF6)], const [0.3, 1]),
    );

    // Montaña principal.
    canvas.drawPath(
      polygon([
        (0.32, 1), (0.48, 0.64), (0.55, 0.55), (0.6, 0.46), (0.66, 0.3), (0.7, 0.24),
        (0.74, 0.31), (0.79, 0.36), (0.86, 0.48), (0.93, 0.54), (1, 0.6), (1, 1),
      ]),
      Paint()..shader = vertical(const [Color(0xFF7FA8E6), Color(0x00A6C4F0)], const [0.2, 0.95]),
    );

    // Cara en sombra (derecha) y caras con nieve (izquierda).
    canvas.drawPath(
      polygon([(0.7, 0.24), (0.74, 0.31), (0.79, 0.36), (0.86, 0.48), (0.82, 0.7), (0.74, 0.58)]),
      Paint()..shader = vertical(const [Color(0xFF5F8FDB), Color(0x005F8FDB)], const [0.25, 0.85]),
    );
    canvas.drawPath(
      polygon([(0.7, 0.24), (0.66, 0.3), (0.6, 0.46), (0.58, 0.58), (0.63, 0.47), (0.65, 0.62), (0.69, 0.42), (0.72, 0.5)]),
      Paint()
        ..shader = vertical([Colors.white, Colors.white.withValues(alpha: 0)], const [0.25, 0.7]),
    );

    // Niebla al pie de las montañas.
    final mist = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.55, h * 0.82), width: w * 0.6, height: h * 0.18), mist);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.95, h * 0.74), width: w * 0.4, height: h * 0.16), mist);
  }

  @override
  bool shouldRepaint(_MountainPainter oldDelegate) => false;
}

/// Iniciales del empleado en un círculo con degradado.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.initials, this.size = 46});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
        border: Border.all(color: Colors.white, width: size / 15),
        boxShadow: AppShadows.card,
      ),
      child: Text(
        initials,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: size / 3),
      ),
    );
  }
}

/// Cabecera de las pestañas: logo a la izquierda y el perfil del empleado a la derecha.
class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, required this.session, required this.onLogout});

  final Session session;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const ConswareLogo(height: 30),
        const Spacer(),
        Tooltip(
          message: 'Mi perfil',
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => _showProfile(context),
            child: ProfileAvatar(initials: session.initials),
          ),
        ),
      ],
    );
  }

  void _showProfile(BuildContext context) {
    final expires = session.expiresAtUtc.toLocal();
    final now = DateTime.now();
    final sameDay = expires.year == now.year && expires.month == now.month && expires.day == now.day;
    final time = '${sameDay ? 'hoy' : 'mañana'} a las '
        '${expires.hour.toString().padLeft(2, '0')}:${expires.minute.toString().padLeft(2, '0')}';

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ProfileAvatar(initials: session.initials, size: 72),
              const SizedBox(height: 12),
              Text(session.fullName, style: AppText.sectionTitle.copyWith(fontSize: 19)),
              const SizedBox(height: 2),
              Text('${session.department} · Empleado', style: AppText.subtitle),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, color: AppColors.approved),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Sesión segura activa como ${session.username}.\nVence $time.',
                        style: const TextStyle(fontSize: 13, color: AppColors.text, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    onLogout();
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Cerrar sesión'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.rejected,
                    side: const BorderSide(color: AppColors.rejectedBg, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
