# Material World Clock v2


![GitHub Tag](https://img.shields.io/github/v/tag/EricZeller/flutter-world-clock-v2?logo=data%3Aimage%2Fsvg%2Bxml%3Bbase64%2CPHN2ZyBmaWxsPSIjZmZmZmZmIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld0JveD0iMCAwIDI0IDI0Ij48cGF0aCBkPSJtMjEuNDEgMTEuNDEtOC44My04LjgzYy0uMzctLjM3LS44OC0uNTgtMS40MS0uNThINGMtMS4xIDAtMiAuOS0yIDJ2Ny4xN2MwIC41My4yMSAxLjA0LjU5IDEuNDFsOC44MyA4LjgzYy43OC43OCAyLjA1Ljc4IDIuODMgMGw3LjE3LTcuMTdjLjc4LS43OC43OC0yLjA0LS4wMS0yLjgzek02LjUgOEM1LjY3IDggNSA3LjMzIDUgNi41UzUuNjcgNSA2LjUgNSA4IDUuNjcgOCA2LjUgNy4zMyA4IDYuNSA4eiIvPjwvc3ZnPg%3D%3D&label=version&link=https%3A%2F%2Fgithub.com%2FEricZeller%2Fflutter-world-clock-v2%2Freleases)
![License](https://img.shields.io/github/license/EricZeller/flutter-world-clock-v2?logo=gnu)
![GitHub Downloads (all assets, all releases)](https://img.shields.io/github/downloads/EricZeller/flutter-world-clock-v2/total?logo=data:image/svg+xml;base64,PHN2ZyBmaWxsPSIjZmZmZmZmIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld0JveD0iMCAwIDI0IDI0Ij48cGF0aCBkPSJNNSAyMGgxNHYtMkg1djJ6TTE5IDloLTRWM0g5djZINWw3IDcgNy03eiIvPjwvc3ZnPg==)
![GitHub top language](https://img.shields.io/github/languages/top/EricZeller/flutter-world-clock-v2?logo=data:image/svg+xml;base64,PHN2ZyBmaWxsPSIjZmZmZmZmIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld0JveD0iMCAwIDI0IDI0Ij48cGF0aCBkPSJNOS40IDE2LjYgNC44IDEybDQuNi00LjZMOCA2bC02IDYgNiA2IDEuNC0xLjR6bTUuMiAwIDQuNi00LjYtNC42LTQuNkwxNiA2bDYgNi02IDYtMS40LTEuNHoiLz48L3N2Zz4=)
![Issues](https://img.shields.io/github/issues/EricZeller/flutter-world-clock-v2?logo=github)
![Last Commit](https://img.shields.io/github/last-commit/EricZeller/flutter-world-clock-v2?logo=data:image/svg+xml;base64,PHN2ZyBmaWxsPSIjZmZmZmZmIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld0JveD0iMCAwIDI0IDI0Ij48cGF0aCBkPSJNMTYuOSAxMWE1IDUgMCAwIDAtOS44IDBIMnYyaDUuMWE1IDUgMCAwIDAgOS44IDBIMjJ2LTJoLTUuMXpNMTIgMTVjLTEuNjYgMC0zLTEuMzQtMy0zczEuMzQtMyAzLTMgMyAxLjM0IDMgMy0xLjM0IDMtMyAzeiIvPjwvc3ZnPg==)


<a href="https://apt.izzysoft.de/fdroid/index/apk/de.ericz.worldclockv2/"><img src="assets/IzzyOnDroidButton_nofont.svg" height="50px"></a>

World Clock is a Flutter app that displays the current time and weather for various cities. The app uses the Material You theme to provide a modern and customizable user experience.

## Features

- Displays the current time for selected cities.
- Shows the current weather (temperature, weather conditions) for selected cities.
- Customizable Material You theme.

## Screenshots

<p align="center">
<img src="fastlane/metadata/android/en-US/images/phoneScreenshots/screenshot_01_dark_lightmode.png" alt="Screenshot dark/light mode" height="350"/>
<img src="fastlane/metadata/android/en-US/images/phoneScreenshots/screenshot_02_city_search.png" alt="Screenshot city search" height="350"/>
<img src="fastlane/metadata/android/en-US/images/phoneScreenshots/screenshot_03_settings.png" alt="Screenshot settings" height="350"/>
<img src="fastlane/metadata/android/en-US/images/phoneScreenshots/screenshot_04_purple.png" alt="Screenshot purple" height="350"/>
</p>

## Sources

All icons and fonts from [fonts.google.com](https://fonts.google.com)

Flag icons from [flagpedia.net](https://flagpedia.net/download)

Libraries/packages from pub.dev

Used (keyless) weather API: [wttr.in](https://github.com/chubin/wttr.in) by [@chubin](https://github.com/chubin)


## Installation

Head to the releases for installation candidates.

To install and run the app locally, follow these steps:

1. **Install Flutter**:
   Ensure that Flutter is installed on your system. Follow the [official guide](https://flutter.dev/docs/get-started/install) to install Flutter.

2. **Clone the repository**:
   ```bash
   git clone https://github.com/EricZeller/flutter-world-clock-v2.git
   cd flutter-world-clock-v2
   flutter pub get
   flutter run
