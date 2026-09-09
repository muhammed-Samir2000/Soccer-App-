import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../shared/widgets/app_page_app_bar.dart';
import '../../bookings/domain/booking.dart';
import '../../bookings/domain/booking_repository.dart';
import '../domain/financial_report.dart';

class FinancialAnalyticsScreen extends StatefulWidget {
  const FinancialAnalyticsScreen({super.key, required this.repository});

  final BookingRepository repository;

  @override
  State<FinancialAnalyticsScreen> createState() =>
      _FinancialAnalyticsScreenState();
}

class _FinancialAnalyticsScreenState extends State<FinancialAnalyticsScreen> {
  late Future<List<Booking>> _bookings;
  late DateTime _startMonth;
  late DateTime _endMonth;

  @override
  void initState() {
    super.initState();
    final DateTime today = DateTime.now();
    _endMonth = DateTime(today.year, today.month);
    _startMonth = DateTime(today.year, today.month - 2);
    _bookings = widget.repository.getBookings();
  }

  Future<void> _selectPeriod() async {
    final DateTimeRange? selection = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
      initialDateRange: DateTimeRange(start: _startMonth, end: _endMonth),
      helpText: 'اختار فترة التحليل',
      saveText: 'تطبيق',
    );
    if (selection == null || !mounted) {
      return;
    }
    setState(() {
      _startMonth = DateTime(selection.start.year, selection.start.month);
      _endMonth = DateTime(selection.end.year, selection.end.month);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const AppPageAppBar(title: 'التحليل المالي'),
    body: FutureBuilder<List<Booking>>(
      future: _bookings,
      builder: (BuildContext context, AsyncSnapshot<List<Booking>> snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final FinancialReport report = FinancialReport.fromBookings(
          bookings: snapshot.data!,
          startMonth: _startMonth,
          endMonth: _endMonth,
        );
        return ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 32),
          children: [
            Text(
              'التحصيل المالي',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            const Text('تابع المبالغ المحصلة وقارنها بالفترة اللي قبلها.'),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: _selectPeriod,
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(_periodLabel(report.startMonth, report.endMonth)),
            ),
            const SizedBox(height: 18),
            _CollectedHero(report: report),
            const SizedBox(height: 16),
            _FinancialMetrics(report: report),
            const SizedBox(height: 24),
            _TrendCard(report: report),
            const SizedBox(height: 18),
            _ComparisonCard(report: report),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'التحصيل هنا مبني على الحجوزات المؤكدة والثابتة في النسخة التجريبية. الحجز المبدئي لا يُحسب كمبلغ محصل.',
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _CollectedHero extends StatelessWidget {
  const _CollectedHero({required this.report});

  final FinancialReport report;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final int difference = report.differenceFromPrevious;
    final String comparison = report.changeRate == null
        ? report.comparisonAmount == 0
              ? 'لا توجد فترة محصلة سابقة للمقارنة'
              : ''
        : '${difference >= 0 ? '+' : ''}${(report.changeRate! * 100).round()}% عن الفترة السابقة';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, const Color(0xFF123C31)],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المبلغ المحصل',
                  style: TextStyle(
                    color: colors.onPrimary.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _money(report.collectedAmount),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  comparison,
                  style: TextStyle(
                    color: colors.onPrimary.withValues(alpha: 0.84),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: colors.onPrimary.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              color: colors.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FinancialMetrics extends StatelessWidget {
  const _FinancialMetrics({required this.report});

  final FinancialReport report;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _MetricCard(
          label: 'حجوزات محصلة',
          value: '${report.collectedBookings}',
          icon: Icons.check_circle_outline,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _MetricCard(
          label: 'مبدئي غير محصل',
          value: _money(report.pendingAmount),
          icon: Icons.pending_outlined,
          accent: Colors.orange.shade800,
        ),
      ),
    ],
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final Color color = accent ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 14),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 3),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.report});

  final FinancialReport report;

  @override
  Widget build(BuildContext context) => _AnalyticsCard(
    title: 'حركة التحصيل',
    subtitle: 'الإيراد المحصل لكل شهر داخل الفترة المختارة.',
    child: Column(
      children: [
        SizedBox(
          height: 170,
          child: CustomPaint(
            painter: _RevenueTrendPainter(
              values: report.trend
                  .map((MonthlyCollection item) => item.collectedAmount)
                  .toList(),
              color: Theme.of(context).colorScheme.primary,
            ),
            child:
                report.trend.every(
                  (MonthlyCollection item) => item.collectedAmount == 0,
                )
                ? const Center(child: Text('لسه مفيش تحصيل مؤكد في الفترة دي.'))
                : null,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: report.trend
              .map(
                (MonthlyCollection item) => Text(
                  _monthShortLabel(item.month),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
              .toList(),
        ),
      ],
    ),
  );
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({required this.report});

  final FinancialReport report;

  @override
  Widget build(BuildContext context) => _AnalyticsCard(
    title: 'مقارنة بالفترة السابقة',
    subtitle: 'نفس عدد الشهور قبل بداية الفترة اللي اخترتها.',
    child: _ComparisonBars(
      current: report.collectedAmount,
      previous: report.comparisonAmount,
    ),
  );
}

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 18),
          child,
        ],
      ),
    ),
  );
}

class _ComparisonBars extends StatelessWidget {
  const _ComparisonBars({required this.current, required this.previous});

  final int current;
  final int previous;

  @override
  Widget build(BuildContext context) {
    final int maxValue = math.max(math.max(current, previous), 1);
    return Column(
      children: [
        _ComparisonBar(
          label: 'الفترة المختارة',
          amount: current,
          value: current / maxValue,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        _ComparisonBar(
          label: 'الفترة السابقة',
          amount: previous,
          value: previous / maxValue,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ],
    );
  }
}

class _ComparisonBar extends StatelessWidget {
  const _ComparisonBar({
    required this.label,
    required this.amount,
    required this.value,
    required this.color,
  });

  final String label;
  final int amount;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(child: Text(label)),
          Text(_money(amount), style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
      const SizedBox(height: 7),
      ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: LinearProgressIndicator(
          value: value,
          minHeight: 12,
          color: color,
          backgroundColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest,
        ),
      ),
    ],
  );
}

class _RevenueTrendPainter extends CustomPainter {
  const _RevenueTrendPainter({required this.values, required this.color});

  final List<int> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || values.every((int value) => value == 0)) {
      return;
    }
    const double topPadding = 14;
    const double bottomPadding = 16;
    const double horizontalPadding = 14;
    final double chartHeight = size.height - topPadding - bottomPadding;
    final int maxValue = values.reduce(math.max);
    final Paint grid = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    for (int index = 0; index < 4; index++) {
      final double y = topPadding + chartHeight * index / 3;
      canvas.drawLine(
        Offset(horizontalPadding, y),
        Offset(size.width - horizontalPadding, y),
        grid,
      );
    }

    final List<Offset> points = List<Offset>.generate(values.length, (
      int index,
    ) {
      final double x = values.length == 1
          ? size.width / 2
          : horizontalPadding +
                (size.width - horizontalPadding * 2) *
                    index /
                    (values.length - 1);
      final double y =
          topPadding + chartHeight * (1 - values[index] / maxValue);
      return Offset(x, y);
    });
    final Path line = Path()..moveTo(points.first.dx, points.first.dy);
    for (int index = 1; index < points.length; index++) {
      final Offset previous = points[index - 1];
      final Offset current = points[index];
      line.cubicTo(
        (previous.dx + current.dx) / 2,
        previous.dy,
        (previous.dx + current.dx) / 2,
        current.dy,
        current.dx,
        current.dy,
      );
    }
    final Path fill = Path.from(line)
      ..lineTo(points.last.dx, size.height - bottomPadding)
      ..lineTo(points.first.dx, size.height - bottomPadding)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          colors: [color.withValues(alpha: 0.24), color.withValues(alpha: 0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    for (final Offset point in points) {
      canvas.drawCircle(point, 5, Paint()..color = color);
      canvas.drawCircle(point, 2, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(_RevenueTrendPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}

String _money(int amount) => '$amount ج.م';

String _periodLabel(DateTime start, DateTime end) => start == end
    ? _monthYearLabel(start)
    : 'من ${_monthYearLabel(start)} إلى ${_monthYearLabel(end)}';

String _monthYearLabel(DateTime month) => '${_monthLabel(month)} ${month.year}';

String _monthShortLabel(DateTime month) => _monthLabel(month).substring(0, 3);

String _monthLabel(DateTime month) {
  const List<String> months = <String>[
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];
  return months[month.month - 1];
}
