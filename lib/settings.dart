import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' as mat;
import 'package:flutter/material.dart';
import 'package:weylusmousereplacement/dimens.dart';
import 'package:weylusmousereplacement/settings_item.dart';

Future<void> showDialog(BuildContext parentContext) async {
  mat.showDialog(
    context: parentContext,
    barrierColor: Colors.transparent,
    builder: (BuildContext context) => AlertDialog(
      backgroundColor: Colors.grey,
      title: Text(
        "Settings".toUpperCase(),
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.black, fontSize: textXL, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsItem("Server IP", "The IP Address for your Weylus server", "server_ip", "192.168.xx.xx"),
          SettingsItem("Access Code", "The Access Code for your Weylus server", "access_code", "0000"),
          // Padding(
          //   padding: EdgeInsets.symmetric(horizontal: spaceMD),
          //   child: Text(
          //     "Server IP".toUpperCase(),
          //     style: TextStyle(color: Colors.black, fontSize: textMD, fontWeight: FontWeight.bold),
          //   ),
          // ),
          // Padding(
          //   padding: EdgeInsets.symmetric(horizontal: spaceMD),
          //   child: Text(
          //     "The IP Address for your Weylus server",
          //     style: TextStyle(color: Colors.black54, fontSize: textSM, fontWeight: FontWeight.bold),
          //   ),
          // ),
          // SizedBox(height: spaceSM),
          // TextField(
          //   style: TextStyle(
          //     color: Colors.white,
          //     fontWeight: FontWeight.bold,
          //     decoration: TextDecoration.none,
          //     decorationThickness: 0,
          //     fontSize: textMD,
          //   ),
          //   decoration: InputDecoration(
          //     fillColor: Colors.black87,
          //     filled: true,
          //     border: const OutlineInputBorder(borderRadius: BorderRadius.all(cornerRadiusMD), borderSide: BorderSide.none),
          //     isCollapsed: true,
          //     hintText: "192.168.xx.xx",
          //     floatingLabelBehavior: FloatingLabelBehavior.always,
          //     contentPadding: const EdgeInsets.symmetric(horizontal: spaceMD, vertical: spaceSM),
          //     isDense: true,
          //   ),
          // ),
        ],
      ),
    ),
  );
}
