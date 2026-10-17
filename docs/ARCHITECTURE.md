# Architecture

High-level overview of how AQIPath produces a clean-air route.

## Pipeline

```
Location + destination / loop distance
        │
        ▼
Candidate route generation (routing provider, live traffic)
        │
        ▼
Sample points along each route
        │
        ▼
AQI lookup per sample (real-time data provider)
        │
        ▼
Exposure score = f(AQI along path, time spent)
        │
        ▼
Rank by exposure and travel time  ──►  Colour-coded map + alerts
```

## Exposure scoring

For each candidate route, points are sampled at regular intervals. Each point's AQI is weighted by the time spent in that segment, giving a time-weighted average exposure. Routes are then ranked by a blend of exposure and total travel time, so a much slower route is not recommended for a marginal AQI gain.

## Loop routes

For a requested distance (2, 5 or 10 km), waypoints are placed around the start point to form a loop. Candidate loops are scored with the same exposure model, and the lowest-exposure loop within a distance tolerance is returned.

## Alerts

A background check compares current AQI along the user's active or saved routes with the last known state, and notifies the user when conditions worsen or a better route is available.

> Update this document with module names and data sources as the code lands in the repository.
