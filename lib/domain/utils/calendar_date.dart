String calendarDate(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
DateTime civilDay(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day);
