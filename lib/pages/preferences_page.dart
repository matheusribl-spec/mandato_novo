import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mandato_novo/services/app_state.dart';

class PreferencesPage extends StatelessWidget {
  const PreferencesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferências'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Temas de Interesse',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  ...appState.themes.asMap().entries.map((entry) {
                    final index = entry.key;
                    final theme = entry.value;
                    final isLast = index == appState.themes.length - 1;

                    return Column(
                      children: [
                        CheckboxListTile(
                          title: Text(
                            theme.title,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            theme.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                          value: appState.selectedThemeIds.contains(theme.id),
                          onChanged: (_) => appState.toggleThemeSelection(theme.id),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        if (!isLast)
                          Divider(height: 1, color: Colors.grey.shade200, indent: 16, endIndent: 16),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Portais Monitorados',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  ...appState.portals.asMap().entries.map((entry) {
                    final index = entry.key;
                    final portal = entry.value;
                    final isLast = index == appState.portals.length - 1;

                    return Column(
                      children: [
                        CheckboxListTile(
                          title: Text(
                            portal.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            portal.url,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                          value: appState.selectedPortalIds.contains(portal.id),
                          onChanged: (_) => appState.togglePortalSelection(portal.id),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        if (!isLast)
                          Divider(height: 1, color: Colors.grey.shade200, indent: 16, endIndent: 16),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Preferências atualizadas')),
                  );
                },
                icon: const Icon(Icons.check_circle),
                label: const Text('Salvar Preferências'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
