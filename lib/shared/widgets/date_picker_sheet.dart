import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

const _months = [
  'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
  'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
];

const _weekdays = ['Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct', 'Pz'];

String formatDateTr(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  final parts = iso.split('-');
  if (parts.length < 3) return iso;
  final day = int.tryParse(parts[2]) ?? 0;
  final monthIdx = (int.tryParse(parts[1]) ?? 1) - 1;
  final year = parts[0];
  if (monthIdx < 0 || monthIdx >= 12) return iso;
  return '$day ${_months[monthIdx]} $year';
}

class DatePickerSheet extends StatefulWidget {
  final String title;
  final String? initialDate;
  final String? highlightFrom;
  final String? highlightTo;
  final void Function(String date) onSelected;

  const DatePickerSheet({
    super.key,
    required this.title,
    required this.onSelected,
    this.initialDate,
    this.highlightFrom,
    this.highlightTo,
  });

  @override
  State<DatePickerSheet> createState() => _DatePickerSheetState();
}

class _DatePickerSheetState extends State<DatePickerSheet> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    final ref = widget.initialDate ?? widget.highlightFrom;
    if (ref != null) {
      final p = ref.split('-');
      if (p.length >= 2) {
        _year = int.tryParse(p[0]) ?? DateTime.now().year;
        _month = (int.tryParse(p[1]) ?? DateTime.now().month) - 1;
        return;
      }
    }
    final now = DateTime.now();
    _year = now.year;
    _month = now.month - 1;
  }

  String get _todayStr {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  List<({int? day, String str})> get _cells {
    final firstDow = DateTime(_year, _month + 1, 1).weekday - 1;
    final daysInMonth = DateTime(_year, _month + 2, 0).day;
    final cells = <({int? day, String str})>[];
    for (var i = 0; i < firstDow; i++) {
      cells.add((day: null, str: ''));
    }
    for (var d = 1; d <= daysInMonth; d++) {
      final s = '$_year-${(_month + 1).toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
      cells.add((day: d, str: s));
    }
    return cells;
  }

  bool _inRange(String s) {
    final from = widget.highlightFrom;
    final to = widget.highlightTo;
    if (from == null && to == null) return false;
    final f = from ?? '0000-00-00';
    final t = to ?? '9999-99-99';
    return s.compareTo(f) >= 0 && s.compareTo(t) <= 0;
  }

  void _prev() => setState(() {
        if (_month == 0) {
          _month = 11;
          _year--;
        } else {
          _month--;
        }
      });

  void _next() => setState(() {
        if (_month == 11) {
          _month = 0;
          _year++;
        } else {
          _month++;
        }
      });

  @override
  Widget build(BuildContext context) {
    final today = _todayStr;
    final selected = widget.initialDate;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 16,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
                color: AppColors.gray200,
                borderRadius: BorderRadius.circular(2)),
          ),
          Text(widget.title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gray900)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: _prev,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.chevron_left,
                      size: 20, color: AppColors.gray600),
                ),
              ),
              Text('${_months[_month]} $_year',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gray900)),
              GestureDetector(
                onTap: _next,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.chevron_right,
                      size: 20, color: AppColors.gray600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: _weekdays
                .map((wd) => Expanded(
                      child: Center(
                          child: Text(wd,
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.gray400))),
                    ))
                .toList(),
          ),
          const SizedBox(height: 4),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.1,
            children: _cells.map((cell) {
              if (cell.day == null) return const SizedBox();
              final isSelected = cell.str == selected;
              final isToday = cell.str == today;
              final inRange = _inRange(cell.str);

              Color bg = Colors.transparent;
              Color fg = AppColors.gray700;
              BoxBorder? border;

              if (isSelected) {
                bg = AppColors.blue600;
                fg = Colors.white;
              } else if (inRange) {
                bg = const Color(0xFFFEF3C7);
                fg = const Color(0xFF92400E);
              } else if (isToday) {
                border = Border.all(color: AppColors.blue600, width: 1.5);
                fg = AppColors.blue600;
              }

              return GestureDetector(
                onTap: () {
                  widget.onSelected(cell.str);
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(8),
                    border: border,
                  ),
                  child: Center(
                    child: Text(
                      '${cell.day}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected || isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: fg,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
