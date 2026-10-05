import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/utils/user_facing_error.dart';
import '../../../shared/models/artist_show.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/widgets/pp_input.dart';

String formatShowDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String showStatusLabel(String s) {
  switch (s) {
    case ArtistShow.statusConfirmed:
      return 'Confirmado';
    case ArtistShow.statusPending:
      return 'Pendente';
    case ArtistShow.statusCancelled:
      return 'Cancelado';
    default:
      return s;
  }
}

String eventKindLabel(String k) {
  switch (k) {
    case ArtistShow.eventKindRehearsal:
      return 'Ensaio';
    case ArtistShow.eventKindRecording:
      return 'Gravação';
    case ArtistShow.eventKindShow:
    default:
      return 'Show';
  }
}

/// Dialogo criar/editar compromisso na agenda (show, ensaio, gravação).
Future<void> showArtistShowEditor(
  BuildContext context,
  WidgetRef ref, {
  required UserProfile profile,
  ArtistShow? existing,
}) async {
  final svc = ref.read(artistWorkspaceServiceProvider);
  final titleCtrl = TextEditingController(text: existing?.title ?? '');
  final timeCtrl = TextEditingController(text: existing?.time ?? '');
  final venueCtrl = TextEditingController(text: existing?.venue ?? '');
  final cityCtrl = TextEditingController(text: existing?.city ?? '');
  final notesCtrl = TextEditingController(text: existing?.notes ?? '');
  var date = existing?.date ?? DateTime.now();
  var status = existing?.status ?? ArtistShow.statusPending;
  var eventKind = existing?.eventKind ?? ArtistShow.eventKindShow;

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSt) => AlertDialog(
        title: Text(existing == null ? 'Novo compromisso' : 'Editar compromisso'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PPInput(label: 'Nome do evento', controller: titleCtrl),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: eventKind,
                decoration: const InputDecoration(labelText: 'Tipo de compromisso'),
                items: ArtistShow.eventKindOrder
                    .map(
                      (k) => DropdownMenuItem(
                        value: k,
                        child: Text(eventKindLabel(k)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setSt(() => eventKind = v ?? eventKind),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Data'),
                subtitle: Text(formatShowDate(date)),
                trailing: const Icon(Icons.calendar_today_rounded),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setSt(() => date = picked);
                },
              ),
              PPInput(label: 'Horário', controller: timeCtrl, hint: 'Ex.: 21:00'),
              PPInput(label: 'Local', controller: venueCtrl),
              PPInput(label: 'Cidade', controller: cityCtrl),
              PPInput(label: 'Observações', controller: notesCtrl, maxLines: 3),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: ArtistShow.statusLabelsOrder
                    .map(
                      (s) => DropdownMenuItem(value: s, child: Text(showStatusLabel(s))),
                    )
                    .toList(),
                onChanged: (v) => setSt(() => status = v ?? status),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    ),
  );

  if (ok != true || !context.mounted) return;
  if (titleCtrl.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Informe o nome do evento')),
    );
    return;
  }

  final show = ArtistShow(
    id: existing?.id ?? '',
    profileId: profile.id,
    title: titleCtrl.text.trim(),
    date: date,
    time: timeCtrl.text.trim(),
    venue: venueCtrl.text.trim(),
    city: cityCtrl.text.trim(),
    notes: notesCtrl.text.trim(),
    status: status,
    eventKind: eventKind,
    createdAt: existing?.createdAt ?? DateTime.now(),
    updatedAt: DateTime.now(),
  );
  try {
    await svc.saveShow(show);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compromisso salvo')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível salvar.${userFacingErrorSuffix(e)}',
          ),
        ),
      );
    }
  }
}
