import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'services/hrDashboardService.dart'; // For formatting date
// import 'date_service.dart'; // Import the service file

class DatePickerButton extends StatefulWidget {
  @override
  _DatePickerButtonState createState() => _DatePickerButtonState();
}

class _DatePickerButtonState extends State<DatePickerButton> {
  DateTime? _selectedDate;
  Map<String, Map<String, String>> _data = {};

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchData(DateFormat('yyyy-MM-dd').format(picked));
    }
  }

  void _fetchData(String date) async {
    DateService service = DateService();
    Map<String, Map<String, String>> data = await service.getDataByDate(date);
    setState(() {
      _data = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Page'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () => _selectDate(context),
            child: Text('Select date'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _data.length,
              itemBuilder: (context, index) {
                String email = _data.keys.elementAt(index);
                Map<String, String> emailData = _data[email]!;

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(email),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                                child:
                                    Text('Check-in: ${emailData['checkIn']}')),
                            Expanded(
                                child: Text(
                                    'Check-out: ${emailData['checkOut']}')),
                          ],
                        ),
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            children: [
                              const TextSpan(
                                text: 'Status: ',
                                style: TextStyle(color: Colors.black),
                              ),
                              TextSpan(
                                text: 'present',
                                style: const TextStyle(color: Colors.green),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
                // },

                // return Card(
                //   child: ListTile(
                //     title: Text(email),
                //     subtitle: Text('Check-in: ${emailData['checkIn']}\nCheck-out: ${emailData['checkOut']}'),
                //   ),
                // );
              },
            ),
          ),
        ],
      ),
    );
  }
}