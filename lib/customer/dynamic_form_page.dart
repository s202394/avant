import 'package:avant/views/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:multi_select_flutter/dialog/mult_select_dialog.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';

import '../model/customer_entry_master_model.dart';
import 'dynamic_dropdown_cell.dart';

class DynamicFormWidget extends StatefulWidget {
  final Function(List<FormRowData>) onSubmit;
  final List<Subject> subjectList;
  final List<Classes> classesList;
  final List<FormRowData> initialRows;

  const DynamicFormWidget({
    super.key,
    required this.subjectList,
    required this.classesList,
    required this.onSubmit,
    this.initialRows = const [],
  });

  @override
  DynamicFormWidgetState createState() => DynamicFormWidgetState();
}

class DynamicFormWidgetState extends State<DynamicFormWidget> {
  final List<Map<int, String>> decisionMakerList = [
    {1: 'Yes'},
    {0: 'No'}
  ];
  late List<FormRowData> rows;

  DynamicFormWidgetState() : rows = [];

  @override
  void initState() {
    super.initState();

    rows = widget.initialRows.isNotEmpty ? widget.initialRows : [FormRowData()];
    debugPrint('rows :${rows.length}');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // You can also check if data has already arrived here before updating
    if (widget.initialRows.isNotEmpty && rows != widget.initialRows) {
      setState(() {
        rows = widget.initialRows;
      });
    }
  }

    void updateRows(List<FormRowData> newRows) {
      setState(() {
        rows = newRows;
      });
      debugPrint('Updated rows: ${rows.length}');
    }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Table Header
        Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          border: TableBorder.all(color: Colors.grey),
          columnWidths: const {
            0: FixedColumnWidth(50),
            1: FlexColumnWidth(),
            2: FlexColumnWidth(),
            3: FlexColumnWidth(),
            4: FixedColumnWidth(50),
          },
          children: [
            TableRow(
                decoration: BoxDecoration(color: Colors.amber.shade200),
                children: [
                  tableHeaderCell("S.NO"),
                  tableHeaderCell("SUBJECT NAME"),
                  tableHeaderCell("CLASS NAME"),
                  tableHeaderCell("DECISION MAKER"),
                  tableHeaderCell("ACTION"),
                ]),
          ],
        ),
        // Dynamic Rows
        SizedBox(
          child: ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: rows.length,
            itemBuilder: (context, index) {
              return buildFormRow(index);
            },
          ),
        ),
      ],
    );
  }

  Widget tableHeaderCell(String label) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: CustomText(label, fontSize: 12),
    );
  }

  Widget buildFormRow(int index) {
    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: TableBorder.all(color: Colors.grey),
      columnWidths: const {
        0: FixedColumnWidth(50),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(2),
        4: FixedColumnWidth(50),
      },
      children: [
        TableRow(children: [
          tableCell((index + 1).toString()), // Row number
          DynamicDropdownCell<int>(
            value: rows[index].subjectId,
            hint: "--Select--",
            items: widget.subjectList
                .map((subject) => {subject.subjectId: subject.subjectName})
                .toList(),
            onChanged: (value) {
              setState(() {
                rows[index].subjectId = value;
              });
              widget.onSubmit(rows);
            },
          ),
          buildClassDropdown(index),
          DynamicDropdownCell<int>(
            value: rows[index].decisionMaker != null
                ? (rows[index].decisionMaker == 'Yes' ? 1 : 0)
                : null,
            hint: "--Select--",
            items: decisionMakerList,
            onChanged: (value) {
              setState(() {
                rows[index].decisionMaker = value == 1 ? 'Yes' : 'No';
              });
              widget.onSubmit(rows);
            },
          ),
          actionCell(index), // Action Add/Remove button
        ]),
      ],
    );
  }

  Widget buildClassDropdown(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: InkWell(
        onTap: () async {
          final selectedClasses = await showDialog<List<Classes>>(
            context: context,
            builder: (context) {
              return MultiSelectDialog<Classes>(
                items: widget.classesList
                    .map((cls) => MultiSelectItem(cls, cls.className))
                    .toList(),
                initialValue: rows[index].selectedClasses ?? [],
                title: const Text("Select Classes"),
                selectedColor: Colors.blue,
                searchable: true,
              );
            },
          );
          if (selectedClasses != null) {
            setState(() {
              rows[index].selectedClasses = selectedClasses;
            });
            widget.onSubmit(rows);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  rows[index].selectedClasses != null &&
                          rows[index].selectedClasses!.isNotEmpty
                      ? rows[index]
                          .selectedClasses!
                          .map((cls) => cls.className)
                          .join(", ")
                      : "--Select--",
                  style: const TextStyle(fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.black54),
            ],
          ),
        ),
      ),
    );
  }

  Widget tableCell(String content) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8.0),
      child: CustomText(content, fontSize: 10),
    );
  }

  Widget actionCell(int index) {
    return IconButton(
      icon: Icon(
        index == rows.length - 1 ? Icons.add : Icons.remove,
        color: index == rows.length - 1 ? Colors.green : Colors.red,
      ),
      onPressed: () {
        setState(() {
          if (index == rows.length - 1) {
            rows.add(FormRowData());
          } else {
            rows.removeAt(index);
          }
        });
      },
    );
  }
}

class FormRowData {
  int? subjectId;
  List<Classes>? selectedClasses;
  String? decisionMaker;

  FormRowData({this.subjectId, this.selectedClasses, this.decisionMaker});
}
