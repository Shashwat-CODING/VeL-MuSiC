import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../generated/l10n.dart';
import '../../themes/colors.dart';
import '../../themes/text_styles.dart';
import '../../utils/adaptive_widgets/adaptive_widgets.dart';
import '../../utils/bottom_modals.dart';
import 'color_icon.dart';
import 'setting_screen_data.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  TextEditingController searchController = TextEditingController();
  bool? isBatteryOptimisationDisabled;

  String searchText = "";

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      checkBatteryOptimisation();
    }
  }

  @override
  void dispose() {
    super.dispose();
    searchController.dispose();
  }

  checkBatteryOptimisation() async {
    isBatteryOptimisationDisabled =
        await Permission.ignoreBatteryOptimizations.isGranted;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      appBar: AdaptiveAppBar(
        title: Text(S.of(context).Settings,
            style: mediumTextStyle(context, bold: false)),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: AdaptiveTextField(
                  controller: searchController,
                  onChanged: (value) {
                    setState(() {
                      searchText = value;
                    });
                  },
                  autofocus: false,
                  keyboardType: TextInputType.text,
                  maxLines: 1,
                  textInputAction: TextInputAction.search,
                  fillColor:
                      Platform.isWindows ? null : darkGreyColor.withAlpha(100),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                  borderRadius:
                      BorderRadius.circular(Platform.isWindows ? 4.0 : 35),
                  hintText: S.of(context).Search_Settings,
                  prefix: Icon(Icons.search, color: spotifyGreen),
                  suffix: searchController.text.trim().isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            searchController.text = "";
                            searchText = "";
                            setState(() {});
                          },
                          child: Icon(CupertinoIcons.clear, color: spotifyGreen),
                        )
                      : null,
                ),
              ),
              if (searchText == "" &&
                  isBatteryOptimisationDisabled != true &&
                  Platform.isAndroid)
                AdaptiveListTile(
                  backgroundColor: Colors.red.withOpacity(0.3),
                  leading: const ColorIcon(
                    icon: Icons.battery_alert,
                    color: Colors.red,
                  ),
                  title: Text(S.of(context).Battery_Optimisation_title),
                  subtitle: Text(
                    S.of(context).Battery_Optimisation_message,
                    style: tinyTextStyle(context),
                  ),
                  onTap: () async {
                    await Permission.ignoreBatteryOptimizations.request();
                    await checkBatteryOptimisation();
                  },
                ),

              ...(searchText == ""
                      ? settingScreenData(context)
                      : allSettingsData(context)
                          .where((element) => element.title
                              .toLowerCase()
                              .contains(searchText.toLowerCase()))
                          .toList())
                  .map((e) {
                return AdaptiveListTile(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  title: Text(
                    e.title,
                    style:
                        textStyle(context, bold: false).copyWith(fontSize: 16),
                  ),
                  leading: (e.icon != null)
                      ? ColorIcon(
                          color: e.color,
                          icon: e.icon!,
                        )
                      : null,
                  trailing: e.trailing != null
                      ? e.trailing!(context)
                      : (e.hasNavigation
                          ? Icon(
                              AdaptiveIcons.chevron_right,
                              size: 30,
                              color: spotifyGreen,
                            )
                          : null),
                  onTap: () {
                    if (e.hasNavigation && e.location != null) {
                      context.go(e.location!);
                    } else if (e.onTap != null) {
                      e.onTap!(context);
                    }
                  },
                  subtitle: e.subtitle != null ? e.subtitle!(context) : null,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}


