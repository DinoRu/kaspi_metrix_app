// // =====================================
// // lib/presentation/widgets/search_bottom_sheet.dart
// // =====================================
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:metrix/data/models/meter.dart';
// import 'package:metrix/data/models/search_filter.dart';
// import 'package:metrix/presentation/providers/search_provider.dart';

// class SearchFilterBottomSheet extends ConsumerStatefulWidget {
//   const SearchFilterBottomSheet({super.key});

//   @override
//   ConsumerState<SearchFilterBottomSheet> createState() =>
//       _SearchFilterBottomSheetState();
// }

// class _SearchFilterBottomSheetState
//     extends ConsumerState<SearchFilterBottomSheet> {
//   late SearchFilter _tempFilter;
//   final TextEditingController _minReadingController = TextEditingController();
//   final TextEditingController _maxReadingController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     _tempFilter = ref.read(searchFilterProvider);
//     _minReadingController.text = _tempFilter.minReading?.toString() ?? '';
//     _maxReadingController.text = _tempFilter.maxReading?.toString() ?? '';
//   }

//   @override
//   void dispose() {
//     _minReadingController.dispose();
//     _maxReadingController.dispose();
//     super.dispose();
//   }

//   void _applyFilters() {
//     final notifier = ref.read(searchFilterProvider.notifier);

//     notifier.updateTypes(_tempFilter.types);
//     notifier.updateStatuses(_tempFilter.statuses);
//     notifier.updateDateRange(_tempFilter.dateFrom, _tempFilter.dateTo);
//     notifier.updateSort(_tempFilter.sortBy);

//     final minReading = double.tryParse(_minReadingController.text);
//     final maxReading = double.tryParse(_maxReadingController.text);
//     notifier.updateReadingRange(minReading, maxReading);

//     Navigator.pop(context);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final availableTypes = ref.watch(availableTypesProvider);
//     final availableStatuses = ref.watch(availableStatusesProvider);
//     final searchHistory = ref.watch(searchHistoryProvider);

//     return DraggableScrollableSheet(
//       initialChildSize: 0.7,
//       minChildSize: 0.3,
//       maxChildSize: 0.9,
//       expand: false,
//       builder: (context, scrollController) {
//         return Container(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Handle
//               Center(
//                 child: Container(
//                   width: 40,
//                   height: 4,
//                   decoration: BoxDecoration(
//                     color: Colors.grey.shade300,
//                     borderRadius: BorderRadius.circular(2),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 16),

//               // Title
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     'Advanced Filters',
//                     style: Theme.of(context).textTheme.headlineSmall,
//                   ),
//                   TextButton(
//                     onPressed: () {
//                       setState(() {
//                         _tempFilter = const SearchFilter();
//                         _minReadingController.clear();
//                         _maxReadingController.clear();
//                       });
//                     },
//                     child: const Text('Clear All'),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 16),

//               Expanded(
//                 child: ListView(
//                   controller: scrollController,
//                   children: [
//                     // Sort By
//                     Text(
//                       'Sort By',
//                       style: Theme.of(context).textTheme.titleMedium,
//                     ),
//                     const SizedBox(height: 8),
//                     Wrap(
//                       spacing: 8,
//                       children: SortBy.values.map((sort) {
//                         return ChoiceChip(
//                           label: Text(sort.displayName),
//                           selected: _tempFilter.sortBy == sort,
//                           onSelected: (selected) {
//                             if (selected) {
//                               setState(() {
//                                 _tempFilter = _tempFilter.copyWith(
//                                   sortBy: sort,
//                                 );
//                               });
//                             }
//                           },
//                         );
//                       }).toList(),
//                     ),
//                     const SizedBox(height: 16),

//                     // Meter Types
//                     if (availableTypes.hasValue &&
//                         availableTypes.value!.isNotEmpty) ...[
//                       Text(
//                         'Meter Types',
//                         style: Theme.of(context).textTheme.titleMedium,
//                       ),
//                       const SizedBox(height: 8),
//                       Wrap(
//                         spacing: 8,
//                         children: availableTypes.value!.map((type) {
//                           return FilterChip(
//                             label: Text(type),
//                             selected: _tempFilter.types.contains(type),
//                             onSelected: (selected) {
//                               setState(() {
//                                 final newTypes = List<String>.from(
//                                   _tempFilter.types,
//                                 );
//                                 if (selected) {
//                                   newTypes.add(type);
//                                 } else {
//                                   newTypes.remove(type);
//                                 }
//                                 _tempFilter = _tempFilter.copyWith(
//                                   types: newTypes,
//                                 );
//                               });
//                             },
//                           );
//                         }).toList(),
//                       ),
//                       const SizedBox(height: 16),
//                     ],

//                     // Status
//                     if (availableStatuses.hasValue &&
//                         availableStatuses.value!.isNotEmpty) ...[
//                       Text(
//                         'Status',
//                         style: Theme.of(context).textTheme.titleMedium,
//                       ),
//                       const SizedBox(height: 8),
//                       Wrap(
//                         spacing: 8,
//                         children: availableStatuses.value!.map((status) {
//                           return FilterChip(
//                             label: Text(status),
//                             selected: _tempFilter.statuses.contains(status),
//                             onSelected: (selected) {
//                               setState(() {
//                                 final newStatuses = List<String>.from(
//                                   _tempFilter.statuses,
//                                 );
//                                 if (selected) {
//                                   newStatuses.add(status);
//                                 } else {
//                                   newStatuses.remove(status);
//                                 }
//                                 _tempFilter = _tempFilter.copyWith(
//                                   statuses: newStatuses,
//                                 );
//                               });
//                             },
//                           );
//                         }).toList(),
//                       ),
//                       const SizedBox(height: 16),
//                     ],

//                     // Date Range
//                     Text(
//                       'Last Reading Date',
//                       style: Theme.of(context).textTheme.titleMedium,
//                     ),
//                     const SizedBox(height: 8),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: OutlinedButton.icon(
//                             icon: const Icon(Icons.calendar_today),
//                             label: Text(
//                               _tempFilter.dateFrom != null
//                                   ? '${_tempFilter.dateFrom!.day}/${_tempFilter.dateFrom!.month}/${_tempFilter.dateFrom!.year}'
//                                   : 'From Date',
//                             ),
//                             onPressed: () async {
//                               final date = await showDatePicker(
//                                 context: context,
//                                 initialDate:
//                                     _tempFilter.dateFrom ?? DateTime.now(),
//                                 firstDate: DateTime(2020),
//                                 lastDate: DateTime.now(),
//                               );
//                               if (date != null) {
//                                 setState(() {
//                                   _tempFilter = _tempFilter.copyWith(
//                                     dateFrom: date,
//                                   );
//                                 });
//                               }
//                             },
//                           ),
//                         ),
//                         const SizedBox(width: 16),
//                         Expanded(
//                           child: OutlinedButton.icon(
//                             icon: const Icon(Icons.calendar_today),
//                             label: Text(
//                               _tempFilter.dateTo != null
//                                   ? '${_tempFilter.dateTo!.day}/${_tempFilter.dateTo!.month}/${_tempFilter.dateTo!.year}'
//                                   : 'To Date',
//                             ),
//                             onPressed: () async {
//                               final date = await showDatePicker(
//                                 context: context,
//                                 initialDate:
//                                     _tempFilter.dateTo ?? DateTime.now(),
//                                 firstDate: DateTime(2020),
//                                 lastDate: DateTime.now(),
//                               );
//                               if (date != null) {
//                                 setState(() {
//                                   _tempFilter = _tempFilter.copyWith(
//                                     dateTo: date,
//                                   );
//                                 });
//                               }
//                             },
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 16),

//                     // Reading Value Range
//                     Text(
//                       'Reading Value Range',
//                       style: Theme.of(context).textTheme.titleMedium,
//                     ),
//                     const SizedBox(height: 8),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: TextField(
//                             controller: _minReadingController,
//                             keyboardType: TextInputType.number,
//                             decoration: const InputDecoration(
//                               labelText: 'Min Value',
//                               border: OutlineInputBorder(),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 16),
//                         Expanded(
//                           child: TextField(
//                             controller: _maxReadingController,
//                             keyboardType: TextInputType.number,
//                             decoration: const InputDecoration(
//                               labelText: 'Max Value',
//                               border: OutlineInputBorder(),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 16),

//                     // Search History
//                     if (searchHistory.hasValue &&
//                         searchHistory.value!.isNotEmpty) ...[
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             'Recent Searches',
//                             style: Theme.of(context).textTheme.titleMedium,
//                           ),
//                           TextButton(
//                             onPressed: () async {
//                               await ref
//                                   .read(meterRepositoryEnhancedProvider)
//                                   .clearSearchHistory();
//                               ref.invalidate(searchHistoryProvider);
//                             },
//                             child: const Text('Clear'),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 8),
//                       Wrap(
//                         spacing: 8,
//                         children: searchHistory.value!.take(10).map((query) {
//                           return ActionChip(
//                             label: Text(query),
//                             onPressed: () {
//                               ref
//                                   .read(searchFilterProvider.notifier)
//                                   .updateQuery(query);
//                               Navigator.pop(context);
//                             },
//                           );
//                         }).toList(),
//                       ),
//                     ],
//                   ],
//                 ),
//               ),

//               // Apply Button
//               const SizedBox(height: 16),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: _applyFilters,
//                   style: ElevatedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                   ),
//                   child: const Text('Apply Filters'),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }

// class MeterCardEnhanced extends StatelessWidget {
//   final Meter meter;
//   final String searchQuery;
//   final VoidCallback onTap;

//   const MeterCardEnhanced({
//     super.key,
//     required this.meter,
//     required this.searchQuery,
//     required this.onTap,
//   });

//   Widget _highlightText(String text, String query) {
//     if (query.isEmpty) return Text(text);

//     final matches = query.toLowerCase();
//     final textLower = text.toLowerCase();

//     if (!textLower.contains(matches)) return Text(text);

//     final startIndex = textLower.indexOf(matches);
//     final endIndex = startIndex + matches.length;

//     return RichText(
//       text: TextSpan(
//         children: [
//           TextSpan(
//             text: text.substring(0, startIndex),
//             style: const TextStyle(color: Colors.black87),
//           ),
//           TextSpan(
//             text: text.substring(startIndex, endIndex),
//             style: const TextStyle(
//               color: Colors.blue,
//               fontWeight: FontWeight.bold,
//               backgroundColor: Colors.yellow,
//             ),
//           ),
//           TextSpan(
//             text: text.substring(endIndex),
//             style: const TextStyle(color: Colors.black87),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(12),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Expanded(
//                     child: _highlightText(meter.meterNumber, searchQuery),
//                   ),
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 8,
//                       vertical: 4,
//                     ),
//                     decoration: BoxDecoration(
//                       color: meter.status == 'active'
//                           ? Colors.green.shade100
//                           : Colors.grey.shade200,
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Text(
//                       meter.status ?? 'unknown',
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: meter.status == 'active'
//                             ? Colors.green.shade800
//                             : Colors.grey.shade700,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//               Row(
//                 children: [
//                   const Icon(Icons.category, size: 16, color: Colors.grey),
//                   const SizedBox(width: 4),
//                   Text(
//                     meter.type,
//                     style: const TextStyle(fontSize: 14, color: Colors.grey),
//                   ),
//                 ],
//               ),
//               if (meter.clientName != null) ...[
//                 const SizedBox(height: 4),
//                 Row(
//                   children: [
//                     const Icon(Icons.person, size: 16, color: Colors.grey),
//                     const SizedBox(width: 4),
//                     Expanded(
//                       child: _highlightText(meter.clientName!, searchQuery),
//                     ),
//                   ],
//                 ),
//               ],
//               if (meter.locationAddress != null) ...[
//                 const SizedBox(height: 4),
//                 Row(
//                   children: [
//                     const Icon(Icons.location_on, size: 16, color: Colors.grey),
//                     const SizedBox(width: 4),
//                     Expanded(
//                       child: _highlightText(
//                         meter.locationAddress!,
//                         searchQuery,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//               if (meter.lastReadingDate != null) ...[
//                 const SizedBox(height: 8),
//                 Row(
//                   children: [
//                     const Icon(Icons.access_time, size: 16, color: Colors.blue),
//                     const SizedBox(width: 4),
//                     Text(
//                       'Last reading: ${meter.lastReadingDate}',
//                       style: const TextStyle(fontSize: 12, color: Colors.blue),
//                     ),
//                   ],
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
