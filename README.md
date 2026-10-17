# AQIPath

**Navigate by the air you breathe.** AQIPath is an Android and iOS app that finds the route with the cleanest air, using real-time Air Quality Index (AQI) data together with live traffic and travel times. Runners and cyclists can also generate loop routes of a chosen distance that start and end at home.

[![Get it on Google Play](https://img.shields.io/badge/Google%20Play-Download-3DDC84?logo=googleplay&logoColor=white)](https://play.google.com/store/apps/details?id=com.tekzee.aqiapp)
[![Download on the App Store](https://img.shields.io/badge/App%20Store-Download-0D96F6?logo=appstore&logoColor=white)](https://apps.apple.com/app/id6754751849)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS-555)
![Status](https://img.shields.io/badge/status-released-brightgreen)

> Android package ID: `com.tekzee.aqiapp` · Category: Weather · Content rating: Everyone

---

## Why AQIPath?

The fastest route is often the most polluted one: busy arterial roads, junctions and industrial belts. Standard navigation apps optimise only for time. AQIPath adds air quality to the equation so you can choose how much extra time you are willing to trade for cleaner air, whether you are commuting, doing the school run, or going for a run.

## Features

- **Cleanest-route navigation.** Compares route options using real-time AQI along the path, live traffic and estimated travel time, then recommends the one with the lowest pollution exposure.
- **Fitness loop routes.** Pick a distance (2, 5 or 10 km) and get a walking or cycling loop around your location that starts and ends at the same point, biased toward low-AQI streets.
- **Commute balancing.** Weighs travel time against air quality so you can see the trade-off before you set off.
- **Live colour-coded AQI map.** See current air quality in your area at a glance.
- **Smart alerts.** Get notified when air quality around you worsens or when a healthier route becomes available.

### Who is it for?

Daily commuters, runners and cyclists, parents on school runs, travellers in unfamiliar cities, and anyone with asthma or other respiratory sensitivities.

## Download

AQIPath is available on both stores:

- **Android** — [Google Play](https://play.google.com/store/apps/details?id=com.tekzee.aqiapp)
- **iOS** — [App Store](https://apps.apple.com/app/id6754751849)

## Screenshots

Screenshots are listed on the [Play Store](https://play.google.com/store/apps/details?id=com.tekzee.aqiapp) and [App Store](https://apps.apple.com/app/id6754751849) pages. To show them here, add images to [`docs/screenshots/`](docs/screenshots/) and reference them, for example:

```markdown
<p float="left">
  <img src="docs/screenshots/home.png" width="200" />
  <img src="docs/screenshots/route.png" width="200" />
  <img src="docs/screenshots/loop.png" width="200" />
</p>
```

## How it works

1. **Locate.** The app reads your location (with your permission) and your chosen destination or loop distance.
2. **Generate candidates.** Several candidate routes are requested from a routing provider, including live traffic and travel times.
3. **Score by air quality.** Each candidate is sampled along its path against real-time AQI data, producing an exposure score.
4. **Rank and recommend.** Routes are ranked on a combination of exposure and travel time, and the best option is shown on the colour-coded map.
5. **Keep watching.** While you are out, the app monitors conditions and alerts you if air quality changes or a cleaner route appears.

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for more detail.

## AQI reference

| AQI | Category | Meaning |
|-----|----------|---------|
| 0–50 | Good | Air quality is satisfactory |
| 51–100 | Moderate | Acceptable; sensitive people may be affected |
| 101–150 | Unhealthy for sensitive groups | Sensitive groups may experience effects |
| 151–200 | Unhealthy | Everyone may begin to experience effects |
| 201–300 | Very unhealthy | Health alert for everyone |
| 301+ | Hazardous | Emergency conditions |

Bands follow the US EPA scale. Local scales (for example India's CPCB index) use different breakpoints.

## Getting started (development)

### Prerequisites

- Android Studio (latest stable)
- JDK 17 or newer
- An Android device or emulator
- API keys for your routing/maps and AQI data providers (see below)

### Setup

```bash
git clone https://github.com/AnayMehta976/AQIPath.git
cd AQIPath
cp local.properties.example local.properties   # then fill in your keys
```

Open the project in Android Studio, let Gradle sync, and run the `app` configuration.

### Configuration

Secrets are never committed. Copy [`local.properties.example`](local.properties.example) to `local.properties` and add your own keys:

```properties
MAPS_API_KEY=your_maps_key
AQI_API_KEY=your_aqi_data_key
```

## Project structure

```
AQIPath/
├── app/                  # Android application module
├── docs/                 # Architecture notes and screenshots
├── .github/              # Issue and pull request templates
├── CONTRIBUTING.md
├── PRIVACY.md
└── README.md
```

## Privacy

AQIPath uses your location to compute routes and show local air quality. See [PRIVACY.md](PRIVACY.md) for what is collected, how it is protected, and how to request deletion.

## Roadmap

- [ ] Offline caching of recent AQI readings
- [ ] Personal exposure history and weekly summary
- [ ] Health profiles (asthma and other sensitivities) with tailored thresholds
- [ ] Wear OS companion for run tracking
- [ ] Hindi and other regional languages

## Contributing

Contributions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) first, then open an issue or pull request.

## Support

- Bug reports and feature requests: [GitHub Issues](https://github.com/AnayMehta976/AQIPath/issues)
- Email: srbmehta@gmail.com

## Acknowledgements

Air quality data and routing are provided by third-party services. Thanks to the open-source community for the libraries that make this app possible.
