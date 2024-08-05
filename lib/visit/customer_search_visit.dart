import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:avant/visit/customer_search_visit.dart';
import 'package:avant/visit/customer_search_visit_list.dart';

class CustomerSearchVisit extends StatefulWidget {
  @override
  _CustomerSearchVisitPageState createState() =>
      _CustomerSearchVisitPageState();
}

class _CustomerSearchVisitPageState extends State<CustomerSearchVisit> {
  String? selectedCity;

  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  TextEditingController _customerNameController = TextEditingController();
  TextEditingController _customerCodeController = TextEditingController();
  TextEditingController _teacherNameController = TextEditingController();

  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('DSR Entry'),
        backgroundColor: Color(0xFFFFF8E1),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: Color(0xFFF49B20),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                child: Text(
                  'Search Costumer - Visit',
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView(
                  children: [
                    buildTextField(
                        'Customer Name', _customerNameController, _submitted),
                    buildTextField(
                        'Customer Code', _customerCodeController, _submitted),
                    buildTextField('Principal / Teacher Name',
                        _teacherNameController, _submitted),
                    buildDropdownField('City', selectedCity, (value) {
                      setState(() {
                        selectedCity = value;
                      });
                    }),
                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _submitted = true;
                      });
                      if (_formKey.currentState!.validate() &&
                          selectedCity != null) {
                        _submitForm();
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      color: Colors.blue,
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                        child: Text(
                          'Search Costumer',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submitForm() {
    print('Form submitted!');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerSearchVisitList(
            customerName: _customerNameController.text,
            customerCode: _customerCodeController.text,
            principalName: _teacherNameController.text,
            city: selectedCity),
      ),
    );
  }

  Widget buildTextField(
      String label, TextEditingController controller, bool submitted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          errorText: submitted && controller.text.isEmpty
              ? 'Please enter $label'
              : null,
          contentPadding: EdgeInsets.symmetric(
            vertical: 12.0,
            horizontal: 12.0,
          ),
          alignLabelWithHint: true,
        ),
        controller: controller,
        onChanged: (text) {
          if (_submitted && text.isNotEmpty) {
            setState(() {

            });
          }
        },
      ),
    );
  }

  Widget buildDropdownField(
      String label, String? selectedValue, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          errorText: _submitted && selectedValue == null
              ? 'Please select a $label'
              : null,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isDense: true,
            value: selectedValue,
            items: [
              DropdownMenuItem(child: Text('Option 1'), value: 'Option 1'),
              DropdownMenuItem(child: Text('Option 2'), value: 'Option 2'),
            ],
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerCodeController.dispose();
    _teacherNameController.dispose();
    super.dispose();
  }
}
