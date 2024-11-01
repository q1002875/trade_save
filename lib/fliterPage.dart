import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// 篩選對話框
class FilterDialog extends StatefulWidget {
  final TradeFilter initialFilter;

  const FilterDialog({super.key, required this.initialFilter});

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

// 篩選條件數據類
class TradeFilter {
  DateTime? startDate;
  DateTime? endDate;
  String? direction;
  String? bigTimePeriod;
  bool? isProfitable;

  TradeFilter({
    this.startDate,
    this.endDate,
    this.direction,
    this.bigTimePeriod,
    this.isProfitable,
  });

  bool isEmpty() {
    return startDate == null &&
        endDate == null &&
        direction == null &&
        bigTimePeriod == null &&
        isProfitable == null;
  }
}

class _FilterDialogState extends State<FilterDialog> {
  late TradeFilter _filter;
  final _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('篩選條件'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 日期範圍選擇
            _buildDateRangeSection(),
            const Divider(),

            // 交易方向選擇
            _buildDirectionSection(),
            const Divider(),

            // 時段選擇
            _buildTimePeriodSection(),
            const Divider(),

            // 盈虧選擇
            _buildProfitabilitySection(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context, _filter);
          },
          child: const Text('確定'),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _filter = TradeFilter();
            });
          },
          child: const Text('清除'),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _filter = TradeFilter(
      startDate: widget.initialFilter.startDate,
      endDate: widget.initialFilter.endDate,
      direction: widget.initialFilter.direction,
      bigTimePeriod: widget.initialFilter.bigTimePeriod,
      isProfitable: widget.initialFilter.isProfitable,
    );
  }

  Widget _buildDateRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('日期範圍', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _filter.startDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _filter.startDate = date);
                  }
                },
                child: Text(_filter.startDate == null
                    ? '起始日期'
                    : _dateFormat.format(_filter.startDate!)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _filter.endDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _filter.endDate = date);
                  }
                },
                child: Text(_filter.endDate == null
                    ? '結束日期'
                    : _dateFormat.format(_filter.endDate!)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDirectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('交易方向', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('做多'),
              selected: _filter.direction == '做多',
              onSelected: (selected) {
                setState(() {
                  _filter.direction = selected ? '做多' : null;
                });
              },
            ),
            ChoiceChip(
              label: const Text('做空'),
              selected: _filter.direction == '做空',
              onSelected: (selected) {
                setState(() {
                  _filter.direction = selected ? '做空' : null;
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfitabilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('盈虧', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('盈利'),
              selected: _filter.isProfitable == true,
              onSelected: (selected) {
                setState(() {
                  _filter.isProfitable = selected ? true : null;
                });
              },
            ),
            ChoiceChip(
              label: const Text('虧損'),
              selected: _filter.isProfitable == false,
              onSelected: (selected) {
                setState(() {
                  _filter.isProfitable = selected ? false : null;
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimePeriodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('時段', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('早盤'),
              selected: _filter.bigTimePeriod == '早盤',
              onSelected: (selected) {
                setState(() {
                  _filter.bigTimePeriod = selected ? '早盤' : null;
                });
              },
            ),
            ChoiceChip(
              label: const Text('午盤'),
              selected: _filter.bigTimePeriod == '午盤',
              onSelected: (selected) {
                setState(() {
                  _filter.bigTimePeriod = selected ? '午盤' : null;
                });
              },
            ),
            ChoiceChip(
              label: const Text('晚盤'),
              selected: _filter.bigTimePeriod == '晚盤',
              onSelected: (selected) {
                setState(() {
                  _filter.bigTimePeriod = selected ? '晚盤' : null;
                });
              },
            ),
          ],
        ),
      ],
    );
  }
}
