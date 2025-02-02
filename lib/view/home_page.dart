import 'dart:collection';
import 'package:calender_app/model/todo.dart';
import 'package:calender_app/service/db.dart';
import 'package:calender_app/util/util.dart';
import 'package:calender_app/view/add_task_page.dart';
import 'package:calender_app/view/edit_task_page.dart';
import 'package:calender_app/view_model/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:nholiday_jp/nholiday_jp.dart';

class HomePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _selectedDayNotifier = ref.watch(selectedDayProvider.notifier);
    final _focusedDayProvider = ref.watch(focusedDayProvider);
    final _focusedDayNotifier = ref.watch(focusedDayProvider.notifier);
    final _visibleProvider = ref.watch(visibleProvider);
    final _visibleNotifier = ref.watch(visibleProvider.notifier);
    final _todoDatabaseProvider = ref.watch(todoDatabaseProvider);
    final _todoDatabaseNotifier = ref.watch(todoDatabaseProvider.notifier);
    final _displayMonthProvider = ref.watch(displayMonthProvider);
    final _displayMonthNotifier = ref.watch(displayMonthProvider.notifier);
    final _pageControllerProvider = ref.watch(pageControllerProvider);
    final _pageControllerNotifier = ref.watch(pageControllerProvider.state);

    List<TodoItemData> todoItems = _todoDatabaseNotifier.state.todoItems;

    Map<DateTime, List<String>> eventList() {
      final eventList = <DateTime, List<String>>{};
      for (final todoItem in todoItems) {
        if (todoItem.startTime != null) {
          eventList[todoItem.startTime!] = [todoItem.title];
        }
      }
      return eventList;
    }

    int getHashCode(DateTime key) {
      return key.day * 1000000 + key.month * 10000 + key.year;
    }

    final _events = LinkedHashMap<DateTime, List>(
      equals: isSameDay,
      hashCode: getHashCode,
    )..addAll(eventList());

    List _getEventForDay(DateTime day) {
      return _events[day] ?? [];
    }

    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            color: baseBackGroundColor,
          ),
          Column(
            children: [
              Container(
                child: Column(
                  children: [
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: const Text(
                        'カレンダー',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  ],
                ),
                height: 100,
                width: double.infinity,
                color: Colors.blue,
              ),
              TableCalendar(
                locale: 'ja',
                firstDay: DateTime.utc(2010, 10, 16),
                lastDay: DateTime.utc(2030, 3, 14),
                focusedDay: _focusedDayNotifier.state,
                eventLoader: _getEventForDay,
                startingDayOfWeek: StartingDayOfWeek.monday,
                daysOfWeekHeight: 25.0,
                holidayPredicate: (day) {
                  return false;
                },
                daysOfWeekStyle: DaysOfWeekStyle(
                  decoration: BoxDecoration(
                    border: Border.all(width: 0.1),
                    color: Colors.grey[100],
                  ),
                  weekendStyle: const TextStyle(color: Colors.red),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle:
                      TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
                  decoration: BoxDecoration(color: Colors.white),
                  leftChevronVisible: false,
                  rightChevronVisible: false,
                  headerPadding: EdgeInsets.all(8),
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (BuildContext context, DateTime day,
                      DateTime focusedDay) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 0),
                      alignment: Alignment.center,
                      child: Text(
                        day.day.toString(),
                        style: TextStyle(
                          color: textColor(day),
                        ),
                      ),
                    );
                  },
                ),
                calendarStyle: CalendarStyle(
                  markerMargin: const EdgeInsets.all(6),
                  cellMargin: const EdgeInsets.all(8),
                  rangeHighlightColor: Colors.white,
                  defaultDecoration: const BoxDecoration(color: Colors.white),
                  rowDecoration: const BoxDecoration(color: Colors.white),
                  todayDecoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
                onPageChanged: (date) {
                  _focusedDayNotifier.state = date;
                },
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDayNotifier.state, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  _selectedDayNotifier.state = selectedDay;
                  _selectedDayNotifier.state = focusedDay;
                  _visibleNotifier.state = true;
                  _pageControllerNotifier.state =
                      PageController(initialPage: selectedDay.day - 1);
                },
              ),
            ],
          ),
          Positioned(
            top: 100,
            left: 30.0,
            child: OutlinedButton(
              onPressed: () {
                _visibleNotifier.state = true;
                _pageControllerNotifier.state =
                    PageController(initialPage: dayTime.day - 1);
              },
              child: const Text('今日', style: TextStyle(color: Colors.grey)),
              style: OutlinedButton.styleFrom(
                primary: Colors.grey,
                minimumSize: const Size(50, 30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                side: const BorderSide(color: Colors.grey),
              ),
            ),
          ),
          const Positioned(
            top: 103,
            right: 95,
            child: Icon(
              Icons.arrow_drop_down,
              size: 40,
            ),
          ),
          GestureDetector(
            onTap: () => _visibleNotifier.state = false,
            child: Visibility(
              visible: _visibleProvider,
              child: Container(
                height: double.infinity,
                width: double.infinity,
                color: Colors.black.withOpacity(0.7),
              ),
            ),
          ),
          Visibility(
            visible: _visibleProvider,
            child: Container(
              margin: const EdgeInsets.only(top: 200, bottom: 50),
              child: PageView(
                controller: _pageControllerProvider,
                children: _allDateCard(
                  todoItems,
                  _todoDatabaseNotifier,
                  _focusedDayProvider,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  List<Widget> _allDateCard(
    List<TodoItemData> items,
    TodoDatabaseNotifier db,
    DateTime displayMonth,
  ) {
    final List<Widget> list = [];
    DateTime date = DateTime(displayMonth.year, displayMonth.month, 1);
    while (date.month == displayMonth.month) {
      list.add(
        _dateCard(
          items.where((element) => isSameDay(element.startTime, date)).toList(),
          db,
          date,
        ),
      );
      date = date.add(const Duration(days: 1));
    }
    return list;
  }

  Widget _dateCard(
      List<TodoItemData> items, TodoDatabaseNotifier db, DateTime date) {
    return Consumer(
      builder: ((context, ref, child) {
        return Container(
          margin: const EdgeInsets.only(left: 10, right: 10),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('yyyy/MM/dd (E)', "ja").format(date),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.blue),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddTaskPage(date),
                        ),
                      );
                    },
                  ),
                ],
              ),
              if (items.isNotEmpty)
                ...items.map(
                  (item) {
                    return GestureDetector(
                      onTap: () {
                        final _editStartTimeNotifier =
                            ref.watch(editStartTimeProvider.notifier);
                        _editStartTimeNotifier.state = item.startTime;

                        final _editEndTimeNotifier =
                            ref.watch(editEndTimeProvider.notifier);
                        _editEndTimeNotifier.state = item.endTime;

                        final _editToggleNotifier =
                            ref.watch(editToggleProvider.notifier);
                        _editToggleNotifier.state = item.allDay;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EditTaskPage(item: item, db: db),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          const Divider(height: 2),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                item.allDay == true
                                    ? const Padding(
                                        padding:
                                            EdgeInsets.only(left: 6, right: 6),
                                        child: Text('終日'),
                                      )
                                    : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            DateFormat('HH:mm')
                                                .format(item.startTime!),
                                            style:
                                                const TextStyle(fontSize: 15),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            DateFormat('HH:mm')
                                                .format(item.endTime!),
                                            style:
                                                const TextStyle(fontSize: 15),
                                          )
                                        ],
                                      ),
                                const SizedBox(width: 10),
                                Container(
                                  width: 5,
                                  height: 43,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 20),
                                Text(
                                  (item.title),
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                )
              else
                const Expanded(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 20.0),
                      child: Text('予定がありません。'),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}
