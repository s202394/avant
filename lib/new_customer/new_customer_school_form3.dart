import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:avant/model/customer_entry_master_model.dart';
import 'package:avant/api/api_service.dart';

class NewCustomerSchoolForm2 extends StatefulWidget {
  @override
  _NewCustomerSchoolForm2State createState() => _NewCustomerSchoolForm2State();
}

class _NewCustomerSchoolForm2State extends State<NewCustomerSchoolForm2> {
  late Future<CustomerEntryMasterResponse> futureData;
  String? _selectedStartClass;
  String? _selectedEndClass;
  String? _selectedSamplingMonth;
  String? _selectedDecisionMonth;
  String? _selectedMedium;
  String? _selectedRanking;
  String? _selectedPurchaseMode;

  final TextEditingController panController = TextEditingController();
  final TextEditingController gstController = TextEditingController();

  String? panError;
  String? gstError;

  @override
  void initState() {
    super.initState();
    futureData = initializePreferencesAndData();

    panController.addListener(() {
      setState(() {
        panError = null;
      });
    });

    gstController.addListener(() {
      setState(() {
        gstError = null;
      });
    });
  }

  Future<CustomerEntryMasterResponse> initializePreferencesAndData() async {
    final prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token') ?? '';
    String downHierarchy = prefs.getString('DownHierarchy') ?? '';
    return CustomerEntryMasterService()
        .fetchCustomerEntryMaster(downHierarchy, token);
  }

  @override
  void dispose() {
    panController.dispose();
    gstController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Customer - School'),
        backgroundColor: Color(0xFFFFF8E1),
      ),
      body: FutureBuilder<CustomerEntryMasterResponse>(
        future: futureData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            return buildForm(snapshot.data!);
          } else {
            return Center(child: Text('No data found'));
          }
        },
      ),
    );
  }

  Widget buildForm(CustomerEntryMasterResponse data) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildDropdownField(
            label: 'Start Class',
            value: _selectedStartClass,
            items: data.classesList.map((item) => item.className).toList(),
            onChanged: (value) => setState(() => _selectedStartClass = value),
          ),
          buildDropdownField(
            label: 'End Class',
            value: _selectedEndClass,
            items: data.classesList.map((item) => item.className).toList(),
            onChanged: (value) => setState(() => _selectedEndClass = value),
          ),
          buildDropdownField(
            label: 'Sampling Month',
            value: _selectedSamplingMonth,
            items: data.monthsList.map((item) => item.name).toList(),
            onChanged: (value) =>
                setState(() => _selectedSamplingMonth = value),
          ),
          buildDropdownField(
            label: 'Decision Month',
            value: _selectedDecisionMonth,
            items: data.monthsList.map((item) => item.name).toList(),
            onChanged: (value) =>
                setState(() => _selectedDecisionMonth = value),
          ),
          buildDropdownField(
            label: 'Medium',
            value: _selectedMedium,
            items: ['Medium 1', 'Medium 2'],
            // Replace with actual data if available
            onChanged: (value) => setState(() => _selectedMedium = value),
          ),
          buildDropdownField(
            label: 'Ranking',
            value: _selectedRanking,
            items: ['Rank 1', 'Rank 2'],
            // Replace with actual data if available
            onChanged: (value) => setState(() => _selectedRanking = value),
          ),
          buildTextField(
              controller: panController, label: 'PAN', errorText: panError),
          buildTextField(
              controller: gstController, label: 'GST', errorText: gstError),
          buildPurchaseModeField(data.purchaseModeList),
          SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  panError =
                      panController.text.isEmpty ? 'Please enter PAN' : null;
                  gstError =
                      gstController.text.isEmpty ? 'Please enter GST' : null;
                });
              },
              child: Text('Next'),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    String? errorText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget buildPurchaseModeField(List<PurchaseMode> purchaseModeList) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Purchase Mode:'),
          Column(
            children: purchaseModeList.map((mode) {
              return buildRadioOption(mode.modeName, mode.modeValue);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget buildRadioOption(String label, String value) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: _selectedPurchaseMode,
      onChanged: (newValue) {
        setState(() {
          _selectedPurchaseMode = newValue;
        });
      },
    );
  }
}
