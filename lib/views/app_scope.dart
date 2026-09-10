import 'package:flutter/widgets.dart';

import '../viewmodels/project_viewmodel.dart';

/// Inyeccion del ViewModel en el arbol de widgets.
///
/// Se resuelve con `InheritedNotifier` en lugar de un paquete de estado para
/// mantener el MVP con una sola dependencia externa. Cualquier vista obtiene
/// el ViewModel con `AppScope.of(context)` y se reconstruye sola cuando el
/// ViewModel notifica cambios.
class AppScope extends InheritedNotifier<ProjectViewModel> {
  const AppScope({
    super.key,
    required ProjectViewModel viewModel,
    required super.child,
  }) : super(notifier: viewModel);

  static ProjectViewModel of(BuildContext context) {
    final AppScope? scope =
        context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope no encontrado en el arbol de widgets.');
    return scope!.notifier!;
  }

  /// Acceso sin suscripcion, para manejadores de eventos.
  static ProjectViewModel read(BuildContext context) {
    final AppScope? scope =
        context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope no encontrado en el arbol de widgets.');
    return scope!.notifier!;
  }
}
