# MacStats

A modern, highly interactive system monitor for macOS menu bar.

## Features

-   **CPU**: 4x4 Core Grid, Usage %, and Top Processes filter (excluding system daemons).
-   **GPU**: Dashboard with Radial Gauge usage and Temperature stats.
-   **Memory**: Real-time RAM usage.
-   **Disk**: Read/Write speeds with interactive bidirectional graph (Green/Red).
-   **Network**: Upload/Download speeds with local IP display.
-   **Sensors**: Thermal pressure and temperature sensors (Apple Silicon support).
-   **Interactive Graphs**: Hover over any graph to see precise historical values.
-   **Modern UI**: Native SwiftUI, Dark Mode support, and polished aesthetics.

## Installation

1.  Clone the repository:
    ```bash
    git clone https://github.com/yourusername/macstats.git
    cd macstats
    ```
2.  Build and Run:
    ```bash
    swift run
    ```

## Development

### Prerequisites

-   macOS 12.0+
-   Xcode 13.0+ (Swift 5.5+)

### Code Style

This project uses `SwiftLint` to enforce code style.

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
