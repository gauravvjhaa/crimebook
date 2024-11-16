// custom_dropdown.dart

import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class CustomDropdown extends StatefulWidget {
  final List<String> items;
  final String? selectedValue;
  final String hint;
  final void Function(String?) onChanged;
  final bool isSearchable;
  final double? dropdownMaxHeight;
  final double? dropdownWidth;
  final double? buttonHeight;
  final double? buttonWidth;
  final EdgeInsetsGeometry? buttonPadding;
  final BoxDecoration? buttonDecoration;
  final IconData? icon;
  final Color? iconEnabledColor;
  final Color? iconDisabledColor;
  final double? iconSize;

  const CustomDropdown({
    Key? key,
    required this.items,
    this.selectedValue,
    required this.hint,
    required this.onChanged,
    this.isSearchable = false,
    this.dropdownMaxHeight,
    this.dropdownWidth,
    this.buttonHeight,
    this.buttonWidth,
    this.buttonPadding,
    this.buttonDecoration,
    this.icon,
    this.iconEnabledColor,
    this.iconDisabledColor,
    this.iconSize,
  }) : super(key: key);

  @override
  _CustomDropdownState createState() => _CustomDropdownState();
}

class _CustomDropdownState extends State<CustomDropdown> {
  late List<String> _items;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _items = widget.items;
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _items = widget.items
          .where((item) => item.toLowerCase().contains(_searchController.text.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    var brightness = MediaQuery.of(context).platformBrightness;
    bool isDarkMode = brightness == Brightness.dark;

    // Ensure the selected value is in the current list of items
    String? dropdownValue = _items.contains(widget.selectedValue) ? widget.selectedValue : null;

    return DropdownButtonHideUnderline(
      child: DropdownButton2<String>(
        isExpanded: true,
        hint: Text(
          widget.hint,
          style: TextStyle(
            fontSize: 14,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        items: _items
            .map((item) => DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ))
            .toList(),
        value: dropdownValue,
        onChanged: widget.onChanged,
        buttonStyleData: ButtonStyleData(
          height: widget.buttonHeight ?? 50,
          width: widget.buttonWidth,
          padding: widget.buttonPadding ?? const EdgeInsets.symmetric(horizontal: 14),
          decoration: widget.buttonDecoration ??
              BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.black26,
                ),
                color: isDarkMode ? Colors.grey[700] : Colors.lightBlue[100],
              ),
          elevation: 2,
        ),
        iconStyleData: IconStyleData(
          icon: Icon(
            widget.icon ?? Icons.arrow_drop_down,
            color: isDarkMode
                ? (widget.iconEnabledColor ?? Colors.white)
                : (widget.iconEnabledColor ?? Colors.black),
          ),
          iconSize: widget.iconSize ?? 24,
        ),
        dropdownStyleData: DropdownStyleData(
          maxHeight: widget.dropdownMaxHeight ?? 200,
          width: widget.dropdownWidth,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: isDarkMode ? Colors.grey[800] : Colors.lightBlue[100],
          ),
          scrollbarTheme: ScrollbarThemeData(
            radius: const Radius.circular(40),
            thickness: MaterialStateProperty.all(6),
            thumbVisibility: MaterialStateProperty.all(true),
          ),
        ),
        menuItemStyleData: const MenuItemStyleData(
          height: 40,
          padding: EdgeInsets.symmetric(horizontal: 14),
        ),
        dropdownSearchData: widget.isSearchable
            ? DropdownSearchData(
          searchController: _searchController,
          searchInnerWidgetHeight: 50,
          searchInnerWidget: Padding(
            padding: const EdgeInsets.only(
              top: 8,
              bottom: 4,
              right: 8,
              left: 8,
            ),
            child: TextFormField(
              controller: _searchController,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                hintText: 'Search...',
                hintStyle: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white : Colors.black),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                _onSearchChanged();
              },
            ),
          ),
          searchMatchFn: (item, searchValue) {
            return item.value
                .toString()
                .toLowerCase()
                .contains(searchValue.toLowerCase());
          },
        )
            : null,
        onMenuStateChange: (isOpen) {
          if (!isOpen) {
            _searchController.clear();
            setState(() {
              _items = widget.items;
            });
          }
        },
      ),
    );
  }
}
