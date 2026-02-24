import 'package:flutter/material.dart';
import '../constant/colorconstant.dart';

class CommanSearchField extends StatelessWidget {
  final TextEditingController searchcontroller;
  final String? hintText;
  final Function(String)? onSearch;
  final IconData? prefixicon;
  final Color? prefixcolor;
  final IconData? suffixicon;
  final VoidCallback? onSuffixTap;

  const CommanSearchField({
    super.key,
    required this.searchcontroller,
    this.hintText,
    this.prefixicon,
    this.prefixcolor,
    this.suffixicon,
    this.onSearch,
    this.onSuffixTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorConstant.whiteColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: searchcontroller,
        onChanged: (value) {
          if (onSearch != null) onSearch!(value);
        },
        style: const TextStyle(
          color: ColorConstant.blackColor,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: hintText ?? "Search here...",
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(
              color: ColorConstant.gradientColor1,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(
              color: ColorConstant.gradientColor1,
              width: 1.5,
            ),
          ),
          prefixIcon: Icon(prefixicon ?? Icons.search, color: prefixcolor ?? ColorConstant.blackColor),
          suffixIcon: suffixicon != null ? IconButton(icon: Icon(suffixicon, color: ColorConstant.secondary,),
            onPressed: onSuffixTap,
          ) : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          border: InputBorder.none,
        ),
      ),
    );
  }
}