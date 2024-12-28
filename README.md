# zzd

[![Zig](https://img.shields.io/badge/Made%20with-Zig-%23F7A41D)](https://ziglang.org)

A powerful hexdump utility built with Zig that helps you inspect binary content in a human-readable format. Perfect for developers who need to understand the underlying structure of files.

## Features

- Clean and intuitive hex dump output
- Fast performance with Zig's efficiency
- Cross-platform support (Windows, Linux, macOS)
- Flexible display options and number formats
- Pattern highlighting capabilities
- Customizable output formatting

## Prerequisites

Before installing `zzd`, ensure you have [Zig](https://ziglang.org/download/) installed on your system.

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/lvkolb/zzd.git
cd zzd
```

### 2. Build and Install

Choose one of the following installation methods:

#### Method A: Global Installation

```bash
# Build and install to /usr/local/bin (requires admin privileges)
zig build install-to-bin
```

#### Method B: Local Build

```bash
# Just build the project
zig build
```

## Usage

### Basic Command

```bash
zzd <filename> [options]
```

### Platform-Specific Paths

#### Windows
```bash
zig-out\bin\zzd <filename> [options]
```

#### Linux/macOS
```bash
zig-out/bin/zzd <filename> [options]
```

### Command-Line Options

#### Display Options
```
--line-length=<n>   Set the number of bytes per line (default: 16, max: 64)
--group=<n>         Group bytes in sets of n (default: 1)
--no-ascii          Don't display ASCII representation
--no-offset         Don't display offset column
--color=<n>         Set color display mode
```

#### Number Format Options
```
(default: hex)      Display numbers in hexadecimal
--decimal           Display numbers in decimal
--octal             Display numbers in octal
--binary            Display numbers in binary
```

#### Data Selection
```
--limit=<n>         Limit the number of bytes displayed
--skip=<n>          Skip first n bytes of input
```

#### Pattern Matching
```
--highlight=<hex>   Highlight specific byte sequences (can be used multiple times)
```

### Examples

#### Basic File Analysis
```bash
# Display a file in default hexadecimal format
zzd sequence.bin
zig-out\bin\zzd zzd sequence.bin
zig-out/bin/zzd zzd sequence.bin

# Display with custom line length and grouping
zzd sequence.bin --line-length=32 --group=4
zig-out\bin\zzd zzd sequence.bin --line-length=32 --group=4
zig-out/bin/zzd zzd sequence.bin --line-length=32 --group=4

# Show only decimal values without ASCII
zzd sequence.bin --decimal --no-ascii
zig-out\bin\zzd zzd sequence.bin --decimal --no-ascii
zig-out/bin/zzd zzd sequence.bin --decimal --no-ascii
```

#### Advanced Usage
```bash
# Skip first 100 bytes and limit output to 500 bytes
zzd large_file.bin --skip=100 --limit=500
zig-out\bin\zzd zzd large_file.bin --skip=100 --limit=500
zig-out/bin/zzd zzd large_file.bin --skip=100 --limit=500

# Highlight specific byte patterns
zzd firmware.bin --highlight=FF00 --highlight=A5
zig-out\bin\zzd zzd firmware.bin --highlight=FF00 --highlight=A5
zig-out/bin/zzd zzd firmware.bin --highlight=FF00 --highlight=A5

# Custom formatting with binary output
zzd data.bin --binary --line-length=8 --group=4
zig-out\bin\zzd zzd data.bin --binary --line-length=8 --group=4
zig-out/bin/zzd zzd data.bin --binary --line-length=8 --group=4
```
