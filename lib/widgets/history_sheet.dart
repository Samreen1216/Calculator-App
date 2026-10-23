import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/calculation.dart';
import '../theme/app_theme.dart';
import '../controllers/calculator_controller.dart';

enum HistoryFilter {
  all,
  calculations,
  conversions,
}

class HistorySheet extends StatefulWidget {
  final List<Calculation> history;
  final VoidCallback onClear;
  final ValueChanged<Calculation> onSelect;
  final ValueChanged<int>? onDeleteItem;
  final bool isBottomSheet;
  final VoidCallback? onClose;
  final HistoryFilter initialFilter;

  const HistorySheet({
    super.key,
    required this.history,
    required this.onClear,
    required this.onSelect,
    this.onDeleteItem,
    this.isBottomSheet = true,
    this.onClose,
    this.initialFilter = HistoryFilter.all,
  });

  @override
  State<HistorySheet> createState() => _HistorySheetState();
}

class _HistorySheetState extends State<HistorySheet> {
  late HistoryFilter _currentFilter;

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.initialFilter;
    _ensureValidFilter();
  }

  @override
  void didUpdateWidget(covariant HistorySheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ensureValidFilter();
  }

  void _ensureValidFilter() {
    final hasConversions = widget.history.any((c) => c.isConversion);
    final hasCalculations = widget.history.any((c) => !c.isConversion);

    if (_currentFilter == HistoryFilter.conversions && !hasConversions) {
      if (hasCalculations) {
        _currentFilter = HistoryFilter.all;
      }
    } else if (_currentFilter == HistoryFilter.calculations && !hasCalculations) {
      if (hasConversions) {
        _currentFilter = HistoryFilter.all;
      }
    }
  }

  List<Calculation> get _filteredHistory {
    switch (_currentFilter) {
      case HistoryFilter.calculations:
        return widget.history.where((c) => !c.isConversion).toList();
      case HistoryFilter.conversions:
        return widget.history.where((c) => c.isConversion).toList();
      case HistoryFilter.all:
        return widget.history;
    }
  }

  @override
  Widget build(BuildContext context) {
    final calcTheme = Theme.of(context).extension<CalculatorTheme>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = calcTheme?.displayColor ??
        (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFFFFFFF));
    final primaryText = calcTheme?.primaryTextColor ??
        (isDark ? const Color(0xFFF2F2F7) : const Color(0xFF202938));
    final secondaryText = calcTheme?.secondaryTextColor ??
        (isDark ? const Color(0xFF98989D) : const Color(0xFF778196));
    final dividerColor = calcTheme?.numberButtonColor ??
        (isDark ? const Color(0xFF48484A) : const Color(0xFFEEF0F4));
    final accentColor = calcTheme?.equalsButtonColor ?? const Color(0xFF347D78);

    final displayList = _filteredHistory;
    final hasConversions = widget.history.any((c) => c.isConversion);
    final hasCalculations = widget.history.any((c) => !c.isConversion);
    final showFilterChips = hasConversions && hasCalculations;

    final content = Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: widget.isBottomSheet
            ? const BorderRadius.vertical(top: Radius.circular(24))
            : BorderRadius.circular(16),
        boxShadow: widget.isBottomSheet
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ]
            : null,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: widget.isBottomSheet ? MainAxisSize.min : MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle (bottom sheet only)
            if (widget.isBottomSheet)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 2),
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: dividerColor.withValues(alpha: isDark ? 0.8 : 1.0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: primaryText,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.history.isNotEmpty)
                        TextButton(
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => _confirmClear(context),
                          child: const Text(
                            'Clear All',
                            style: TextStyle(
                              color: Color(0xFFE74C3C),
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      const SizedBox(width: 4),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () {
                          if (widget.onClose != null) {
                            widget.onClose!();
                          } else if (widget.isBottomSheet) {
                            Navigator.maybePop(context);
                          }
                        },
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Optional Filter Chips when both calculations and conversions exist
            if (showFilterChips)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        'All (${widget.history.length})',
                        HistoryFilter.all,
                        accentColor,
                        primaryText,
                        secondaryText,
                        dividerColor,
                      ),
                      const SizedBox(width: 6),
                      _buildFilterChip(
                        'Calculations (${widget.history.where((c) => !c.isConversion).length})',
                        HistoryFilter.calculations,
                        accentColor,
                        primaryText,
                        secondaryText,
                        dividerColor,
                      ),
                      const SizedBox(width: 6),
                      _buildFilterChip(
                        'Conversions (${widget.history.where((c) => c.isConversion).length})',
                        HistoryFilter.conversions,
                        accentColor,
                        primaryText,
                        secondaryText,
                        dividerColor,
                      ),
                    ],
                  ),
                ),
              ),

            Divider(height: 1, thickness: 1, color: dividerColor),

            // History list or empty state
            if (displayList.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: dividerColor.withValues(alpha: isDark ? 0.35 : 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _currentFilter == HistoryFilter.conversions
                              ? Icons.swap_horiz_rounded
                              : Icons.history_rounded,
                          size: 32,
                          color: secondaryText.withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _currentFilter == HistoryFilter.conversions
                            ? 'No conversion history yet'
                            : 'No history yet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: primaryText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _currentFilter == HistoryFilter.conversions
                            ? 'Recent unit conversions\nwill appear here.'
                            : 'Your calculations and results\nwill appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  itemCount: displayList.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final calc = displayList[index];
                    final resultFormatted = calc.isConversion
                        ? '= ${calc.result}'
                        : '= ${CalculatorController.formatNumber(calc.result)}';

                    return Dismissible(
                      key: ValueKey(
                        '${calc.timestamp.millisecondsSinceEpoch}_${calc.expression}_$index',
                      ),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.symmetric(vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE74C3C),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 6),
                            Text(
                              'Delete',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      onDismissed: (_) {
                        final realIndex = widget.history.indexOf(calc);
                        if (realIndex != -1 && widget.onDeleteItem != null) {
                          widget.onDeleteItem!(realIndex);
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF38383A).withValues(alpha: 0.45)
                              : const Color(0xFFF7F8FA),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: dividerColor.withValues(alpha: isDark ? 0.35 : 0.65),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () {
                                    widget.onSelect(calc);
                                    if (widget.isBottomSheet) {
                                      Navigator.pop(context);
                                    }
                                  },
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          if (calc.isConversion && calc.category != null) ...[
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 1.5,
                                              ),
                                              margin: const EdgeInsets.only(right: 6),
                                              decoration: BoxDecoration(
                                                color: accentColor.withValues(alpha: 0.14),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                calc.category!,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: accentColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                          Icon(
                                            calc.isConversion
                                                ? Icons.swap_horiz_rounded
                                                : Icons.access_time_rounded,
                                            size: 12,
                                            color: secondaryText.withValues(alpha: 0.7),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatTimestamp(calc.timestamp),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: secondaryText.withValues(alpha: 0.8),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        calc.expression,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: secondaryText,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        resultFormatted,
                                        style: TextStyle(
                                          fontSize: 19,
                                          fontWeight: FontWeight.w600,
                                          color: primaryText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.copy_rounded, size: 18),
                                  tooltip: 'Copy result',
                                  visualDensity: VisualDensity.compact,
                                  style: IconButton.styleFrom(
                                    foregroundColor: secondaryText,
                                    padding: const EdgeInsets.all(6),
                                    hoverColor: accentColor.withValues(alpha: 0.1),
                                  ),
                                  onPressed: () {
                                    final copyVal = calc.isConversion
                                        ? calc.result
                                        : CalculatorController.formatNumber(calc.result);
                                    Clipboard.setData(ClipboardData(text: copyVal));
                                    ScaffoldMessenger.of(context).removeCurrentSnackBar();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Copied: $copyVal'),
                                        duration: const Duration(seconds: 2),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                ),
                                if (widget.onDeleteItem != null)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                    tooltip: 'Delete',
                                    visualDensity: VisualDensity.compact,
                                    style: IconButton.styleFrom(
                                      foregroundColor: secondaryText.withValues(alpha: 0.75),
                                      padding: const EdgeInsets.all(6),
                                      hoverColor: const Color(0xFFE74C3C).withValues(alpha: 0.1),
                                    ),
                                    onPressed: () {
                                      final realIndex = widget.history.indexOf(calc);
                                      if (realIndex != -1 && widget.onDeleteItem != null) {
                                        widget.onDeleteItem!(realIndex);
                                      }
                                    },
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );

    if (widget.isBottomSheet) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 540,
            maxHeight: MediaQuery.of(context).size.height * 0.82,
          ),
          child: Material(
            color: Colors.transparent,
            child: content,
          ),
        ),
      );
    } else {
      return content;
    }
  }

  Widget _buildFilterChip(
    String label,
    HistoryFilter filter,
    Color accentColor,
    Color primaryText,
    Color secondaryText,
    Color dividerColor,
  ) {
    final isSelected = _currentFilter == filter;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        setState(() {
          _currentFilter = filter;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? accentColor : dividerColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : secondaryText,
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime time) {
    final now = DateTime.now();
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute';

    final isSameDay = now.year == time.year &&
        now.month == time.month &&
        now.day == time.day;
    if (isSameDay) {
      return 'Today, $timeStr';
    }

    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = yesterday.year == time.year &&
        yesterday.month == time.month &&
        yesterday.day == time.day;
    if (isYesterday) {
      return 'Yesterday, $timeStr';
    }

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final monthName = months[time.month - 1];
    return '$monthName ${time.day}, $timeStr';
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Clear All History?'),
        content: const Text(
          'This will permanently delete all saved calculations.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              widget.onClear();
              if (widget.isBottomSheet) {
                Navigator.pop(context);
              }
            },
            child: const Text(
              'Clear All',
              style: TextStyle(
                color: Color(0xFFE74C3C),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
