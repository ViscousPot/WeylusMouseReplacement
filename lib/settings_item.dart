import 'package:flutter/material.dart';
import 'package:weylusmousereplacement/dimens.dart';
import 'package:weylusmousereplacement/global.dart';

class SettingsItem extends StatefulWidget {
  const SettingsItem(this.title, this.description, this.storageKey, this.hint, {super.key});

  final String title;
  final String description;
  final String storageKey;
  final String hint;

  @override
  State<SettingsItem> createState() => _SettingsItemState();
}

class _SettingsItemState extends State<SettingsItem> {
  final controller = TextEditingController();

  @override
  initState() {
    Future.delayed(Duration.zero, () async {
      controller.text = await storage.read(key: widget.storageKey) ?? "";
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: spaceMD),
          child: Text(
            widget.title.toUpperCase(),
            style: TextStyle(color: Colors.black, fontSize: textMD, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: spaceMD),
          child: Text(
            widget.description,
            style: TextStyle(color: Colors.black54, fontSize: textSM, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: spaceSM),
        TextField(
          controller: controller,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.none,
            decorationThickness: 0,
            fontSize: textMD,
          ),
          decoration: InputDecoration(
            fillColor: Colors.black87,
            filled: true,
            border: const OutlineInputBorder(borderRadius: BorderRadius.all(cornerRadiusMD), borderSide: BorderSide.none),
            isCollapsed: true,
            hintText: widget.hint,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            contentPadding: const EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM),
            isDense: true,
          ),
          onChanged: (text) async => await storage.write(key: widget.storageKey, value: text),
        ),
      ],
    );
  }
}
