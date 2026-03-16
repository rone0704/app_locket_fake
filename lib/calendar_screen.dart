import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

  // DANH SÁCH GIẢ LẬP: Khai báo hôm nay và 2 ngày trước là có chụp ảnh
  final List<DateTime> _daysWithPhotos = [
    DateTime.now(),
    DateTime.now().subtract(const Duration(days: 2)),
  ];

  @override
  Widget build(BuildContext context) {
    // Kiểm tra xem ngày đang chọn có nằm trong danh sách có ảnh không
    bool isSelectedDayHavingPhoto = _daysWithPhotos.any((d) => isSameDay(d, _selectedDay));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Lịch sử", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(20)),
              child: TableCalendar(
                firstDay: DateTime.utc(2023, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                calendarStyle: const CalendarStyle(
                  defaultTextStyle: TextStyle(color: Colors.white),
                  weekendTextStyle: TextStyle(color: Colors.white54),
                  outsideTextStyle: TextStyle(color: Colors.white24),
                  todayDecoration: BoxDecoration(color: Color(0xFF333333), shape: BoxShape.circle),
                  selectedDecoration: BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                  selectedTextStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
                headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true, titleTextStyle: TextStyle(color: Colors.white, fontSize: 18)),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    if (_daysWithPhotos.any((d) => isSameDay(d, day))) {
                      return Positioned(
                        bottom: 4,
                        child: Icon(Icons.circle, size: 6, color: isSameDay(_selectedDay, day) ? Colors.black : Colors.amber),
                      );
                    }
                    return null;
                  },
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // --- HIỂN THỊ ẢNH NẾU NGÀY ĐÓ CÓ CHỤP ---
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF121212),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: isSelectedDayHavingPhoto 
                ? ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    // Hiển thị ảnh mẫu từ mạng cho sinh động
                    child: Image.network(
                      "https://images.unsplash.com/photo-1517849845537-4d257902454a?q=80&w=800&auto=format&fit=crop",
                      fit: BoxFit.cover,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sentiment_dissatisfied_rounded, size: 60, color: Colors.white24),
                      const SizedBox(height: 16),
                      Text("Không có ảnh ngày ${_selectedDay?.day}/${_selectedDay?.month}", style: const TextStyle(color: Colors.white54, fontSize: 16)),
                    ],
                  ),
            ),
          ),
        ],
      ),
    );
  }
}