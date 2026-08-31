import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/family_model.dart';
import '../services/weather_service.dart';

/// Search-and-pick dialog for the family's weather location. Same
/// controller-lifecycle pattern as NameLabelDialog (owned via
/// initState/dispose), plus an async search step in between typing and
/// picking — a typed place name is ambiguous until geocoded into a specific
/// lat/lon, so this shows candidates rather than guessing the first match.
///
/// Returns `null` on cancel, or the picked [FamilyWeatherLocation].
/// Clearing an existing location is a separate action in Settings (mirrors
/// how Family Groups pairs an edit icon with its own delete icon), so this
/// dialog never needs a third "cleared" outcome to distinguish from cancel.
class WeatherLocationDialog extends StatefulWidget {
  const WeatherLocationDialog({super.key, required this.weatherService});

  final WeatherService weatherService;

  @override
  State<WeatherLocationDialog> createState() => _WeatherLocationDialogState();
}

class _WeatherLocationDialogState extends State<WeatherLocationDialog> {
  late final TextEditingController _queryController;
  List<WeatherLocationResult> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _error = null;
    });

    try {
      final results = await widget.weatherService.searchLocations(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _isSearching = false;
        _hasSearched = true;
      });
    } catch (_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      setState(() {
        _error = l10n.weatherSearchFailedError;
        _isSearching = false;
        _hasSearched = true;
      });
    }
  }

  void _pick(WeatherLocationResult result) {
    Navigator.of(context).pop(
      FamilyWeatherLocation(
        name: result.displayName,
        latitude: result.latitude,
        longitude: result.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.weatherSearchDialogTitle),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.weatherSearchHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: l10n.weatherSearchFieldLabel,
                      errorText: _error,
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.search),
                        tooltip: l10n.weatherSearchButton,
                        onPressed: _search,
                      ),
              ],
            ),
            if (_hasSearched && _results.isEmpty && _error == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  l10n.weatherSearchNoResults,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            else if (_results.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final result = _results[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.place_outlined),
                      title: Text(result.displayName),
                      onTap: () => _pick(result),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}
