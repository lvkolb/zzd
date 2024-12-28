# zzd

[![Zig](https://img.shields.io/badge/Made%20with-Zig-%23F7A41D)](https://ziglang.org)

A powerful hexdump utility built with Zig that helps you inspect binary content in a human-readable format. Perfect for developers who need to understand the underlying structure of files.

## Features

- Clean and intuitive hex dump output
- Fast performance with Zig's efficiency
- Cross-platform support (Windows, Linux, macOS)
- Simple command-line interface

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
zzd <filename>
```

### Platform-Specific Examples

#### Windows
```bash
zig-out\bin\zzd sequence.bin
```

#### Linux/macOS
```bash
zig-out/bin/zzd sequence.bin
```

### Example

To analyze a binary sequence file:
```bash
# Generate a sample binary file using the provided script
python generate_binary.dat.py

# Analyze the generated file
zzd sequence.bin
```
