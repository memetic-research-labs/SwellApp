# SwellApp

Surf forecast and beach tracking app for iOS.

See swell direction, wind conditions, and wave height for your saved surf spots at a glance.

## Features

- Save your favorite surf breaks by dropping a pin on the map
- GPS-based location — map opens to your current location
- Automatic coastline bearing detection using OpenStreetMap data
- View current swell height, direction, and offshore/onshore wind
- 7-day forecast chart with star ratings
- Hourly surf quality breakdown showing swell, wind speed, and wind type
- Shoreline diagram showing swell and wind arrows relative to the beach
- 24 built-in US surf spots searchable by name
- Imperial and metric unit support

## Tech Stack

- Swift + SwiftUI
- MapKit for beach selection
- CoreLocation for GPS and compass
- Weather & marine data from [Open-Meteo](https://open-meteo.com/)
- Coastline geometry from [OpenStreetMap Overpass API](https://overpass-api.de/)

## Requirements

- iOS 18+
- Xcode 26+

## Getting Started

1. Clone the repo:
   ```
   git clone git@github.com:memetic-research-labs/SwellApp.git
   cd SwellApp/Swell
   ```

2. Open `Swell.xcodeproj` in Xcode.

3. Select an iOS simulator or device target.

4. Build and run (`Cmd+R`).

No additional dependencies or package managers required — all APIs are called directly.

## Project Structure

```
Swell/
├── Models/           # Beach, SurfSpot, forecast data models
├── Services/         # API clients, persistence, scoring engine
├── Utilities/        # Compass angle math, unit formatting
├── Views/
│   ├── BeachMap/     # Add beach with map, search, bearing dial
│   ├── Forecast/     # Forecast detail, shoreline diagram
│   ├── SavedBeaches/ # User's saved spots list
│   └── Settings/     # Unit system toggle
├── Resources/        # Built-in surf spot database (JSON)
└── SwellApp.swift    # App entry point
```

## Design Notes

The **Shoreline Condition View** is the core visual: a square diagram showing ocean (top 85%) and land (bottom 15%), with arrow wedges for swell (blue) and wind (purple) direction. Rather than a traditional compass, it represents conditions relative to the shoreline — swell coming from sea to shore, wind from shore to ocean.

## License

MIT
