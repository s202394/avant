import 'package:avant/api/api_service.dart';
import 'package:avant/common/toast.dart';
import 'package:avant/views/rich_text.dart';
import 'package:avant/visit/self_stock_request_search.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/login_model.dart';
import '../model/self_stock_request_response.dart';
import '../model/self_stock_request_trade_response.dart';

class SelfStockEntry extends StatefulWidget {
  const SelfStockEntry({super.key});

  @override
  SelfStockEntryPageState createState() => SelfStockEntryPageState();
}

class SelfStockEntryPageState extends State<SelfStockEntry> {
  // Dropdown Selections
  String? selectedShipmentMode;
  int? selectedShipmentModeId;
  String? selectedShipTo;
  String? selectedDeliveryTrade;
  int? selectedDeliveryTradeId;

  // Form Keys
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Data Variables
  int? executiveId;
  String? token;
  ShipmentAddress? address;
  ShipmentResponse? shipmentResponse;
  late Future<SelfStockRequestResponse> _selfStockRequestData;

  // Controllers
  final TextEditingController _executiveNameController =
      TextEditingController();
  final TextEditingController _shippingInstructionsController =
      TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  // UI State
  bool _submitted = false;
  bool _isLoadingShipment = false;

  ToastMessage message = ToastMessage();

  @override
  void initState() {
    super.initState();
    _selfStockRequestData = _fetchSelfStockData();
  }

  Future<SelfStockRequestResponse> _fetchSelfStockData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
    executiveId = await getExecutiveId();
    _executiveNameController.text = await getExecutiveName() ?? '';
    return await SelfStockRequestService().getSelfStockRequest(token ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Self Stock Sample Request'),
        backgroundColor: const Color(0xFFFFF8E1),
      ),
      body: FutureBuilder<SelfStockRequestResponse>(
        future: _selfStockRequestData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No data available'));
          }

          final response = snapshot.data!;
          return _buildForm(response);
        },
      ),
    );
  }

  // Builds the main form UI
  Widget _buildForm(SelfStockRequestResponse response) {
    final shipToItems = response.shipTo.map((value) {
      return DropdownMenuItem<String>(
        value: value.shipTo,
        child: Text(value.shipTo),
      );
    }).toList();

    return Stack(
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView(
                    children: [
                      _buildTextField(
                          'Executive Name', _executiveNameController,
                          enabled: false),
                      _buildDropdownField(
                        'Shipment Mode',
                        selectedShipmentMode,
                        {
                          for (var item in response.shipmentMode)
                            item.shipmentMode: item.shipmentModeId
                        },
                        (value) => _onShipmentModeChanged(value, response),
                      ),
                      const SizedBox(height: 8),
                      _buildShipToDropdown(shipToItems),
                      if (selectedShipTo != null &&
                          selectedShipTo != 'Transport Office')
                        _buildAddressSection(),
                      const SizedBox(height: 8),
                      _buildTextField('Shipping Instructions',
                          _shippingInstructionsController,
                          maxLines: 3),
                      _buildTextField('Remarks', _remarksController,
                          maxLines: 3),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              _buildSubmitButton(),
            ],
          ),
        ),
        if (_isLoadingShipment)
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }

// Builds a TextField with validation
  Widget _buildTextField(String label, TextEditingController controller,
      {int maxLines = 1, bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          alignLabelWithHint: true,
          contentPadding:
          const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
        ),
      ),
    );
  }

  // Builds a Dropdown Field with validation
  Widget _buildDropdownField(String label, String? selectedValue,
      Map<String, int> items, void Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        value: selectedValue,
        items: items.keys.map((key) {
          return DropdownMenuItem<String>(
            value: key,
            child: Text(key),
          );
        }).toList(),
        onChanged: onChanged,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select $label';
          }
          return null;
        },
      ),
    );
  }

  // Builds the 'Ship To' dropdown with validation
  Widget _buildShipToDropdown(List<DropdownMenuItem<String>> shipToItems) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Ship To',
        border: OutlineInputBorder(),
      ),
      value: selectedShipTo,
      items: shipToItems,
      onChanged: (value) {
        setState(() {
          if (value != null && value.isNotEmpty) {
            _formKey.currentState!.validate();
          }
          selectedShipTo = value;
          selectedDeliveryTrade = null;
          shipmentResponse = null;
          address = null;
          if (selectedShipTo != 'Transport Office') {
            getShipmentData(selectedShipTo!);
          }
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select Ship To';
        }
        return null;
      },
    );
  }

  // Builds the Address Section (for Trade and Non-Trade cases)
  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selectedShipTo == 'Trade') _buildTradeAddressDropdown(),
        _buildAddressText(),
      ],
    );
  }

  // Builds the 'Delivery Trade' dropdown if 'Trade' is selected
  Widget _buildTradeAddressDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Delivery Trade',
            border: const OutlineInputBorder(),
            errorText: _submitted && selectedDeliveryTrade == null
                ? 'Please select Delivery Trade'
                : null,
          ),
          items: shipmentResponse?.shipmentAddress
              .whereType<TradeShipmentAddress>()
              .map((trade) {
            return DropdownMenuItem<String>(
              value: trade.customerName,
              child: Text(trade.customerName),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedDeliveryTrade = value;
              address = shipmentResponse?.shipmentAddress
                  .whereType<TradeShipmentAddress>()
                  .firstWhere(
                    (trade) => trade.customerName == value,
                    orElse: () => TradeShipmentAddress(
                      customerId: 0,
                      customerName: '',
                      customerType: '',
                      customerCity: '',
                      customerAddress: '',
                      shippingAddress: '',
                    ),
                  );
            });
          },
        ),
      ],
    );
  }

// Builds the Address Text for display
  Widget _buildAddressText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (((selectedShipTo == 'Residence Address' ||
                    selectedShipTo == 'By Hand') &&
                address != null) ||
            (selectedShipTo == 'Trade' && selectedDeliveryTrade != null))
          const Column(
            children: [
              SizedBox(height: 8),
              Text(
                'Delivery Address',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              SizedBox(height: 8),
            ],
          ),
        // Case for Trade Shipment Address
        if (selectedShipTo == 'Trade' &&
            selectedDeliveryTrade != null &&
            address is TradeShipmentAddress)
          RichTextWidget(
            label: (address as TradeShipmentAddress).shippingAddress,
          ),

        // Case for Residence Address or By Hand
        if (selectedShipTo == 'Residence Address' ||
            selectedShipTo == 'By Hand')
          Text(
            address != null && address is Address
                ? (address as Address).shippingAddress1
                : '', // Address placeholder
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
      ],
    );
  }

  // Builds the Submit Button
  Widget _buildSubmitButton() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _submitted = true; // Set submitted to true to trigger validation
              });
              if (_formKey.currentState!.validate()) {
                // Only proceed if the form is valid and required fields are filled
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SelfStockRequestSearch(
                      type: 'Self Stock Sample Request',
                      title: 'Self Stock Sample Request',
                      customerName: _executiveNameController.text,
                      shipmentModeId: selectedShipmentModeId ?? 0,
                      shipToId: selectedShipTo ?? '',
                      deliveryTradeId: selectedDeliveryTradeId ?? 0,
                      shippingInstructions: _shippingInstructionsController.text,
                      remarks: _remarksController.text,
                      address: getSelectedAddress(),
                    ),
                  ),
                );
              }
            },
            child: Container(
              width: double.infinity,
              color: Colors.blue,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                child: Text(
                  'Submit',
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
    );
  }

  // Handles Shipment Mode Change
  void _onShipmentModeChanged(
      String? value, SelfStockRequestResponse response) {
    if (value != null && value.isNotEmpty) {
      _formKey.currentState!.validate();
    }
    setState(() {
      selectedShipmentMode = value;
      selectedShipmentModeId = response.shipmentMode
          .firstWhere((item) => item.shipmentMode == value)
          .shipmentModeId;
    });
  }

  // Fetches the selected address to pass to the next screen
  String getSelectedAddress() {
    if (selectedShipTo == 'Trade' && address is TradeShipmentAddress) {
      return (address as TradeShipmentAddress).shippingAddress;
    } else if (address is Address) {
      return (address as Address).shippingAddress1;
    }
    return 'No address selected';
  }

  // Fetches shipment data based on the selected 'Ship To' option
  void getShipmentData(String shipTo) async {
    setState(() {
      _isLoadingShipment = true;
    });

    try {
      final data = await SelfStockRequestService()
          .fetchShipmentData(executiveId ?? 0, '', shipTo, token ?? '');

      // Set the address based on the fetched data
      setState(() {
        shipmentResponse = data;

        // Set the address based on the type of shipment address
        if (shipTo == 'Trade' &&
            shipmentResponse?.shipmentAddress.isNotEmpty == true) {
          address = shipmentResponse!.shipmentAddress
              .whereType<TradeShipmentAddress>()
              .first;
        } else if (shipTo != 'Trade' &&
            shipmentResponse?.shipmentAddress.isNotEmpty == true) {
          address =
              shipmentResponse!.shipmentAddress.whereType<Address>().first;
        }

        _isLoadingShipment = false;
      });
    } catch (error) {
      setState(() {
        _isLoadingShipment = false;
      });
      ToastMessage().showToastMessage('Failed to fetch shipment data.');
    }
  }
}
