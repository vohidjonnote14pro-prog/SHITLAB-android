import 'package:flutter/material.dart';

import '../store.dart';

/// Ma'lumot o'zgarganda faqat ko'rinib turgan oynani qayta chizadi.
///
/// Orqadagi oynalar (boshqa tab yoki ustiga ochilgan sahifa ostidagi)
/// har bir harf yozilganda qayta chizilmaydi — ular ko'ringanda yangilanadi.
class AppBuilder extends StatefulWidget {
  final WidgetBuilder builder;
  const AppBuilder({super.key, required this.builder});

  @override
  State<AppBuilder> createState() => _AppBuilderState();
}

class _AppBuilderState extends State<AppBuilder> {
  bool _visible = true;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    app.addListener(_onChange);
  }

  @override
  void dispose() {
    app.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (!mounted) return;
    if (_visible) {
      setState(() {});
    } else {
      _dirty = true;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final wasHidden = !_visible;
    _visible = TickerMode.of(context) && (ModalRoute.of(context)?.isCurrent ?? true);
    if (wasHidden && _visible && _dirty) _dirty = false;
  }

  @override
  Widget build(BuildContext context) {
    _visible = TickerMode.of(context) && (ModalRoute.of(context)?.isCurrent ?? true);
    return widget.builder(context);
  }
}
