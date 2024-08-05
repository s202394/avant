import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class NewCustomerForm extends StatefulWidget {
  final String? customerType;

  NewCustomerForm({
    required this.customerType,
  });

  @override
  _NewCustomerFormState createState() => _NewCustomerFormState();
}

class _NewCustomerFormState extends State<NewCustomerForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _customerTypeController =
      TextEditingController(text: '');
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _primaryContactNameController =
      TextEditingController();
  final TextEditingController _primaryContactDesignationController =
      TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _pinCodeController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _emailIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _customerTypeController.text = widget.customerType ?? '';
  }

  late GoogleMapController mapController;
  final LatLng _center = const LatLng(28.7041, 77.1025);

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Customer'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField('Customer Type', _customerTypeController,
                  enabled: false),
              _buildTextField('Customer Name', _customerNameController),
              _buildTextField(
                  'Primary Contact Name', _primaryContactNameController),
              _buildTextField('Primary Contact Designation',
                  _primaryContactDesignationController),
              SizedBox(height: 16.0),
              Text('Pin Location', style: TextStyle(fontSize: 16)),
              SizedBox(height: 8.0),
              Container(
                height: 200.0,
                child: GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _center,
                    zoom: 15.0,
                  ),
                  markers: {
                    Marker(
                      markerId: MarkerId('location'),
                      position: _center,
                    ),
                  },
                ),
              ),
              SizedBox(height: 16.0),
              _buildTextField('Address', _addressController),
              _buildTextField('City', _cityController),
              _buildTextField('Pin Code', _pinCodeController),
              _buildTextField('Phone Number', _phoneNumberController),
              _buildTextField('Email Id', _emailIdController),
              SizedBox(height: 16.0),
              GestureDetector(
                onTap: () {
                  if (_formKey.currentState!.validate()) {}
                },
                child: Container(
                  width: double.infinity,
                  color: Colors.blue,
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                    child: Text(
                      'Add Customer',
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool enabled = true, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        enabled: enabled,
        maxLines: maxLines,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdownField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: controller.text.isEmpty ? null : controller.text,
        items: ['Type 1', 'Type 2', 'Type 3']
            .map((type) => DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                ))
            .toList(),
        onChanged: (value) {
          setState(() {
            controller.text = value ?? '';
          });
        },
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select $label';
          }
          return null;
        },
      ),
    );
  }
}
