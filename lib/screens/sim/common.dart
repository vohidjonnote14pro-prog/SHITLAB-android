import 'package:flutter/material.dart';

import '../../calc.dart';
import '../../models.dart';
import '../../theme.dart';
import 'instruments.dart';
import 'placement.dart';
import 'simulation.dart';
import 'thermal.dart';
import 'view3d.dart';
import 'wiring.dart';

/// Shitdagi bitta apparat (simulyatsiya uchun).
class SimMod {
  final String id;
  final String name;
  final int poles;
  final List<String> phases;
  final double current;
  final int rating;
  final bool uzo;
  final bool main;
  final String type;

  const SimMod({
    required this.id,
    required this.name,
    required this.poles,
    required this.phases,
    required this.current,
    required this.rating,
    required this.uzo,
    required this.main,
    required this.type,
  });
}

/// Loyihadan apparatlar ro'yxatini tuzadi: QF0 (kirish) + har bir yuklama.
List<SimMod> buildMods(Project p) {
  final r = Calc.panel(p);
  final mods = <SimMod>[
    SimMod(
      id: 'QF0',
      name: 'Kirish avtomati',
      poles: 3,
      phases: const ['L1', 'L2', 'L3'],
      current: 0,
      rating: r.mainBreaker > 0 ? r.mainBreaker : 32,
      uzo: false,
      main: true,
      type: 'main',
    ),
  ];
  for (var i = 0; i < p.loads.length; i++) {
    final l = p.loads[i];
    final lr = Calc.load(l);
    mods.add(SimMod(
      id: 'QF${i + 1}',
      name: l.name,
      poles: l.threePhase ? 3 : 1,
      phases: l.threePhase ? const ['L1', 'L2', 'L3'] : [l.phase],
      current: lr.current,
      rating: lr.breaker > 0 ? lr.breaker : 16,
      uzo: lr.uzo,
      main: false,
      type: l.type,
    ));
  }
  return mods;
}

class SimModeDef {
  final String key;
  final String label;
  final IconData icon;
  const SimModeDef(this.key, this.label, this.icon);
}

const simModes = <SimModeDef>[
  SimModeDef('sim', 'Oddiy', Icons.play_arrow_rounded),
  SimModeDef('3d', '3D', Icons.view_in_ar_outlined),
  SimModeDef('tools', 'Asboblar', Icons.speed_outlined),
  SimModeDef('heat', 'Issiqlik', Icons.thermostat_outlined),
  SimModeDef('place', 'Joylash', Icons.view_week_outlined),
  SimModeDef('wire', 'Sim ulash', Icons.cable_outlined),
];

Widget simScreenFor(String key, String projectId) {
  switch (key) {
    case '3d':
      return View3DScreen(projectId: projectId);
    case 'tools':
      return InstrumentsScreen(projectId: projectId);
    case 'heat':
      return ThermalScreen(projectId: projectId);
    case 'place':
      return PlacementScreen(projectId: projectId);
    case 'wire':
      return WiringScreen(projectId: projectId);
    default:
      return SimulationScreen(projectId: projectId);
  }
}

/// Rejim tanlagich: Oddiy · 3D · Asboblar · Issiqlik · Joylash · Sim ulash.
class ModeBar extends StatelessWidget {
  final String projectId;
  final String current;
  const ModeBar({super.key, required this.projectId, required this.current});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          for (final m in simModes)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Material(
                color: m.key == current ? C.amber : C.card,
                shape: StadiumBorder(
                  side: BorderSide(color: m.key == current ? C.amber : C.line),
                ),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: m.key == current
                      ? null
                      : () => Navigator.of(context).pushReplacement(
                            PageRouteBuilder(
                              transitionDuration: const Duration(milliseconds: 180),
                              pageBuilder: (_, __, ___) => simScreenFor(m.key, projectId),
                              transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
                            ),
                          ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 13),
                    child: Row(
                      children: [
                        Icon(m.icon, size: 15, color: m.key == current ? C.ink : C.muted),
                        const SizedBox(width: 5),
                        Text(
                          m.label,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: m.key == current ? C.ink : C.text2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Kichik avtomat belgisi (dastak holati bilan).
class MiniBreaker extends StatelessWidget {
  final bool on;
  final Color dot;
  final Color lever;
  const MiniBreaker({super.key, required this.on, required this.dot, required this.lever});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 40,
      decoration: BoxDecoration(color: const Color(0xFFE6E9ED), borderRadius: BorderRadius.circular(3)),
      child: Stack(
        children: [
          Positioned(
            left: 5,
            top: 5,
            child: Container(
              width: 14,
              height: 20,
              decoration: BoxDecoration(color: const Color(0xFF2A2F37), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutBack,
            left: 7,
            top: on ? 7 : 15,
            child: Container(
              width: 10,
              height: 8,
              decoration: BoxDecoration(color: lever, borderRadius: BorderRadius.circular(1.5)),
            ),
          ),
          Positioned(
            left: 9,
            top: 30,
            child: Container(width: 6, height: 6, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
          ),
        ],
      ),
    );
  }
}

String clock() {
  final d = DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
}

class NoLoads extends StatelessWidget {
  const NoLoads({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(30),
      child: Text(
        'Simulyatsiya uchun avval shitga yuklama qo\'shing.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, color: C.muted, height: 1.45),
      ),
    );
  }
}
