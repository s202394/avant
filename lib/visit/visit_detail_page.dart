import 'dart:io' show Platform;
import 'dart:io';

import 'package:avant/api/api_service.dart';
import 'package:avant/model/visit_details_model.dart';
import 'package:avant/views/label_text.dart';
import 'package:avant/visit/dsr_entry.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../views/common_app_bar.dart';
import '../views/custom_text.dart';

class VisitDetailsPage extends StatefulWidget {
  final int customerId;
  final int visitId;
  final bool isTodayPlan;

  const VisitDetailsPage({
    super.key,
    required this.customerId,
    required this.visitId,
    required this.isTodayPlan,
  });

  @override
  VisitDetailsPageState createState() => VisitDetailsPageState();
}

class VisitDetailsPageState extends State<VisitDetailsPage> {
  late Future<VisitDetailsResponse> futureVisitDetails;
  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    futureVisitDetails = _initializeAndFetchVisitDetails();
  }

  Future<VisitDetailsResponse> _initializeAndFetchVisitDetails() async {
    prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    return VisitDetailsService()
        .visitDetails(widget.customerId, widget.visitId, token ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: 'Last Visit Details'),
      body: FutureBuilder<VisitDetailsResponse>(
        future: futureVisitDetails,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          } else if (!snapshot.hasData ||
              snapshot.data == null ||
              snapshot.data!.isEmpty()) {
            return const Center(child: CustomText("No Data Found"));
          } else {
            return buildVisitDetails(snapshot.data!);
          }
        },
      ),
    );
  }

  Widget buildVisitDetails(VisitDetailsResponse data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: CustomText(
              data.customerDetails?.customerName ?? '',
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            subtitle: CustomText(
                data.customerDetails?.address.replaceAll('<br>', '\n') ?? '',
                fontSize: 14.0,
                color: Colors.black,
                textAlign: TextAlign.left),
            trailing: Visibility(
              visible: widget.isTodayPlan,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DsrEntry(
                        customerId: data.customerDetails?.customerId ?? 0,
                        customerName: data.customerDetails?.customerName ?? '',
                        customerCode: '',
                        customerType: data.visitDetails?.customerType ?? '',
                        address: data.customerDetails?.address ?? '',
                        city: '',
                        state: '',
                      ),
                    ),
                  );
                },
                child: Image.asset('images/travel.png', height: 30, width: 30),
              ),
            ),
          ),
          const Divider(),
          const SizedBox(height: 12.0),
          LabeledText(label: 'Visit Date', value: data.visitDetails?.visitDate),
          LabeledText(
              label: 'Visit By', value: data.visitDetails?.executiveName),
          LabeledText(
              label: 'Visit Purpose', value: data.visitDetails?.visitPurpose),
          LabeledText(
              label: 'Joint Visit', value: data.visitDetails?.jointVisitWith),
          LabeledText(label: 'Person Met', value: data.visitDetails?.personMet),
          Visibility(
            visible: data.promotionalDetails != null &&
                data.promotionalDetails!.isNotEmpty,
            child: Column(
              children: [
                const SizedBox(height: 16.0),
                const CustomText('Sampling Done:',
                    fontWeight: FontWeight.bold, fontSize: 14),
                for (var sample in data.promotionalDetails ?? [])
                  CustomText(
                      '${sample.title} - ${sample.samplingType} (${sample.isbn}) Qty: ${sample.requestedQty}',
                      fontSize: 14),
              ],
            ),
          ),
          Visibility(
            visible: (data.uploadedDocuments?.length ?? 0) > 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16.0),
                const CustomText('Uploaded Documents',
                    fontWeight: FontWeight.bold, fontSize: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: data.uploadedDocuments?.length,
                  itemBuilder: (context, index) {
                    final uploadedDocument = data.uploadedDocuments?[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 1.0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        leading: Text('${uploadedDocument?.sNo}'),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText("${uploadedDocument?.documentName}",
                                fontSize: 14),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.save_alt, color: Colors.blue),
                          onPressed: () {
                            if (uploadedDocument?.uploadedFile != null) {
                              String imageUrl = uploadedDocument!.action;
                              //saveImageToGallery(imageUrl, context);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12.0),
          const CustomText('Visit Feedback:',
              fontWeight: FontWeight.bold, fontSize: 14),
          CustomText(data.visitDetails?.visitFeedback ?? '', fontSize: 12),
        ],
      ),
    );
  }

  Future<void> saveImageToGallery(String url, BuildContext context) async {
    // Create an instance of the DeviceInfoPlugin to check SDK version
    final deviceInfoPlugin = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;

    PermissionStatus status;

    // Check if the device is Android 13 or above
    if (Platform.isAndroid && androidInfo.version.sdkInt >= 33) {
      status = await Permission.photos
          .request(); // Placeholder (may require update later)
    } else {
      // Request storage permission for devices below Android 13
      status = await Permission.storage.request();
    }

    if (status.isGranted) {
      try {
        // Fetch the image from the given URL
        var response = await Dio()
            .get(url, options: Options(responseType: ResponseType.bytes));
        /*final result = await ImageGallerySaver.saveImage(
            Uint8List.fromList(response.data),
            quality: 60,
            name: "downloaded_image");

        if (result['isSuccess']) {
          if (kDebugMode) {
            print('Image saved to gallery');
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image saved successfully to gallery!')),
          );
        } else {
          throw Exception('Failed to save image to gallery.');
        }*/
      } catch (e) {
        if (kDebugMode) {
          print('Error saving image: $e');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving image: $e')),
        );
      }
    } else if (status.isPermanentlyDenied) {
      // If the permission is permanently denied, guide the user to the app settings
      openAppSettings();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enable storage permission in settings.')),
      );
    } else {
      // Handle permission denied
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage permission denied.')),
      );
    }
  }
}
