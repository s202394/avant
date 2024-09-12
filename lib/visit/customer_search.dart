import 'package:avant/api/api_service.dart';
import 'package:avant/db/db_helper.dart';
import 'package:avant/model/login_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/city_list_for_search_customer_response.dart';
import 'customer_search_list.dart';

class CustomerSearch extends StatefulWidget {
  final String type;
  final String title;

  const CustomerSearch({super.key, required this.type, required this.title});

  @override
  CustomerSearchPageState createState() => CustomerSearchPageState();
}

class CustomerSearchPageState extends State<CustomerSearch> {
  late SharedPreferences prefs;
  late String token;
  late int executiveId;
  late String downHierarchy;

  bool _submitted = false;

  DatabaseHelper dbHelper = DatabaseHelper();

  List<CityList> cityList = [];
  CityList? _selectedCity;
  List<String> customerTypesList = [];
  String? _selectedCustomerType;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _cityFieldKey = GlobalKey<FormFieldState>();
  final _customerTypeFieldKey = GlobalKey<FormFieldState>();

  final FocusNode _cityFocusNode = FocusNode();
  final FocusNode _customerTypeFocusNode = FocusNode();

  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerCodeController = TextEditingController();
  final TextEditingController _teacherNameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _customerTypeController = TextEditingController();

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
      downHierarchy = prefs.getString('DownHierarchy') ?? '';
    });
    executiveId = await getExecutiveId() ?? 0;

    customerTypesList = await DatabaseHelper().getCustomerTypesListFromDB();
    if (customerTypesList.isNotEmpty) {
      if (kDebugMode) {
        print("CustomerTypes List: $customerTypesList");
      }
    } else {
      if (kDebugMode) {
        print("CustomerTypes key not found or no data in the database.");
      }
    }

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
        title: Text(widget.title),
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16),
                      child: Text(
                        'Search Customer - ${widget.type}',
                        textAlign: TextAlign.start,
                        style: const TextStyle(
                          color: Colors.white,
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
                          _buildDropdownFieldCustomerType(
                              'Customer Type',
                              _customerTypeController,
                              _customerTypeFieldKey,
                              _customerTypeFocusNode),
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
                            setState(() {
                              _submitted = true;
                            });
                            if (_formKey.currentState!.validate() &&
                                (_selectedCustomerType ?? '').isNotEmpty) {
                              _submitForm();
                            }
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
        builder: (context) => CustomerSearchList(
          type: widget.type,
          title: widget.title,
          customerId: 0,
          customerName: _customerNameController.text,
          customerCode: _customerCodeController.text,
          contactName: _teacherNameController.text,
          cityId: '${_selectedCity?.cityId ?? ''}',
          cityName: _selectedCity?.cityName ?? '',
          customerType: _selectedCustomerType ?? '',
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

  Widget _buildDropdownFieldCustomerType(
    String label,
    TextEditingController controller,
    GlobalKey<FormFieldState> fieldKey,
    FocusNode focusNode,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        key: fieldKey,
        focusNode: focusNode,
        value: _selectedCustomerType,
        items: customerTypesList
            .map(
              (type) => DropdownMenuItem<String>(
                value: type,
                child: Text(type),
              ),
            )
            .toList(),
        onChanged: (String? value) {
          setState(() {
            _selectedCustomerType = value;

            // Update the text controller with the selected customer type
            controller.text = value ?? '';

            // Validate the field
            fieldKey.currentState?.validate();
          });
        },
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          errorText: _submitted && _selectedCustomerType == null
              ? 'Please select a $label'
              : null,
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
    _customerTypeController.dispose();
    super.dispose();
  }
}
