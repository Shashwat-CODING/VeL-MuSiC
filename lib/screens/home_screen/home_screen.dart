import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../generated/l10n.dart';
import '../../utils/adaptive_widgets/adaptive_widgets.dart';
import '../../ytmusic/ytmusic.dart';
import '../../themes/colors.dart';
import 'section_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final YTMusic ytMusic = GetIt.I<YTMusic>();
  late ScrollController _scrollController;
  late List chips = [];
  late List sections = [];
  int page = 0;
  String? continuation;
  bool initialLoading = true;
  bool nextLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    fetchHome();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }



  _scrollListener() async {
    if (initialLoading || nextLoading || continuation == null) {
      return;
    }

    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      await fetchNext();
    }
  }

  fetchHome() async {
    setState(() {
      initialLoading = true;
      nextLoading = false;
    });
    Map<String, dynamic> home = await ytMusic.browse();
    if (mounted) {
      setState(() {
        initialLoading = false;
        nextLoading = false;
        chips = home['chips'];
        sections = home['sections'];
        continuation = home['continuation'];
      });
    }
  }

  refresh() async {
    if (initialLoading) return;
    Map<String, dynamic> home = await ytMusic.browse();
    if (mounted) {
      setState(() {
        initialLoading = false;
        nextLoading = false;
        chips = home['chips'];
        sections = home['sections'];
        continuation = home['continuation'];
      });
    }
  }

  fetchNext() async {
    if (continuation == null) return;
    setState(() {
      nextLoading = true;
    });
    Map<String, dynamic> home =
        await ytMusic.browseContinuation(additionalParams: continuation!);
    List<Map<String, dynamic>> secs =
        home['sections'].cast<Map<String, dynamic>>();
    if (mounted) {
      setState(() {
        sections.addAll(secs);
        continuation = home['continuation'];
        nextLoading = false;
      });
    }
  }

  Widget _horizontalChipsRow(List data) {
    var list = <Widget>[const SizedBox(width: 16)];
    for (var element in data) {
      list.add(
        AdaptiveInkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => context.go('/chip', extra: element),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
                color: spotifyMediumGrey,
                borderRadius: BorderRadius.circular(20)),
            child: Text(element['title']),
          ),
        ),
      );
      list.add(const SizedBox(
        width: 8,
      ));
    }
    list.add(const SizedBox(
      width: 8,
    ));
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: list,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      appBar: PreferredSize(
        preferredSize: const AdaptiveAppBar().preferredSize,
        child: AdaptiveAppBar(
          automaticallyImplyLeading: false,
          title: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'VeL-MuSic',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: spotifyWhite,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.settings_outlined, color: spotifyWhite),
                  onPressed: () => context.go('/settings'),
                ),
              ],
            ),
          ),
          centerTitle: false,
        ),
      ),
      body: initialLoading
          ? const Center(child: AdaptiveProgressRing())
          : RefreshIndicator(
              onRefresh: () => refresh(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                controller: _scrollController,
                child: SafeArea(
                  child: Column(
                    children: [
                      _horizontalChipsRow(chips),
                      Column(
                        children: [
                          // Greeting just above the first section
                          if (sections.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              child: Row(
                                children: [
                                  Text(
                                    _getGreeting(),
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: spotifyWhite,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ...sections.asMap().entries.map((entry) {
                            int index = entry.key;
                            Map section = entry.value;
                            return SectionItem(
                              section: section,
                              isFirstSection: index == 0, // Pass flag for first section
                            );
                          }),
                          if (!nextLoading && continuation != null)
                            const SizedBox(height: 50),
                          if (nextLoading)
                            const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: AdaptiveProgressRing()),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
