# MacStats

A modern, highly interactive system monitor for macOS menu bar.

<img width="332" height="382" alt="Screenshot 2026-01-04 at 7 47 00 PM" src="https://github.com/user-attachments/assets/4c76620f-8722-4163-9726-641df2182fa4" />
<img width="364" height="364" alt="Screenshot 2026-01-04 at 7 47 15 PM" src="https://github.com/user-attachments/assets/996e6a02-f386-42ba-a119-c0314cbed50e" />
<img width="302" height="670" alt="Screenshot 2026-01-04 at 7 47 30 PM" src="https://github.com/user-attachments/assets/43491f43-8968-4bcf-bad4-06664a86b37e" />

## Features

-   **CPU**: 4x4 Core Grid, Usage %, and Top Processes filter (excluding system daemons).
-   **GPU**: Dashboard with Radial Gauge usage and Temperature stats.
-   **Memory**: Real-time RAM usage.
-   **Disk**: Read/Write speeds with interactive bidirectional graph (Green/Red).
-   **Network**: Upload/Download speeds with local IP display.
-   **Sensors**: Thermal pressure and temperature sensors (Apple Silicon support).
-   **Interactive Graphs**: Hover over any graph to see precise historical values.
-   **Modern UI**: Native SwiftUI, Dark Mode support, and polished aesthetics.

### Build from Source

1.  Clone the repository:
    ```bash
    git clone https://github.com/yourusername/macstats.git
    cd macstats
    ```
2.  **Run Locally (Debug)**:
    ```bash
    swift run
    ```
3.  **Build DMG (Release)**:
    ```bash
    ./scripts/build_dmg.sh
    ```
    This creates a distributable `MacStats.dmg` in the project root.

## Development

### Prerequisites

-   macOS 12.0+
-   Xcode 13.0+ (Swift 5.5+)

### Code Style

This project uses `SwiftLint` to enforce coding standards.

1.  **Install dependencies**:
    ```bash
    brew install swiftlint pre-commit
    ```
2.  **Install hooks**:
    ```bash
    pre-commit install
    ```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
