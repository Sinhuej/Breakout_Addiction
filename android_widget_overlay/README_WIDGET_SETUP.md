Breakout Addiction Android Widget Overlay
========================================

This folder contains safe Android widget files staged OUTSIDE the live android/
tree so the repo does not break when local android platform files are absent.

When you are ready and the real android/ folder exists in the repo, copy these
files into the matching android/app/src/main/... paths.

Files included:
- res/layout/breakout_widget_compact.xml
- res/xml/breakout_widget_info.xml
- kotlin/com/example/breakout_addiction/BreakoutWidgetProvider.kt
