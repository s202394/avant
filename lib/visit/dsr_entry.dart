import 'dart:convert';
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
import 'package:avant/visit/follow_up_action.dart';
import 'package:avant/visit/visit_series_search.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as img; // Image package for compression
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart'; // For temporary file storage
import 'package:shared_preferences/shared_preferences.dart';

import '../views/common_app_bar.dart';
import '../views/custom_text.dart';

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

  List<JoinVisit> _selectedJointVisitWithItems = [];

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
  bool _isFileUploaded = false;

  late Position position;
  late String address;
  late String? executiveName;

  late Future<GetVisitDsrResponse> _visitDsrData;

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _personMetController = TextEditingController();
  final TextEditingController _visitFeedbackController =
      TextEditingController();

  final _dateFieldKey = GlobalKey<FormFieldState>();
  final _visitFeedbackFieldKey = GlobalKey<FormFieldState>();

  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  late String _base64Image;
  late String fileNameResponse;
  late GetVisitDsrResponse visitDsrData;

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        // Get the file size
        final file = File(photo.path);
        final int fileSizeInBytes = await file.length();
        final double fileSizeInMB = fileSizeInBytes / (1024 * 1024);

        Uint8List imageBytes = await file.readAsBytes();

        if (kDebugMode) {
          print('Original file size: ${fileSizeInMB.toStringAsFixed(2)} MB.');
        }

        // If the file size is more than 2 MB, compress it
        if (fileSizeInMB > 2) {
          if (kDebugMode) {
            print('Compressing...');
          }

          // Decode the image using the image package
          img.Image? decodedImage = img.decodeImage(imageBytes);

          // Compress the image by resizing or adjusting JPEG quality
          if (decodedImage != null) {
            // Resize the image (optional), here it's being resized to 80% of the original
            img.Image resizedImage = img.copyResize(decodedImage,
                width: (decodedImage.width * 0.8).toInt());

            // Encode the resized image to JPEG with lower quality (adjust quality as needed)
            List<int> compressedImageBytes =
                img.encodeJpg(resizedImage, quality: 80);

            // Get the temporary directory to store the compressed image
            Directory tempDir = await getTemporaryDirectory();
            String tempPath = tempDir.path;
            File compressedFile = File('$tempPath/compressed_image.jpg');

            // Write the compressed bytes to the new file
            await compressedFile.writeAsBytes(compressedImageBytes);

            // Set the compressed file as the new image file
            setState(() {
              //Update the image file reference
              _imageFile = XFile(compressedFile.path);
              // Update base64 string
              _base64Image = base64Encode(compressedImageBytes);
            });

            if (kDebugMode) {
              print(
                  'Compressed file size: ${(compressedFile.lengthSync() / (1024 * 1024)).toStringAsFixed(2)} MB');
            }
            saveFile(visitDsrData);
          }
        } else {
          setState(() {
            // Set the original base64 string
            _imageFile = photo;
            _base64Image = base64Encode(imageBytes);
          });
          saveFile(visitDsrData);
        }
      }
    } catch (e) {
      // Handle error
      if (kDebugMode) {
        print('Error picking or compressing image: $e');
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
      appBar: const CommonAppBar(title: 'DSR Entry'),
      body: FutureBuilder<GetVisitDsrResponse>(
        future: _visitDsrData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: CustomText('No data available'));
          }

          visitDsrData = snapshot.data!;

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
                            CustomText(
                                visitDsrData.customerSummery.customerName,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                            RichTextWidget(
                                label: visitDsrData.customerSummery.address),
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
                            MultiSelectDropdown<JoinVisit>(
                              label: 'Joint Visit',
                              items: visitDsrData.joinVisitList,
                              selectedItems: _selectedJointVisitWithItems,
                              itemLabelBuilder: (item) => item.executiveName,
                              onChanged: _handleSelectionChange,
                              isMandatory: false,
                              isSubmitted: _submitted,
                            ),
                            buildDropdownField(
                              'Person Met',
                              selectedPersonMet,
                              {
                                for (var item in visitDsrData.personMetList)
                                  item.customerContactName:
                                      item.customerContactId
                              },
                              (value) {
                                setState(() {
                                  selectedPersonMet = value;
                                  selectedPersonMetId = value != null
                                      ? {
                                          for (var item
                                              in visitDsrData.personMetList)
                                            item.customerContactName:
                                                item.customerContactId
                                        }[value]
                                      : null;
                                });
                              },
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
                            const CustomText('Capture Image',
                                fontWeight: FontWeight.bold, fontSize: 14),
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
                            onTap: _isLoading
                                ? null
                                : () {
                                    setState(() {
                                      _submitted = true;
                                    });
                                    if (_formKey.currentState!.validate()) {
                                      _submitForm(visitDsrData);
                                    }
                                  },
                            child: Container(
                              width: double.infinity,
                              color: _isLoading ? Colors.grey : Colors.blue,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: 8.0, horizontal: 16),
                                child: CustomText('Submit',
                                    textAlign: TextAlign.center,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18),
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

  void _handleSelectionChange(List<JoinVisit> selectedItems) {
    setState(() {
      _selectedJointVisitWithItems = selectedItems;
    });
  }

  void _submitForm(GetVisitDsrResponse visitDsrData) async {
    if (_dateController.text.isEmpty) {
      toastMessage.showToastMessage('Please select Visit Date.');
    }
    if (selectedPersonMet == null) {
      toastMessage.showToastMessage('Please select Person Met.');
    } else if (samplingDone == null) {
      toastMessage.showToastMessage('Please select Sampling Done.');
    } else if (followUpAction == null) {
      toastMessage.showToastMessage('Please select Follow Up Action.');
    } else if (_imageFile == null) {
      toastMessage.showToastMessage('Please capture image first.');
    } else {
      nextAction(visitDsrData);
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
      {String initialValue = '',
      bool enabled = true,
      int maxLines = 1,
      double labelFontSize = 14.0,
      double textFontSize = 14.0}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: labelFontSize),
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
          alignLabelWithHint: true,
        ),
        initialValue: initialValue,
        enabled: enabled,
        maxLines: maxLines,
        style: TextStyle(fontSize: textFontSize),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  Widget buildDropdownField(
    String label,
    String? selectedValue,
    Map<String, int> items,
    ValueChanged<String?> onChanged, {
    double labelFontSize = 14.0,
    double textFontSize = 14.0,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: labelFontSize),
          border: const OutlineInputBorder(),
          errorText: _submitted && selectedValue == null
              ? 'Please select $label'
              : null,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isDense: true,
            value: selectedValue,
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: CustomText('Select'),
              ),
              ...items.keys.map(
                (key) => DropdownMenuItem<String>(
                  value: key,
                  child: CustomText(key, fontSize: textFontSize),
                ),
              ),
            ],
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  Widget buildRadioButtons(
    String label,
    bool? groupValue,
    ValueChanged<bool?> onChanged, {
    double labelFontSize = 14.0,
    double textFontSize = 14.0,
  }) {
    return Row(
      children: [
        Expanded(flex: 2, child: Text(label)),
        Expanded(
          flex: 1,
          child: Row(
            children: [
              Radio<bool>(
                  value: true, groupValue: groupValue, onChanged: onChanged),
              CustomText('Yes', fontSize: textFontSize),
            ],
          ),
        ),
        Expanded(
          flex: 1,
          child: Row(
            children: [
              Radio<bool>(
                  value: false, groupValue: groupValue, onChanged: onChanged),
              CustomText('No', fontSize: textFontSize),
            ],
          ),
        ),
      ],
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
                  side: const BorderSide(color: Colors.grey, width: 1),
                  // Border color and width
                  minimumSize: const Size(double.infinity, 250),
                  // Match parent width and height 300
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child:
                    const Icon(Icons.camera_alt, color: Colors.grey, size: 50),
              )
            : Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
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
    double labelFontSize = 14.0,
    double textFontSize = 14.0,
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
                    return Theme(data: ThemeData.light(), child: child!);
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
            style: TextStyle(fontSize: textFontSize),
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(fontSize: labelFontSize),
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
              suffixIcon: isDateField ? const Icon(Icons.calendar_month) : null,
            ),
            textAlign: TextAlign.start,
            maxLines: maxLines,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return (label == 'Visit Date')
                    ? 'Please select $label'
                    : 'Please enter $label';
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

  void saveFile(GetVisitDsrResponse visitDsrData) async {
    try {
      fileNameResponse = '';
      FocusScope.of(context).unfocus();

      if (!await _checkInternetConnection()) return;

      setState(() {
        _isLoading = true;
        _isFileUploaded = false;
      });

      int currentMilliseconds = DateTime.now().millisecondsSinceEpoch;
      String extension =
          path.extension(_imageFile?.name ?? '').replaceAll('.', '');
      final responseData = await SaveFileService().saveFile(
          _imageFile?.name ?? '$currentMilliseconds',
          extension,
          'visit',
          _base64Image,
          token ?? "");

      if (responseData.status == 'Success') {
        fileNameResponse = responseData.returnDetails.fileName;
        setState(() {
          _isFileUploaded = true;
        });
        if (kDebugMode) {
          print(fileNameResponse);
        }
        if (fileNameResponse.isNotEmpty) {
          if (kDebugMode) {
            print('Captured image save successfully.');
          }
        } else {
          setState(() {
            _isFileUploaded = false;
          });
          if (kDebugMode) {
            print('Captured image save error');
          }
          toastMessage.showToastMessage(
              "An error occurred while saving captured image.");
        }
      } else {
        setState(() {
          _isFileUploaded = false;
        });
        if (kDebugMode) {
          print('Captured image save Error ${responseData.message}');
        }
        toastMessage
            .showToastMessage("An error occurred while saving captured image.");
      }
    } catch (e) {
      setState(() {
        _isFileUploaded = false;
      });
      if (kDebugMode) {
        print("Error Captured image save: $e");
      }
    } finally {
      setState(() {
        _isLoading = false;
        _isFileUploaded = false;
      });
    }
  }

  void goToSamplingPage(GetVisitDsrResponse visitDsrData,
      String commaSeparatedIds, String fileName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VisitSeriesSearch(
          visitDsrData: visitDsrData,
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
          personMetId: selectedPersonMetId ?? 0,
          samplingDone: samplingDone ?? false,
          followUpAction: followUpAction ?? false,
          fileName: fileName,
        ),
      ),
    );
  }

  void goToFollowUpActionPage(GetVisitDsrResponse visitDsrData,
      String commaSeparatedIds, String fileName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FollowUpAction(
          visitDsrData: visitDsrData,
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
          personMetId: selectedPersonMetId ?? 0,
          samplingDone: samplingDone ?? false,
          followUpAction: followUpAction ?? false,
          fileName: fileName,
        ),
      ),
    );
  }

  void submit(String commaSeparatedIds, String fileName) async {
    if (followUpAction == false && samplingDone == false) {
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

        // Print the result
        if (kDebugMode) {
          print('Selected IDs: $commaSeparatedIds');
        }

        String uploadedDocumentXML =
            "<DocumentElement><UploadedDocument><DocumentName>$fileName</DocumentName><FileName>$fileName</FileName><FileSize>89135</FileSize></UploadedDocument></DocumentElement>";

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
                selectedPersonMetId ?? 0,
                commaSeparatedIds,
                uploadedDocumentXML,
                "",
                "",
                "",
                "",
                0,
                0,
                userId ?? 0,
                "",
                "",
                'No',
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
    }
  }

  void nextAction(GetVisitDsrResponse visitDsrData) {
    List<int> selectedIds =
        _selectedJointVisitWithItems.map((e) => e.executiveId).toList();

    // Convert list of IDs to comma-separated string
    String commaSeparatedIds = selectedIds.join(', ');
    if (followUpAction == false && samplingDone == false) {
      submit(commaSeparatedIds, fileNameResponse);
    } else if (samplingDone == true) {
      goToSamplingPage(visitDsrData, commaSeparatedIds, fileNameResponse);
    } else {
      goToFollowUpActionPage(visitDsrData, commaSeparatedIds, fileNameResponse);
    }
  }
}
