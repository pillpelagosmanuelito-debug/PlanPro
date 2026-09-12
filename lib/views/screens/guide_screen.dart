import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../data/models/methodology.dart';
import '../widgets/section_card.dart';

/// Guía de referencia: metodologías e indicadores.
///
/// No sustituye a la clase: sirve para consultar durante la partida el
/// significado exacto de un índice o el criterio para elegir enfoque, que es
/// justo cuando el concepto se necesita y por tanto se aprende.
class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guía de referencia')),
      body: ListView(
        padding: const EdgeInsets.only(top: 16, bottom: 28),
        children: <Widget>[
          SectionCard(
            title: 'Cómo elegir el enfoque',
            subtitle: 'Ninguno es mejor en abstracto',
            icon: Icons.alt_route,
            accent: AppColors.planning,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ...Methodology.values.map((Methodology m) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            m.label,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textStrong,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            m.description,
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: AppColors.textSoft,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Funciona cuando: ${m.worksWhen}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                              color: AppColors.planning,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'En el simulador: cada solicitud de cambio cuesta '
                            '× ${m.changeCostFactor.toStringAsFixed(1)} en horas, '
                            'y el cumplimiento documental exigible en cierre es '
                            '${(m.complianceLevel * 100).toStringAsFixed(0)}%.',
                            style: const TextStyle(
                              fontSize: 11,
                              height: 1.35,
                              color: AppColors.textSoft,
                            ),
                          ),
                        ],
                      ),
                    )),
                const NoteBox(
                  text: 'El error frecuente no es elegir mal: es elegir antes '
                      'de leer el acta. Un alcance abierto premia iterar; un '
                      'expediente aprobado premia planificar.',
                  icon: Icons.psychology_outlined,
                  color: AppColors.planning,
                ),
              ],
            ),
          ),
          const SectionCard(
            title: 'Gestión del valor ganado (EVM)',
            subtitle: 'Tres números que responden casi todo',
            icon: Icons.insights,
            accent: AppColors.info,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _Term(
                  term: 'PV · Valor planificado',
                  meaning:
                      'Cuánto trabajo, valorizado, debería estar terminado a '
                      'la fecha según la línea base.',
                ),
                _Term(
                  term: 'EV · Valor ganado',
                  meaning:
                      'Cuánto vale lo que realmente está terminado. Es la '
                      'única medida honesta de avance.',
                ),
                _Term(
                  term: 'AC · Costo real',
                  meaning: 'Lo que llevas gastado, hayas avanzado o no.',
                ),
                _Term(
                  term: 'SPI = EV / PV',
                  meaning:
                      'Menor que 1 significa atraso. Con 0.80 avanzas al 80% '
                      'del ritmo planificado.',
                ),
                _Term(
                  term: 'CPI = EV / AC',
                  meaning:
                      'Menor que 1 significa sobrecosto. Con 0.85 cada sol '
                      'gastado produce 85 céntimos de valor.',
                ),
                _Term(
                  term: 'EAC = BAC / CPI',
                  meaning:
                      'Cuánto costará terminar si el desempeño se mantiene. '
                      'Es la cifra que hay que llevar al patrocinador.',
                ),
                _Term(
                  term: 'TCPI',
                  meaning:
                      'Qué eficiencia necesitas de aquí en adelante para cerrar '
                      'dentro del presupuesto. Si es mucho mayor que tu CPI '
                      'actual, el plan ya no es creíble.',
                ),
                NoteBox(
                  text: 'Estos índices avisan con periodos de anticipación. '
                      'Sirven solo si defines antes el umbral en que actuarás: '
                      'decidirlo en plena crisis es tarde.',
                  icon: Icons.alarm,
                ),
              ],
            ),
          ),
          const SectionCard(
            title: 'Efectos que el simulador modela',
            subtitle: 'De dónde salen los números que ves',
            icon: Icons.science_outlined,
            accent: AppColors.execution,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _Term(
                  term: 'Sesgo de estimación',
                  meaning:
                      'La duración real de cada paquete se sortea alrededor de '
                      '1.10 veces la estimación, con dispersión. Las tareas '
                      'casi nunca terminan antes.',
                ),
                _Term(
                  term: 'Ley de Brooks',
                  meaning:
                      'Cada persona adicional resta eficiencia por '
                      'coordinación, y quien entra nuevo rinde parcialmente y '
                      'consume tiempo de los demás.',
                ),
                _Term(
                  term: 'Economía de los defectos',
                  meaning:
                      'Lo que no se controla al construir reaparece en pruebas '
                      'multiplicado por ocho en horas de corrección.',
                ),
                _Term(
                  term: 'Traslape de fases',
                  meaning:
                      'No hace falta terminar una fase para empezar la '
                      'siguiente, pero sí alcanzar un umbral de avance. Antes '
                      'de eso, las horas asignadas se pierden.',
                ),
                _Term(
                  term: 'Riesgos no identificados',
                  meaning:
                      'Ocurren igual, con 25% más de impacto en horas y sin '
                      'ninguna respuesta preparada.',
                ),
                _Term(
                  term: 'Horas extra',
                  meaning:
                      'Suman 25% de capacidad, cuestan 60% más y acumulan '
                      'fatiga que se descuenta en los periodos siguientes.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Term extends StatelessWidget {
  const _Term({required this.term, required this.meaning});

  final String term;
  final String meaning;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            term,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textStrong,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            meaning,
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.textSoft,
            ),
          ),
        ],
      ),
    );
  }
}
