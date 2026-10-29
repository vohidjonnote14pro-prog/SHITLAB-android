import 'package:flutter/material.dart';

import '../theme.dart';

class Header extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool back;
  final List<Widget> actions;

  const Header({
    super.key,
    required this.title,
    this.subtitle,
    this.back = true,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(back ? 4 : 20, 8, 12, 8),
      child: Row(
        children: [
          if (back)
            IconButton(
              tooltip: 'Orqaga',
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: C.text),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: C.text),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: C.muted),
                  ),
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

class Box extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color border;
  final double radius;

  const Box({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = C.card,
    this.border = C.line,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border),
      ),
      child: child,
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: C.muted, letterSpacing: 1),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color color;
  final Color textColor;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.color = C.amber,
    this.textColor = C.ink,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onTap == null ? C.line : color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          height: 54,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: onTap == null ? C.muted : textColor),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: onTap == null ? C.muted : textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color color;

  const GhostButton({super.key, required this.label, this.onTap, this.icon, this.color = C.text});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF343D4D)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          height: 54,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 19, color: color),
                const SizedBox(width: 8),
              ],
              Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

class Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Color? accent;
  final bool monoText;
  final Widget? leading;

  const Pill({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.accent,
    this.monoText = false,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final a = accent ?? C.amber;
    final disabled = onTap == null;
    return Opacity(
      opacity: disabled && !selected ? 0.4 : 1,
      child: Material(
        color: selected ? C.amberSoft : C.bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: selected ? C.amber : C.line2, width: selected ? 1.5 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 6)],
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: monoText ? monoFont : null,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? a : C.text2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class KV extends StatelessWidget {
  final String k;
  final String v;
  final Color? vColor;
  final bool last;

  const KV(this.k, this.v, {super.key, this.vColor, this.last = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: last ? null : const Border(bottom: BorderSide(color: Color(0xFF222936))),
      ),
      child: Row(
        children: [
          Expanded(child: Text(k, style: const TextStyle(fontSize: 14, color: C.text2))),
          Text(v, style: mono(15, color: vColor ?? C.text)),
        ],
      ),
    );
  }
}

class StatusBox extends StatelessWidget {
  final bool ok;
  final String title;
  final String text;

  const StatusBox({super.key, required this.ok, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ok ? C.okSoft : C.badSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(ok ? Icons.check_circle_outline : Icons.error_outline,
              color: ok ? const Color(0xFF5FD39A) : C.badText),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700, color: ok ? C.okText : C.badText)),
                const SizedBox(height: 2),
                Text(text, style: const TextStyle(fontSize: 12.5, color: C.soft, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PhaseBar extends StatelessWidget {
  final String phase;
  final double current;
  final double max;
  final Color track;
  final Color? fill;
  final Color labelColor;

  const PhaseBar({
    super.key,
    required this.phase,
    required this.current,
    required this.max,
    this.track = C.bg,
    this.fill,
    this.labelColor = C.text,
  });

  @override
  Widget build(BuildContext context) {
    final f = max <= 0 ? 0.0 : (current / max).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(width: 26, child: Text(phase, style: mono(12, color: fill ?? C.phase(phase)))),
        Expanded(
          child: Container(
            height: 9,
            decoration: BoxDecoration(color: track, borderRadius: BorderRadius.circular(5)),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: f,
              child: Container(
                decoration: BoxDecoration(
                  color: fill ?? C.phase(phase),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          width: 66,
          child: Text('${current.toStringAsFixed(1).replaceAll('.', ',')} A',
              textAlign: TextAlign.right, style: mono(12, color: labelColor)),
        ),
      ],
    );
  }
}

void soon(BuildContext context, String what, int stage) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$what — $stage-bosqichda qo\'shiladi')),
  );
}
