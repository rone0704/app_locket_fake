import 'dart:async';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import 'app_utils.dart';
import 'image_url_utils.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  int _previewIndex = 0;
  final PageController _previewPageController = PageController(viewportFraction: 1);

  DateTime _normalizeDay(DateTime day) => DateTime(day.year, day.month, day.day);

  String _formatTime(DateTime value) {
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  List<_HistoryPhoto> _photosOfDay(
    Map<DateTime, List<_HistoryPhoto>> photosByDate,
    DateTime? day,
  ) {
    if (day == null) return const <_HistoryPhoto>[];
    return photosByDate[_normalizeDay(day)] ?? const <_HistoryPhoto>[];
  }

  Widget _buildHistoryImage(String imageUrl, {BoxFit fit = BoxFit.cover}) {
    final provider = resolveImageProvider(imageUrl);
    if (provider == null) {
      return Container(
        color: Colors.black12,
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image_rounded, color: Colors.white54, size: 28),
      );
    }

    return Image(
      image: provider,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.black12,
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image_rounded, color: Colors.white54, size: 28),
        );
      },
    );
  }

  Future<void> _showMonthlyRecap(List<_HistoryPhoto> monthPhotos) async {
    if (monthPhotos.isEmpty || !mounted) return;

    final PageController recapController = PageController();
    int current = 0;
    Timer? timer;

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (context) {
        timer = Timer.periodic(const Duration(seconds: 2), (_) {
          if (!recapController.hasClients) return;
          current = (current + 1) % monthPhotos.length;
          recapController.animateToPage(
            current,
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
          );
        });

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 42),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                PageView.builder(
                  controller: recapController,
                  itemCount: monthPhotos.length,
                  itemBuilder: (context, index) {
                    return _buildHistoryImage(monthPhotos[index].imageUrl);
                  },
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.72),
                        ],
                      ),
                    ),
                    child: const Text(
                      'Monthly Recap • kỷ niệm tháng này',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    timer?.cancel();
    recapController.dispose();
  }

  Widget _buildDayCell(
    BuildContext context,
    DateTime day,
    Map<DateTime, List<_HistoryPhoto>> photosByDate, {
    required bool isSelected,
    required bool isToday,
    required bool isOutside,
  }) {
    final photos = _photosOfDay(photosByDate, day);

    if (photos.isEmpty) {
      final textColor = isOutside ? ThemeColors.textMuted(context) : ThemeColors.textPrimary(context);
      return Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: textColor.withValues(alpha: isOutside ? 0.55 : 1),
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _buildHistoryImage(photos.first.imageUrl),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.black.withValues(alpha: isSelected ? 0.14 : 0.28),
              ),
            ),
          ),
          if (photos.length > 1)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.56),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${photos.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFF2BE00)
                    : (isToday ? const Color(0xFFF2BE00).withValues(alpha: 0.85) : Colors.transparent),
                shape: BoxShape.circle,
                boxShadow: isSelected
                    ? <BoxShadow>[
                        BoxShadow(
                          color: const Color(0xFFF2BE00).withValues(alpha: 0.52),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                '${day.day}',
                style: TextStyle(
                  color: isSelected || isToday ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _previewPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: isDark ? Colors.black : const Color(0xFFF8F7F3),
        appBar: AppBar(
          title: const Text('Lịch sử', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32)),
          backgroundColor: Colors.transparent,
          foregroundColor: isDark ? Colors.white : const Color(0xFF181A1F),
          centerTitle: true,
        ),
        body: Center(
          child: Text(
            'Vui lòng đăng nhập để xem lịch sử',
            style: TextStyle(color: ThemeColors.textSecondary(context)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF8F7F3),
      appBar: AppBar(
        title: const Text('Lịch sử', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32)),
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : const Color(0xFF181A1F),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('timestamp', descending: true)
            .limit(500)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.amber));
          }

          final docs = snapshot.data!.docs;
          final myPosts = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            final ownerUid = data?['userId']?.toString();
            final ownerEmail = data?['email']?.toString();
            return ownerUid == user.uid || ownerEmail == user.email;
          }).toList();

          final photosByDate = <DateTime, List<_HistoryPhoto>>{};
          for (final doc in myPosts) {
            final data = doc.data() as Map<String, dynamic>;
            final imageUrl = data['imageUrl']?.toString() ?? '';
            if (imageUrl.isEmpty) continue;

            final ts = data['timestamp'];
            DateTime capturedAt;
            if (ts is Timestamp) {
              capturedAt = ts.toDate();
            } else {
              capturedAt = DateTime.now();
            }

            final dayKey = _normalizeDay(capturedAt);
            final author = (data['author']?.toString().trim().isNotEmpty ?? false)
                ? data['author'].toString().trim()
                : ((data['email']?.toString() ?? user.email ?? 'Bạn').split('@').first);
            final location = (data['location']?.toString().trim().isNotEmpty ?? false)
                ? data['location'].toString().trim()
                : 'Không có vị trí';

            final photo = _HistoryPhoto(
              imageUrl: imageUrl,
              capturedAt: capturedAt,
              timeLabel: _formatTime(capturedAt),
              locationLabel: location,
              senderLabel: author,
            );

            photosByDate.putIfAbsent(dayKey, () => <_HistoryPhoto>[]).add(photo);
          }

          for (final entry in photosByDate.entries) {
            entry.value.sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
          }

          final selectedPhotos = _photosOfDay(photosByDate, _selectedDay);
          final isSelectedDayHavingPhoto = selectedPhotos.isNotEmpty;
          final safePreviewIndex = selectedPhotos.isEmpty
              ? 0
              : _previewIndex.clamp(0, selectedPhotos.length - 1);

          final monthPhotos = <_HistoryPhoto>[];
          for (final entry in photosByDate.entries) {
            if (entry.key.year == _focusedDay.year && entry.key.month == _focusedDay.month) {
              monthPhotos.addAll(entry.value);
            }
          }
          monthPhotos.sort((a, b) => a.capturedAt.compareTo(b.capturedAt));

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Row(
                  children: <Widget>[
                    Text(
                      'Tháng ${_focusedDay.month}/${_focusedDay.year}',
                      style: TextStyle(
                        color: ThemeColors.textSecondary(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: monthPhotos.isEmpty ? null : () => _showMonthlyRecap(monthPhotos),
                      icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                      label: Text('Xem lại tháng ${_focusedDay.month}'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.amber,
                        textStyle: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: (isDark ? const Color(0xFF1E1E1E) : Colors.white).withValues(alpha: 0.82),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                      ),
                      child: TableCalendar(
                        locale: 'vi_VN',
                        firstDay: DateTime.utc(2023, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                            _previewIndex = 0;
                          });
                          _previewPageController.jumpToPage(0);
                        },
                        onPageChanged: (day) => _focusedDay = day,
                        calendarStyle: CalendarStyle(
                          cellMargin: const EdgeInsets.all(4),
                          defaultTextStyle: TextStyle(color: ThemeColors.textPrimary(context)),
                          weekendTextStyle: TextStyle(color: ThemeColors.textMuted(context)),
                          outsideTextStyle: TextStyle(color: ThemeColors.divider(context).withValues(alpha: 0.5)),
                          todayDecoration: const BoxDecoration(color: Colors.transparent),
                          selectedDecoration: const BoxDecoration(color: Colors.transparent),
                        ),
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          titleTextStyle: TextStyle(
                            color: ThemeColors.textPrimary(context),
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                          leftChevronIcon: Icon(Icons.chevron_left_rounded, color: ThemeColors.textPrimary(context), size: 28),
                          rightChevronIcon: Icon(Icons.chevron_right_rounded, color: ThemeColors.textPrimary(context), size: 28),
                        ),
                        calendarBuilders: CalendarBuilders(
                          defaultBuilder: (context, day, _) => _buildDayCell(
                            context,
                            day,
                            photosByDate,
                            isSelected: isSameDay(_selectedDay, day),
                            isToday: isSameDay(DateTime.now(), day),
                            isOutside: false,
                          ),
                          outsideBuilder: (context, day, _) => _buildDayCell(
                            context,
                            day,
                            photosByDate,
                            isSelected: isSameDay(_selectedDay, day),
                            isToday: isSameDay(DateTime.now(), day),
                            isOutside: true,
                          ),
                          todayBuilder: (context, day, _) => _buildDayCell(
                            context,
                            day,
                            photosByDate,
                            isSelected: isSameDay(_selectedDay, day),
                            isToday: true,
                            isOutside: false,
                          ),
                          selectedBuilder: (context, day, _) => _buildDayCell(
                            context,
                            day,
                            photosByDate,
                            isSelected: true,
                            isToday: isSameDay(DateTime.now(), day),
                            isOutside: false,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF121212) : const Color(0xFFF8F7F3),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                  ),
                  child: isSelectedDayHavingPhoto
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                          child: Stack(
                            fit: StackFit.expand,
                            children: <Widget>[
                              PageView.builder(
                                controller: _previewPageController,
                                itemCount: selectedPhotos.length,
                                onPageChanged: (value) => setState(() => _previewIndex = value),
                                itemBuilder: (context, index) {
                                  return _buildHistoryImage(selectedPhotos[index].imageUrl);
                                },
                              ),
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: <Color>[
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.72),
                                      ],
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        '${selectedPhotos[safePreviewIndex].senderLabel} • ${selectedPhotos[safePreviewIndex].timeLabel}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        selectedPhotos[safePreviewIndex].locationLabel,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: List<Widget>.generate(
                                          selectedPhotos.length,
                                          (index) => AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            width: index == safePreviewIndex ? 20 : 7,
                                            height: 7,
                                            margin: const EdgeInsets.only(right: 6),
                                            decoration: BoxDecoration(
                                              color: index == safePreviewIndex ? Colors.amber : Colors.white38,
                                              borderRadius: BorderRadius.circular(99),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(Icons.sentiment_dissatisfied_rounded, size: 60, color: ThemeColors.divider(context)),
                            const SizedBox(height: 16),
                            Text(
                              'Không có ảnh ngày ${_selectedDay?.day}/${_selectedDay?.month}',
                              style: TextStyle(color: ThemeColors.textMuted(context), fontSize: 16),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HistoryPhoto {
  final String imageUrl;
  final DateTime capturedAt;
  final String timeLabel;
  final String locationLabel;
  final String senderLabel;

  const _HistoryPhoto({
    required this.imageUrl,
    required this.capturedAt,
    required this.timeLabel,
    required this.locationLabel,
    required this.senderLabel,
  });
}
