import 'package:avant/api/api_service.dart';
import 'package:avant/db/db_helper.dart';
import 'package:avant/visit/customer_search_visit_list.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/city_list_for_search_customer_response.dart';

class CustomerSearchVisit extends StatefulWidget {
  const CustomerSearchVisit({super.key});

  @override
  CustomerSearchVisitPageState createState() => CustomerSearchVisitPageState();
}

class CustomerSearchVisitPageState extends State<CustomerSearchVisit> {
  late SharedPreferences prefs;
  late String token;
  late int executiveId;
  late String downHierarchy;

  DatabaseHelper dbHelper = DatabaseHelper();

  List<CityList> cityList = [];
  CityList? _selectedCity;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _cityFieldKey = GlobalKey<FormFieldState>();

  final FocusNode _cityFocusNode = FocusNode();

  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerCodeController = TextEditingController();
  final TextEditingController _teacherNameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCityAccess();
  }

  void _fetchCityAccess() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token') ?? '';
      executiveId = prefs.getInt('executiveId') ?? 0;
      downHierarchy = prefs.getString('DownHierarchy') ?? '';
    });
    _fetchCityData();
  }

  void _fetchCityData() async {
    CityListForSearchCustomerService service =
        CityListForSearchCustomerService();
    try {
      CityListForSearchCustomerResponse response = await service
          .getCityListForSearchCustomer(executiveId, downHierarchy, token);
      setState(() {
        cityList = response.cityList;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DSR Entry'),
        backgroundColor: const Color(0xFFFFF8E1),
      ),
      body: _isLoading // Show progress bar while loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    color: const Color(0xFFF49B20),
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                      child: Text(
                        'Search Customer - Visit',
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
                              'Customer Name', _customerNameController),
                          buildTextField(
                              'Customer Code', _customerCodeController),
                          buildTextField('Principal / Teacher Name',
                              _teacherNameController),
                          _buildDropdownFieldCity('City', _cityController,
                              _cityFieldKey, _cityFocusNode),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            _submitForm();
                          },
                          child: Container(
                            width: double.infinity,
                            color: Colors.blue,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 16),
                              child: Text(
                                'Search Customer',
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
    if (kDebugMode) {
      print('Form submitted!');
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerSearchVisitList(
          customerId: 0,
          customerName: _customerNameController.text,
          customerCode: _customerCodeController.text,
          contactName: _teacherNameController.text,
          cityId: '${_selectedCity?.cityId ?? ''}',
          cityName: _selectedCity?.cityName ?? '',
        ),
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12.0,
            horizontal: 12.0,
          ),
          alignLabelWithHint: true,
        ),
        controller: controller,
      ),
    );
  }

  Widget _buildDropdownFieldCity(
    String label,
    TextEditingController controller,
    GlobalKey<FormFieldState> fieldKey,
    FocusNode focusNode,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<CityList>(
        key: fieldKey,
        focusNode: focusNode,
        value: _selectedCity,
        items: cityList
            .map(
              (city) => DropdownMenuItem<CityList>(
                value: city,
                child: Text(city.cityName),
              ),
            )
            .toList(),
        onChanged: (CityList? value) {
          setState(() {
            _selectedCity = value;

            // Update the text controller with the selected city name
            controller.text = value?.cityName ?? '';

            // Validate the field
            fieldKey.currentState?.validate();
          });
        },
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerCodeController.dispose();
    _teacherNameController.dispose();
    _cityController.dispose();
    super.dispose();
  }
}
