class ScreenSize {
  static const double mobile = 600.0;      // phones
  static const double tablet = 1024.0;     // tablets + small laptops
  static const double desktop = 1440.0;    // larger laptops & desktops

  static bool isMobile(double width) => width < mobile;
  static bool isTablet(double width) => width >= mobile && width < desktop;
  static bool isDesktop(double width) => width >= desktop;
}