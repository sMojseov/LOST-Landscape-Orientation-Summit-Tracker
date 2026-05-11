# 🏔️ LOST: Alpine Intelligence System

**LOST** (Location, Orientation, Scanning, Terrain) is a high-performance Alpine navigation and exploration platform built for mountaineers, hikers, and outdoor enthusiasts. It transforms your iPhone into a sophisticated tactical HUD for the wilderness, combining real-time sensor fusion with professional-grade topographic data.

---

## 🌟 The Vision

In the mountains, information is safety. **LOST** was conceived to bridge the gap between static paper maps and the dynamic, often unpredictable environment of the Alps. Whether you're identifying a distant peak through the **LOST Lens** or planning a technical ascent in the **Hike Planner**, LOST provides the context you need to move with confidence.

---

## 🚀 Key Features

### 1. 🔍 LOST Lens (Scanning)
The heart of the app. A real-time, sensor-driven scanning interface that provides a tactical overlay of your surroundings.
- **Dynamic HUD:** Real-time altitude, magnetic/true heading, and confidence metrics.
- **Gyro-Leveling:** Integrated horizon tracking to ensure precise orientation even on steep terrain.
- **3x3 Alignment Grid:** Professional framing for terrain documentation and peak identification.
- **Tactical Controls:** Instant torch toggle and stability indicators.

### 2. 🗺️ LOST Topo (Mapping)
Professional-grade mapping designed for the rugged Alpine environment.
- **Terrain Awareness:** High-fidelity topographic layers optimized for elevation changes.
- **Region-Centric Views:** Intelligent focusing on key Alpine massifs (Mont Blanc, Matterhorn, Dolomites).
- **Interactive Waypoints:** Visualize routes and critical milestones with elevation data.

### 3. 🏔️ Alpine Registry (Explore)
A comprehensive, curated database of Europe's most iconic peaks and regions.
- **Detailed Peak Specs:** Elevation, range, and country data for 20+ major Alpine summits.
- **Regional Intelligence:** Deep dives into areas like the *Bernese Oberland*, *Hohe Tauern*, and *Wetterstein*.
- **Quick-Navigate:** Seamlessly jump from a mountain profile to its exact location on the Topo map.

### 4. 🥾 Hike Planner
Plan your expeditions with surgical precision.
- **Waypoint Tracking:** Break down your hike into manageable segments with time and distance estimates.
- **Elevation Profiling:** Understand the vertical challenge before you step onto the trail.
- **Weather Integration:** (In Development) Real-time Alpine weather services for your specific coordinates.

### 5. 🛡️ Safety & Profile
Your digital emergency beacon.
- **Emergency Info:** Instant access to your critical medical data and emergency contacts.
- **Theming:** Customizable UI (Deep Forest & Sage Green) optimized for both high-glare sunlight and low-light summit pushes.

---

## 🏗️ Technical Architecture

LOST is built using a modern, reactive architecture centered around **SwiftUI** and **Combine**.

- **Core State:** Managed via a centralized `AppState` and `SettingsManager`, ensuring seamless navigation across the Scan, Map, and Explore modules.
- **Sensor Fusion:** 
    - `CoreLocation`: Provides high-accuracy GPS and magnetic heading.
    - `CoreMotion`: Processes accelerometer and gyroscope data at 30Hz for the scanning HUD.
    - `AVFoundation`: Handles the low-latency camera feed and hardware torch control.
- **Modular Design:** Features are strictly decoupled into `Features/` directories, making the codebase highly maintainable and extensible.

---

## 🛠️ Installation

1. **Requirements:**
    - macOS Sonoma or later.
    - Xcode 15.3+.
    - Physical iOS device (recommended for Sensor/Camera features).

2. **Setup:**
    ```bash
    git clone https://github.com/your-repo/LOST.git
    cd LOST
    open LOST.xcodeproj
    ```

3. **Run:** Select your target device and hit `Cmd + R`.

---

## ⚠️ Safety Disclaimer

**LOST is a supplemental navigation tool.** 
Mountain environments are inherently dangerous. Always carry a physical map and compass, check local weather reports, and never rely solely on a mobile device for navigation. Your battery can fail; your skills should not.

---

## 🎨 Theme & Aesthetics

LOST utilizes a bespoke color palette designed for the outdoors:
- **Deep Forest:** Primary accent for light mode, providing high contrast against topographical maps.
- **Sage Green:** Primary accent for dark mode, reducing eye strain during night-time navigation.
- **Glassmorphism:** The HUD utilizes `.ultraThinMaterial` to ensure the environment remains visible behind the data overlays.

---

Created by **Stefan Mojseov**.
