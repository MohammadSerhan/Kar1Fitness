import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class DateTimelineSelector extends StatefulWidget {
  final DateTime? initialDate;
  final Function(DateTime) onDateSelected;
  final int daysToShow;

  const DateTimelineSelector({
    Key? key,
    this.initialDate,
    required this.onDateSelected,
    this.daysToShow = 7,
  }) : super(key: key);

  @override
  State<DateTimelineSelector> createState() => _DateTimelineSelectorState();
}

class _DateTimelineSelectorState extends State<DateTimelineSelector> {
  late DateTime _selectedDate;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _scrollController = ScrollController();

    // Auto-scroll to today on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDate();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSelectedDate() {
    final today = DateTime.now();
    final daysSinceSelected = today.difference(_selectedDate).inDays;

    if (daysSinceSelected >= 0 && daysSinceSelected < widget.daysToShow) {
      final scrollPosition = (widget.daysToShow - daysSinceSelected - 1) * 70.0;

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          scrollPosition,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  List<DateTime> _generateDateList() {
    final today = DateTime.now();
    final List<DateTime> dates = [];

    // Generate past dates from oldest to newest
    for (int i = widget.daysToShow - 1; i >= 0; i--) {
      dates.add(today.subtract(Duration(days: i)));
    }

    return dates;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  bool _isToday(DateTime date) {
    return _isSameDay(date, DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final dates = _generateDateList();

    return Container(
      height: 90,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = _isSameDay(date, _selectedDate);
          final isToday = _isToday(date);

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
              });
              widget.onDateSelected(date);
            },
            child: Container(
              width: 70,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryYellow
                    : AppTheme.darkGrey,
                borderRadius: BorderRadius.circular(12),
                border: isToday
                    ? Border.all(color: AppTheme.primaryYellow, width: 2)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Day of week
                  Text(
                    DateFormat('EEE').format(date),
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? AppTheme.darkBackground
                          : AppTheme.lightGrey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Day number
                  Text(
                    DateFormat('d').format(date),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? AppTheme.darkBackground
                          : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Month
                  Text(
                    DateFormat('MMM').format(date),
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected
                          ? AppTheme.darkBackground
                          : AppTheme.lightGrey,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
