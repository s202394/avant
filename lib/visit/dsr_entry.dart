import 'dart:io';

import 'package:avant/api/api_service.dart';
import 'package:avant/common/common.dart';
import 'package:avant/common/toast.dart';
import 'package:avant/home.dart';
import 'package:avant/model/get_visit_dsr_model.dart';
import 'package:avant/model/login_model.dart';
import 'package:avant/service/location_service.dart';
import 'package:avant/views/multi_selection_dropdown.dart';
import 'package:avant/views/rich_text.dart';
import 'package:avant/visit/visit_series_search.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DsrEntry extends StatefulWidget {
  final int customerId;
  final String customerName;
  final String customerCode;
  final String customerType;
  final String address;
  final String city;
  final String state;

  const DsrEntry(
      {super.key,
      required this.customerId,
      required this.customerName,
      required this.customerCode,
      required this.customerType,
      required this.address,
      required this.city,
      required this.state});

  @override
  DsrEntryPageState createState() => DsrEntryPageState();
}

class DsrEntryPageState extends State<DsrEntry> {
  String? selectedVisitPurpose;
  int? selectedVisitPurposeId;
  String? selectedJointVisit;
  int? selectedJointVisitId;
  String? selectedPersonMet;
  int? selectedPersonMetId;
  bool? samplingDone;
  bool? followUpAction;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  List<PersonMet> _selectedJointVisitWithItems = [];

  String fetchedAddress = '';

  int? executiveId;
  int? userId;
  String? profileCode;
  String? upHierarchy;
  String? downHierarchy;
  String? token;

  ToastMessage toastMessage = ToastMessage();
  LocationService locationService = LocationService();

  bool _submitted = false;
  bool _isLoading = false;

  late Position position;
  late String address;
  late String? executiveName;

  late Future<GetVisitDsrResponse> _visitDsrData;

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _visitPurposeController = TextEditingController();
  final TextEditingController _jointVisitController = TextEditingController();
  final TextEditingController _personMetController = TextEditingController();
  final TextEditingController _visitFeedbackController =
      TextEditingController();

  final _dateFieldKey = GlobalKey<FormFieldState>();
  final _visitFeedbackFieldKey = GlobalKey<FormFieldState>();

  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      setState(() {
        _imageFile = photo;
      });
    } catch (e) {
      // Handle error
      if (kDebugMode) {
        print('Error picking image: $e');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _visitDsrData = _fetchVisitDsrData();

    getAddressData();
  }

  Future<GetVisitDsrResponse> _fetchVisitDsrData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token') ?? '';
    executiveId = await getExecutiveId();
    userId = await getUserId();
    profileCode = await getProfileCode();
    executiveName = await getExecutiveName();
    upHierarchy = prefs.getString('UpHierarchy') ?? '';
    downHierarchy = prefs.getString('DownHierarchy') ?? '';

    return await GetVisitDsrService().getVisitDsr(
      executiveId ?? 0,
      widget.customerId,
      widget.customerType,
      upHierarchy ?? '',
      downHierarchy ?? '',
      token ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DSR Entry'),
        backgroundColor: const Color(0xFFFFF8E1),
      ),
      body: FutureBuilder<GetVisitDsrResponse>(
        future: _visitDsrData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No data available'));
          }

          final visitDsrData = snapshot.data!;

          // Set the fetched address here
          fetchedAddress = visitDsrData.customerSummery.address;

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
                            Text(
                              visitDsrData.customerSummery.customerName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            RichTextWidget(
                              label: visitDsrData.customerSummery.address,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                                'Visit Date', _dateController, _dateFieldKey),
                            buildTextField('Visit By',
                                initialValue: executiveName ?? '',
                                enabled: false),
                            buildDropdownField(
                              'Visit Purpose',
                              selectedVisitPurpose,
                              {
                                for (var item in visitDsrData.visitPurposeList)
                                  item.visitPurpose: item.id
                              },
                              (value) {
                                setState(() {
                                  selectedVisitPurpose = value;
                                  selectedVisitPurposeId = value != null
                                      ? {
                                          for (var item
                                              in visitDsrData.visitPurposeList)
                                            item.visitPurpose: item.id
                                        }[value]
                                      : null;
                                });
                              },
                            ),
                            /* buildDropdownField(
                          'Joint Visit',
                          selectedJointVisit,
                          {
                            for (var item in visitDsrData.joinVisitList)
                              item.executiveName: item.executiveId
                          },
                          (value) {
                            setState(() {
                              selectedJointVisit = value;
                              selectedJointVisitId = value != null
                                  ? {
                                      for (var item
                                          in visitDsrData.joinVisitList)
                                        item.executiveName: item.executiveId
                                    }[value]
                                  : null;
                            });
                          },
                        ),*/
                            MultiSelectDropdown<PersonMet>(
                              label: 'Joint Visit',
                              items: visitDsrData.personMetList,
                              selectedItems: _selectedJointVisitWithItems,
                              itemLabelBuilder: (item) =>
                                  item.customerContactName,
                              onChanged: _handleSelectionChange,
                              isSubmitted: _submitted,
                            ),
                            buildRadioButtons('Sampling Done', samplingDone,
                                (value) {
                              setState(() {
                                samplingDone = value;
                              });
                            }),
                            buildRadioButtons(
                                'Follow Up Action', followUpAction, (value) {
                              setState(() {
                                followUpAction = value;
                              });
                            }),
                            const Text(
                              'Capture Image',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            buildCaptureImage(),
                            _buildTextField(
                                'Visit Feedback',
                                _visitFeedbackController,
                                _visitFeedbackFieldKey,
                                maxLines: 3),
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
                    ),
                  ],
                ),
              ),
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                ),
            ],
          );
        },
      ),
    );
  }

  void _handleSelectionChange(List<PersonMet> selectedItems) {
    setState(() {
      _selectedJointVisitWithItems = selectedItems;
    });
  }

  void _submitForm() async {
    if (samplingDone == null) {
      toastMessage.showToastMessage('Please select Sampling Done.');
    } else if (followUpAction == null) {
      toastMessage.showToastMessage('Please select Follow Up Action.');
    }
    /*else if (_imageFile == null) {
    toastMessage.showToastMessage('Please capture image first.');
  }*/
    else if (followUpAction == false && samplingDone == false) {
      try {
        FocusScope.of(context).unfocus();

        if (!await _checkInternetConnection()) return;

        setState(() {
          _isLoading = true;
        });

        if (address.isEmpty) {
          address = await locationService.getAddress(
              position.latitude, position.longitude);
        }

        // Assuming _selectedItems is a list of PersonMet objects
        List<int> selectedIds = _selectedJointVisitWithItems
            .map((e) => e.customerContactId)
            .toList();

        // Convert list of IDs to comma-separated string
        String commaSeparatedIds = selectedIds.join(', ');

        // Print the result
        if (kDebugMode) {
          print('Selected IDs: $commaSeparatedIds');
        }

        if (address.isNotEmpty) {
          try {
            if (kDebugMode) {
              print("_submitForm clicked");
            }
            final responseData = await VisitEntryService().visitEntry(
                executiveId ?? 0,
                widget.customerType,
                widget.customerId,
                executiveId ?? 0,
                address,
                profileCode ?? '',
                position.latitude,
                position.longitude,
                1,
                _visitFeedbackController.text,
                _dateController.text,
                selectedVisitPurposeId ?? 0,
                0,
                commaSeparatedIds,
                "",
                "",
                "",
                "",
                "",
                0,
                0,
                userId ?? 0,
                "",
                "",
                false,
                "",
                "",
                false,
                "",
                "",
                token ?? "");

            if (responseData.status == 'Success') {
              String s = responseData.s;
              if (kDebugMode) {
                print(s);
              }
              if (s.isNotEmpty) {
                if (kDebugMode) {
                  print('Add Visit DSR Error s not empty');
                }
                toastMessage.showInfoToastMessage(s);
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const HomePage()),
                    (Route<dynamic> route) => false,
                  );
                }
              } else if (responseData.e.isNotEmpty) {
                if (kDebugMode) {
                  print('Add Visit DSR Error e not empty');
                }
                toastMessage.showToastMessage(responseData.e);
              } else {
                if (kDebugMode) {
                  print('Add Visit DSR Error s & e empty');
                }
                toastMessage
                    .showToastMessage("An error occurred while adding visit.");
              }
            } else {
              if (kDebugMode) {
                print('Add Visit DSR Error ${responseData.status}');
              }
              toastMessage
                  .showToastMessage("An error occurred while adding visit.");
            }
          } catch (e) {
            if (kDebugMode) {
              print("Error fetching location: $e");
            }
          }
        } else {
          if (kDebugMode) {
            print('Address empty');
          }
          toastMessage.showToastMessage("Unable to fetch address.");
        }
      } catch (e) {
        if (kDebugMode) {
          print('Add Visit DSR Error $e');
        }
        toastMessage.showToastMessage("An error occurred while adding visit.");
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      // Assuming _selectedItems is a list of PersonMet objects
      List<int> selectedIds =
          _selectedJointVisitWithItems.map((e) => e.customerContactId).toList();

      // Convert list of IDs to comma-separated string
      String commaSeparatedIds = selectedIds.join(', ');

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VisitSeriesSearch(
            customerId: widget.customerId,
            customerName: widget.customerName,
            customerCode: widget.customerCode,
            customerType: widget.customerType,
            address: fetchedAddress,
            city: widget.city,
            state: widget.state,
            visitFeedback: _visitFeedbackController.text,
            visitDate: _dateController.text,
            visitPurposeId: selectedVisitPurposeId ?? 0,
            jointVisitWithIds: commaSeparatedIds,
            samplingDone: samplingDone ?? false,
            followUpAction: followUpAction ?? false,
          ),
        ),
      );
    }
  }

  Future<bool> _checkInternetConnection() async {
    if (!await checkInternetConnection()) {
      toastMessage.showToastMessage(
          "No internet connection. Please check your connection and try again.");
      return false;
    }
    return true;
  }

  Widget buildTextField(String label,
      {String initialValue = '', bool enabled = true, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
          alignLabelWithHint: true,
        ),
        initialValue: initialValue,
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

  Widget buildDropdownField(String label, String? selectedValue,
      Map<String, int> items, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          errorText: _submitted && selectedValue == null
              ? 'Please select a $label'
              : null,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isDense: true,
            value: selectedValue,
            items: items.keys.map((key) {
              return DropdownMenuItem<String>(
                value: key,
                child: Text(key),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  Widget buildRadioButtons(
      String label, bool? groupValue, ValueChanged<bool?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label)),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Radio<bool>(
                  value: true,
                  groupValue: groupValue,
                  onChanged: onChanged,
                ),
                const Text('Yes'),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Radio<bool>(
                  value: false,
                  groupValue: groupValue,
                  onChanged: onChanged,
                ),
                const Text('No'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _removePhoto() {
    setState(() {
      _imageFile = null;
    });
  }

  Widget buildCaptureImage() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Center(
        child: _imageFile == null
            ? OutlinedButton(
                onPressed: _takePhoto,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.grey, width: 2),
                  // Border color and width
                  minimumSize: const Size(double.infinity, 300),
                  // Match parent width and height 300
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12.0), // Rounded corners
                  ),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.grey, // Icon color
                  size: 50, // Size of the camera icon
                ),
              )
            : Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(12.0), // Rounded corners
                      image: DecorationImage(
                        image: FileImage(File(_imageFile!.path)),
                        // Convert XFile to File
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: IconButton(
                      icon:
                          const Icon(Icons.close, color: Colors.red, size: 30),
                      onPressed: _removePhoto,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    GlobalKey<FormFieldState> fieldKey, {
    int maxLines = 1,
  }) {
    bool isDateField = label == "Visit Date";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: isDateField
            ? () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1970, 1, 1),
                  lastDate: DateTime.now(),
                  builder: (BuildContext context, Widget? child) {
                    return Theme(
                      data: ThemeData.light(),
                      child: child!,
                    );
                  },
                );

                if (picked != null) {
                  controller.text = DateFormat('dd MMM yyyy').format(picked);
                  fieldKey.currentState?.validate();
                }
              }
            : null,
        child: IgnorePointer(
          ignoring: isDateField,
          child: TextFormField(
            key: fieldKey,
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
              suffixIcon: isDateField ? const Icon(Icons.calendar_month) : null,
            ),
            textAlign: TextAlign.start,
            maxLines: maxLines,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select $label';
              }
              return null;
            },
            onChanged: (value) {
              if (value.isNotEmpty) {
                fieldKey.currentState?.validate();
              }
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    _visitPurposeController.dispose();
    _jointVisitController.dispose();
    _personMetController.dispose();
    _visitFeedbackController.dispose();
    super.dispose();
  }

  void getAddressData() async {
    position = await locationService.getCurrentLocation();
    if (kDebugMode) {
      print("Latitude: ${position.latitude}, Longitude: ${position.longitude}");
    }

    address = await locationService.getAddressFromLocation();
    if (kDebugMode) {
      print("address: $address");
    }
  }
}
