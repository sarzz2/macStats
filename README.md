# MacStats

A modern, highly interactive system monitor for macOS menu bar.

<img width="299" height="791" alt="Screenshot 2026-05-03 at 9 33 03 PM" src="https://github.com/user-attachments/assets/fea5557a-e202-4321-b2e9-0ebd592ece0f" />
<img width="325" height="652" alt="Screenshot 2026-05-03 at 9 32 46 PM" src="https://github.com/user-attachments/assets/a55f3993-67e1-4fc2-98ca-c82c0d4afa90" />
<img width="320" height="616" alt="Screenshot 2026-05-03 at 9 32 18 PM" src="https://github.com/user-attachments/assets/f1333ef1-d685-46d2-858b-0d24ff94ef37" />


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
