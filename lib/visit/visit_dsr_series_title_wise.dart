import 'package:flutter/material.dart';

class VisitDsrSeriesTitleWise extends StatefulWidget {
  final String schoolName;
  final String address;
  final String classLevel;
  final String series;
  final String title;

  const VisitDsrSeriesTitleWise({
    super.key,
    required this.schoolName,
    required this.address,
    required this.series,
    required this.classLevel,
    required this.title,
  });

  @override
  _VisitDsrSeriesTitleWise createState() => _VisitDsrSeriesTitleWise();
}

class _VisitDsrSeriesTitleWise extends State<VisitDsrSeriesTitleWise> {
  String? selectedSamplingType;
  String? selectedSampleGiven;
  String? selectedSampleTo;
  String? selectedShipTo;

  bool _submitted = false;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.amber[100],
          title: const Text('DSR Entry'),
        ),
        body: Form(
          key: _formKey, // Assign the form key
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ASN Sr. Secondary School (SCH654)',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Mayur Vihar Phase 1\nNew Delhi - 110001\nDelhi'),
                    SizedBox(height: 8),
                    Text('Visit Date: 24 Jun 2024',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Sampling Done: Yes',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Follow up Action: No',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Container(
                color: Colors.orange,
                child: TabBar(
                  labelColor: Colors.black,
                  indicatorColor: Colors.blue,
                  tabs: [
                    Tab(text: 'Series/ Title'),
                    Tab(text: 'Title wise'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildSeriesTitleTab(),
                    _buildTitleWiseTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeriesTitleTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Series Name: The English Circle',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: DropdownButtonFormField<String>(
                          // Set the initial value
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Sample To',
                            border: OutlineInputBorder(),
                            errorText: _submitted && selectedSampleTo == null
                                ? 'Please select Sample To'
                                : null,
                          ),
                          items: ['Mr. Sanjay Banerjee', 'Rajesh Ranjan']
                              .map((label) => DropdownMenuItem(
                                    value: label,
                                    child: Text(
                                      label,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedSampleTo = value;
                            });
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: DropdownButtonFormField<String>(
                          // Set the initial value
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Sampling Type',
                            border: OutlineInputBorder(),
                            errorText:
                                _submitted && selectedSamplingType == null
                                    ? 'Please select Sample Type'
                                    : null,
                          ),
                          items: ['Home Address', 'Office Address']
                              .map((label) => DropdownMenuItem(
                                    value: label,
                                    child: Text(
                                      label,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedSamplingType = value;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: DropdownButtonFormField<String>(
                          // Set the initial value
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Sample Given',
                            border: OutlineInputBorder(),
                            errorText: _submitted && selectedSampleGiven == null
                                ? 'Please select Sample Given'
                                : null,
                          ),
                          items: ['Given By Hand', 'By Air']
                              .map((label) => DropdownMenuItem(
                                    value: label,
                                    child: Text(
                                      label,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedSampleGiven = value;
                            });
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: DropdownButtonFormField<String>(
                          // Set the initial value
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Ship To',
                            border: OutlineInputBorder(),
                            errorText: _submitted && selectedShipTo == null
                                ? 'Please select Ship To'
                                : null,
                          ),
                          items: ['Official Address', 'Personal Address']
                              .map((label) => DropdownMenuItem(
                                    value: label,
                                    child: Text(
                                      label,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedShipTo = value;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: 5,
            itemBuilder: (context, index) {
              return BookListItem();
            },
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _submitted = true;
                });
                if (_formKey.currentState!.validate() &&
                    selectedSampleTo != null &&
                    selectedSampleGiven != null &&
                    selectedSamplingType != null &&
                    selectedShipTo != null) {
                  _submitForm();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart),
                  SizedBox(width: 8),
                  Text('Submit/ Next'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submitForm() {
    // Handle form submission logic here
    print('Form submitted!');
    // You can access form fields using their controllers or values stored in state variables
  }

  Widget _buildTitleWiseTab() {
    return Center(
      child: Text('Title wise content goes here'),
    );
  }
}

class BookListItem extends StatefulWidget {
  @override
  _BookListItemState createState() => _BookListItemState();
}

class _BookListItemState extends State<BookListItem> {
  int _quantity = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          child: ListTile(
            leading: Image.asset('images/book.png'),
            title: Text(
              'The English Circle 1\nRam Kumar\n9785675765767\nCourse Book\n₹ 280.00',
              textAlign: TextAlign.left,
            ),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /*Text('Stock Available: 5'),*/
                Container(
                  width: 120,
                  child: _quantity == 0
                      ? ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _quantity++;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: Text('Add'),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  if (_quantity > 0) {
                                    _quantity--;
                                  }
                                });
                              },
                              icon: Icon(Icons.remove),
                              color: Colors.red,
                            ),
                            Text('$_quantity'),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  if (_quantity < 10) {
                                    _quantity++;
                                  }
                                });
                              },
                              icon: Icon(Icons.add),
                              color: Colors.red,
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
        Divider(),
      ],
    );
  }
}
