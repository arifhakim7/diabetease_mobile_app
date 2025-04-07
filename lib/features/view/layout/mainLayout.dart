import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fyp_diabetease/features/view/pages/home/homepage_.dart';
import 'package:fyp_diabetease/features/view/pages/search/search.dart';
import 'package:fyp_diabetease/features/view/pages/inbox/inbox_page.dart';
import 'package:fyp_diabetease/features/view/pages/saveRecipe/saved_recipe_page.dart';

class MainLayout extends StatefulWidget {
  final int initialPage;

  const MainLayout({super.key, this.initialPage = 0}); // Default to Home page

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late int currentPage;
  late PageController _page;

  @override
  void initState() {
    super.initState();
    currentPage = widget.initialPage;
    _page = PageController(initialPage: widget.initialPage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // Automatically adjusts for keyboard
      body: PageView(
        controller: _page,
        onPageChanged: (value) {
          setState(() {
            currentPage = value;
          });
        },
        children: const <Widget>[
          home_page(),
          Search(),
          SavedRecipe(),
          InboxPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color.fromARGB(174, 255, 255, 255),
        selectedItemColor: Colors.blue,
        unselectedItemColor: const Color.fromARGB(188, 66, 66, 66),
        currentIndex: currentPage,
        onTap: (page) {
          setState(() {
            currentPage = page;
            _page.animateToPage(
              page,
              duration: const Duration(milliseconds: 50),
              curve: Curves.easeInOut,
            );
          });
        },
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.bookmark),
            label: 'Saved',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.message),
            label: 'Inbox',
          ),
        ],
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButton: MediaQuery.of(context).viewInsets.bottom == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, 'upload_recipe_page');
              },
              backgroundColor: const Color.fromARGB(174, 255, 255, 255),
              child: const Icon(Icons.add),
              shape: const CircleBorder(),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
