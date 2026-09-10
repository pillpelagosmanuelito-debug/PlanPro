import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../data/models/project_state.dart';
import '../../data/models/risk_item.dart';
import '../../viewmodels/project_viewmodel.dart';
import '../app_scope.dart';
import '../widgets/section_card.dart';

/// Modulo 4: Riesgos.
///
/// El registro solo muestra los riesgos identificados. Los demas existen y
/// pueden ocurrir: esa asimetria es deliberada y es la leccion central del
/// modulo.
class RiskTab extends StatelessWidget {
  const RiskTab({super.key});

  @override
  Widget build(BuildContext context) {
    final ProjectViewModel vm = AppScope.of(context);
    final ProjectState state = vm.state!;
    final double hourValue = state.hourValue(vm.config);
    final List<RiskItem> identified = state.identifiedRisks;
    final List<RiskItem> active = identified
        .where((RiskItem r) => !r.occurred)
        .toList()
      ..sort((RiskItem a, RiskItem b) =>
          b.exposure(hourValue).compareTo(a.exposure(hourValue)));
    final List<RiskItem> occurred =
        state.risks.where((RiskItem r) => r.occurred).toList();

    return ListView(
      padding: const EdgeInsets.only(top: 14, bottom: 24),
      children: <Widget>[
        SectionCard(
          title: 'Exposicion al riesgo',
          subtitle: 'Probabilidad por impacto, en dinero',
          icon: Icons.shield_outlined,
          accent: AppColors.warning,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: _Stat(
                      label: 'Exposicion conocida',
                      value: formatMoney(state.riskExposure(hourValue)),
                      color: AppColors.warning,
                    ),
                  ),
                  Expanded(
                    child: _Stat(
                      label: 'Reserva disponible',
                      value: formatMoney(
                        (state.baseline?.contingencyReserve ?? 0) -
                            state.reserveUsed,
                      ),
                      color: AppColors.closure,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Registro: ${identified.length} de ${state.risks.length} '
                'riesgos del proyecto. Los que no estan aqui no dejan de '
                'existir.',
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: AppColors.textSoft,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: identified.length >= state.risks.length
                    ? null
                    : () => _workshop(context, vm),
                icon: const Icon(Icons.search, size: 18),
                label: Text(
                  identified.length >= state.risks.length
                      ? 'No quedan riesgos por identificar'
                      : 'Taller de identificacion · '
                          '${formatMoney(vm.workshopCost)}',
                ),
              ),
              if (vm.lastRevealed.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                NoteBox(
                  text: 'El taller revelo: '
                      '${vm.lastRevealed.map((RiskItem r) => r.name).join(', ')}.',
                  icon: Icons.visibility_outlined,
                  color: AppColors.success,
                ),
              ],
            ],
          ),
        ),
        if (active.isNotEmpty)
          SectionCard(
            title: 'Riesgos activos',
            subtitle: 'Ordenados por exposicion, no por miedo',
            icon: Icons.warning_amber_rounded,
            accent: AppColors.danger,
            child: Column(
              children: active
                  .map((RiskItem r) => _RiskRow(
                        risk: r,
                        hourValue: hourValue,
                        currentPeriod: state.period,
                        onRespond: (RiskResponse response) =>
                            vm.respondToRisk(r.id, response),
                      ))
                  .toList(),
            ),
          ),
        if (occurred.isNotEmpty)
          SectionCard(
            title: 'Riesgos materializados',
            subtitle: 'Lo que ya paso y su costo',
            icon: Icons.report_problem_outlined,
            accent: AppColors.textSoft,
            child: Column(
              children: occurred
                  .map((RiskItem r) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Icon(
                              r.identified
                                  ? Icons.check_circle_outline
                                  : Icons.help_outline,
                              size: 15,
                              color: r.identified
                                  ? AppColors.warning
                                  : AppColors.danger,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    r.name,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textStrong,
                                    ),
                                  ),
                                  Text(
                                    r.identified
                                        ? 'Periodo ${r.occurredPeriod} · '
                                            'estaba en tu registro '
                                            '(${r.response.label})'
                                        : 'Periodo ${r.occurredPeriod} · '
                                            'nunca lo identificaste, el '
                                            'impacto llego agravado',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      height: 1.3,
                                      color: r.identified
                                          ? AppColors.textSoft
                                          : AppColors.danger,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }

  Future<void> _workshop(BuildContext context, ProjectViewModel vm) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Taller de identificacion de riesgos'),
        content: Text(
          'Cuesta ${formatMoney(vm.workshopCost)} y revela hasta dos riesgos '
          'que hoy estan fuera de tu registro.\n\n'
          'Un riesgo identificado puede tratarse; uno desconocido solo puede '
          'sufrirse.',
          style: const TextStyle(fontSize: 13, height: 1.45),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Ahora no'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Realizar taller'),
          ),
        ],
      ),
    );
    if (ok == true) vm.runWorkshop();
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 9.5,
            letterSpacing: 0.6,
            fontWeight: FontWeight.w700,
            color: AppColors.textSoft,
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _RiskRow extends StatelessWidget {
  const _RiskRow({
    required this.risk,
    required this.hourValue,
    required this.currentPeriod,
    required this.onRespond,
  });

  final RiskItem risk;
  final double hourValue;
  final int currentPeriod;
  final ValueChanged<RiskResponse> onRespond;

  @override
  Widget build(BuildContext context) {
    final bool inWindow = risk.window.contains(currentPeriod);
    final bool past = risk.window.every((int p) => p < currentPeriod);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: inWindow ? AppColors.danger : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    risk.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textStrong,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    risk.category.label,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSoft,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              risk.description,
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.35,
                color: AppColors.textSoft,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: <Widget>[
                _chip('Probabilidad',
                    formatPercent(risk.effectiveProbability)),
                _chip('Impacto',
                    '${formatHours(risk.effectiveImpactHours)} + ${formatMoney(risk.effectiveImpactCost)}'),
                _chip('Exposicion', formatMoney(risk.exposure(hourValue))),
                _chip(
                  'Ventana',
                  past
                      ? 'ya paso'
                      : 'P${risk.window.first}-P${risk.window.last}',
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Senial temprana: ${risk.trigger}',
              style: const TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: AppColors.textSoft,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <RiskResponse>[
                RiskResponse.mitigate,
                RiskResponse.transfer,
                RiskResponse.accept,
                RiskResponse.avoid,
              ].map((RiskResponse r) {
                final bool selected = risk.response == r;
                final double cost = r == RiskResponse.mitigate
                    ? risk.mitigationCost
                    : r == RiskResponse.transfer
                        ? risk.transferCost
                        : 0;
                return ChoiceChip(
                  label: Text(
                    cost > 0
                        ? '${r.label} · ${formatMoneyCompact(cost)}'
                        : r.label,
                    style: const TextStyle(fontSize: 11),
                  ),
                  selected: selected,
                  onSelected: past ? null : (_) => onRespond(r),
                );
              }).toList(),
            ),
            if (risk.response != RiskResponse.none) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                risk.response.detail,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  color: AppColors.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(fontSize: 9.5, color: AppColors.textSoft),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textStrong,
          ),
        ),
      ],
    );
  }
}
