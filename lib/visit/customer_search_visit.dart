import 'package:avant/api/api_service.dart';
import 'package:avant/db/db_helper.dart';
import 'package:avant/model/geography_model.dart';
import 'package:avant/visit/customer_search_visit_list.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomerSearchVisit extends StatefulWidget {
  const CustomerSearchVisit({super.key});

  @override
  _CustomerSearchVisitPageState createState() =>
      _CustomerSearchVisitPageState();
}

class _CustomerSearchVisitPageState extends State<CustomerSearchVisit> {
  late SharedPreferences prefs;
  late String token;
  late int executiveId;

  DatabaseHelper dbHelper = DatabaseHelper();

  String _cityAccess = '';
  List<Geography> _filteredCities = [];
  Geography? _selectedCity;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _cityFieldKey = GlobalKey<FormFieldState>();

  final FocusNode _cityFocusNode = FocusNode();

  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerCodeController = TextEditingController();
  final TextEditingController _teacherNameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  bool _submitted = false;
  bool _isLoading = true; // Add loading state

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
      _cityAccess = prefs.getString('CityAccess') ?? '';
    });
    _loadGeographyData();
  }

  void _loadGeographyData() async {
    // Retrieve geography data from the database
    List<Geography> dbData = await dbHelper.getGeographyDataFromDB();
    if (dbData.isNotEmpty) {
      setState(() {
        _filteredCities = dbData;
      });
      print("Loaded geography data from the database.");
    } else {
      print("No data in DB, fetching from API.");
      _fetchGeographyData();
    }
  }

  void _fetchGeographyData() async {
    GeographyService geographyService = GeographyService();
    try {
      GeographyResponse geographyResponse = await geographyService
          .fetchGeographyData(_cityAccess, executiveId, token);
      List<int> cityIds =
          _cityAccess.split(',').map((id) => int.parse(id)).toList();
      setState(() {
        _filteredCities = geographyResponse.geographyList
            .where((geography) => cityIds.contains(geography.cityId))
            .toList();
        _isLoading = false; // Data loaded, stop loading
      });
    } catch (e) {
      print(e);
      setState(() {
        _isLoading = false; // Stop loading in case of error
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
                          buildTextField('Customer Name',
                              _customerNameController, _submitted),
                          buildTextField('Customer Code',
                              _customerCodeController, _submitted),
                          buildTextField('Principal / Teacher Name',
                              _teacherNameController, _submitted),
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
                            setState(() {
                              _submitted = true;
                            });
                            if (_formKey.currentState!.validate()) {
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
    print('Form submitted!');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerSearchVisitList(
          customerId:0,
          customerName: _customerNameController.text,
          customerCode: _customerCodeController.text,
          customerType: _teacherNameController.text,
          address: _selectedCity?.city??'',
          city: _selectedCity?.city??'',
          state: _selectedCity?.city??'',
        ),
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
          border: const OutlineInputBorder(),
          errorText: submitted && controller.text.isEmpty
              ? 'Please enter $label'
              : null,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12.0,
            horizontal: 12.0,
          ),
          alignLabelWithHint: true,
        ),
        controller: controller,
        onChanged: (text) {
          if (_submitted && text.isNotEmpty) {
            setState(() {});
          }
        },
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
      child: DropdownButtonFormField<Geography>(
        key: fieldKey,
        focusNode: focusNode,
        value: _selectedCity,
        items: _filteredCities
            .map(
              (geography) => DropdownMenuItem<Geography>(
                value: geography,
                child: Text(geography.city),
              ),
            )
            .toList(),
        onChanged: (Geography? value) {
          setState(() {
            _selectedCity = value;

            // Update the text controller with the selected city name
            controller.text = value?.city ?? '';

            // Validate the field
            fieldKey.currentState?.validate();
          });
        },
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.city.isEmpty) {
            return 'Please select $label';
          }
          return null;
        },
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
