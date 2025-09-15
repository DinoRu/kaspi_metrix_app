// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:metrix/data/models/meter.dart';
import 'package:metrix/data/models/reading.dart';

class CustomSearchDelegate<T> extends SearchDelegate<T?> {
  final List<T> list;
  final List<String> Function(T) searchFields;
  final Widget Function(BuildContext, T, String)? itemBuilder;
  final void Function(BuildContext, T)? onItemTap;
  final String? hintText;
  final bool showDivider;

  CustomSearchDelegate({
    required this.list,
    required this.searchFields,
    this.itemBuilder,
    this.onItemTap,
    this.hintText,
    this.showDivider = true,
  }) : super(
         searchFieldLabel: hintText ?? 'Rechercher...',
         searchFieldStyle: const TextStyle(fontSize: 16),
       );

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: theme.colorScheme.surface,
        elevation: 2,
        shadowColor: theme.colorScheme.shadow.withOpacity(0.1),
        surfaceTintColor: theme.colorScheme.primary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
          fontSize: 16,
        ),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: query.isEmpty ? 0 : 48,
        child: AnimatedOpacity(
          opacity: query.isEmpty ? 0 : 1,
          duration: const Duration(milliseconds: 200),
          child: IconButton(
            icon: const Icon(Icons.clear_rounded),
            onPressed: () {
              query = '';
              // Haptic feedback pour améliorer l'UX
              HapticFeedback.lightImpact();
            },
            tooltip: 'Effacer',
          ),
        ),
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: AnimatedIcon(
        icon: AnimatedIcons.menu_arrow,
        progress: transitionAnimation,
      ),
      onPressed: () {
        HapticFeedback.lightImpact();
        close(context, null);
      },
      tooltip: 'Retour',
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context, isSuggestion: true);
  }

  Widget _buildSearchResults(
    BuildContext context, {
    bool isSuggestion = false,
  }) {
    final filteredList = _getFilteredList();

    if (query.isEmpty && isSuggestion) {
      return _buildEmptyState(
        context,
        icon: Icons.search_rounded,
        title: 'Commencez à taper pour rechercher',
        subtitle: 'Recherchez dans ${list.length} éléments',
      );
    }

    if (filteredList.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.search_off_rounded,
        title: 'Aucun résultat trouvé',
        subtitle: 'Essayez avec d\'autres mots-clés',
      );
    }

    return AnimatedList(
      initialItemCount: filteredList.length,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      itemBuilder: (context, index, animation) {
        if (index >= filteredList.length) return const SizedBox.shrink();

        final item = filteredList[index];

        return SlideTransition(
          position: animation.drive(
            Tween(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeOutCubic)),
          ),
          child: FadeTransition(
            opacity: animation,
            child: itemBuilder != null
                ? itemBuilder!(context, item, query)
                : _buildDefaultItem(context, item, index),
          ),
        );
      },
    );
  }

  Widget _buildDefaultItem(BuildContext context, T item, int index) {
    final theme = Theme.of(context);
    final fields = searchFields(item);
    final title = fields.isNotEmpty ? fields[1] : '';
    final subtitle = fields.length > 1 ? fields[2] : '';

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              if (onItemTap != null) {
                onItemTap!(context, item);
              } else {
                _defaultNavigate(context, item);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _buildLeadingIcon(context, item),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHighlightedText(
                          title,
                          query,
                          style:
                              theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ) ??
                              const TextStyle(),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          _buildHighlightedText(
                            subtitle,
                            query,
                            style:
                                theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ) ??
                                const TextStyle(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider && index < _getFilteredList().length - 1)
          Divider(
            height: 1,
            indent: 72,
            endIndent: 16,
            color: theme.dividerColor.withOpacity(0.1),
          ),
      ],
    );
  }

  Widget _buildLeadingIcon(BuildContext context, T item) {
    final theme = Theme.of(context);
    IconData icon;
    Color color;

    // Personnalisation selon le type
    if (item is Meter) {
      icon = Icons.speed_rounded;
      color = theme.colorScheme.primary;
    } else if (item is Reading) {
      icon = Icons.analytics_rounded;
      color = theme.colorScheme.secondary;
    } else {
      icon = Icons.folder_rounded;
      color = theme.colorScheme.tertiary;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildHighlightedText(
    String text,
    String query, {
    required TextStyle style,
  }) {
    if (query.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final matches = RegExp(
      RegExp.escape(query),
      caseSensitive: false,
    ).allMatches(text);

    if (matches.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final spans = <TextSpan>[];
    int lastEnd = 0;

    for (final match in matches) {
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(text: text.substring(lastEnd, match.start), style: style),
        );
      }

      spans.add(
        TextSpan(
          text: text.substring(match.start, match.end),
          style: style.copyWith(
            backgroundColor: Colors.yellow.withOpacity(0.3),
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd), style: style));
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<T> _getFilteredList() {
    if (query.isEmpty) return list;

    return list.where((item) {
      return searchFields(
        item,
      ).any((field) => field.toLowerCase().contains(query.toLowerCase()));
    }).toList();
  }

  void _defaultNavigate(BuildContext context, T item) {
    if (item is Meter) {
      Navigator.pushNamed(context, '/reading/new', arguments: item);
    } else if (item is Reading) {
      Navigator.pushNamed(context, '/reading/detail', arguments: item);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Type non reconnu'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          action: SnackBarAction(label: 'OK', onPressed: () {}),
        ),
      );
    }
    close(context, item);
  }
}
