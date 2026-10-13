<p align="center">
  <img src="https://avatars.githubusercontent.com/u/309081559" height="80" alt="Carbon Services Project Logo"/>
</p>

<h1 align="center">Carbon Engine</h1>

<p align="center">
  <strong>Native, Air-Gapped C++ Engine & Desktop Client for Statutory ESG & BRSR Compliance Analytics</strong>
</p>

<p align="center">
  <a href="https://github.com/carbonservices/carbon-engine"><img src="https://img.shields.io/badge/Language-C%2B%2B20-blue.svg" alt="C++20"/></a>
  <a href="https://www.qt.io/"><img src="https://img.shields.io/badge/GUI-Qt%206.10%20(Quick%20%2F%20QML)-41cd52.svg" alt="Qt 6.10"/></a>
  <a href="https://github.com/ggerganov/llama.cpp"><img src="https://img.shields.io/badge/Inference-llama.cpp%20(CUDA%20%2F%20CPU)-orange.svg" alt="llama.cpp"/></a>
  <a href="https://github.com/facebookresearch/faiss"><img src="https://img.shields.io/badge/Vector%20Search-FAISS-blueviolet.svg" alt="FAISS"/></a>
  <a href="https://sqlite.org/"><img src="https://img.shields.io/badge/Storage-SQLite%20WAL-003B57.svg" alt="SQLite WAL"/></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-GPLv3-blue.svg" alt="License: GPLv3"/></a>
  <a href="#contributing"><img src="https://img.shields.io/badge/PRs-welcome-brightgreen.svg" alt="PRs Welcome"/></a>
</p>

<p align="center">
  <img src="docs/carbon-engine.gif" width="940" alt="Carbon Engine Desktop Client Workspace Demo"/>
  <br/>
  <em>Carbon Engine Desktop Workspace: Real-time local extraction tracking, statutory gap cataloging, and live GPU/CPU telemetry.</em>
</p>


## Table of Contents

- [Overview](#overview)
- [Key Features](#key-features)
- [Architecture](#architecture)
- [System Requirements](#system-requirements)
  - [Hardware Requirements](#hardware-requirements)
  - [Software Toolchain](#software-toolchain)
- [Build & Installation](#build--installation)
  - [1. Clone Repository](#1-clone-repository)
  - [2. Build from Source](#2-build-from-source)
- [Quick Start](#quick-start)
- [Google Cloud & Gemini Setup](#google-cloud--gemini-setup)
- [Contributing](#contributing)
- [License](#license)


## Overview

Carbon Engine is an on-device, air-gapped C++ engine and Qt desktop client for statutory ESG reporting (SEBI BRSR, BRSR Core, GRI). It ingests corporate annual reports locally, extracts compliance metrics using local LLMs and vector search with zero cloud telemetry, and generates audit-ready reports.

Most cloud AI services require uploading sensitive financial binders to third-party APIs. For public corporations handling Unpublished Price Sensitive Information (UPSI), Carbon Engine eliminates data leakage risks by keeping 100% of data and compute on the local machine.


## Key Features

- **100% Air-Gapped**: Runs entirely on local hardware with zero outbound network calls or telemetry.
- **Fast Document Ingestion**: Native PDF text extraction with OCR fallback for scanned pages.
- **Hardware-Accelerated AI**: [llama.cpp](https://github.com/ggerganov/llama.cpp) (GPU / CPU acceleration) & [FAISS](https://github.com/facebookresearch/faiss) vector search for embeddings and extraction.
- **Targeted Statutory Extraction**: Extracts and maps metrics directly to official SEBI BRSR sections and principles.
- **Fault-Tolerant Processing**: Built-in sanitization to handle model token cutoffs and formatting anomalies.
- **Consultant Desktop UI**: Qt Quick desktop application with editor support and device telemetry.
- **Audit-Ready Reports**: Exports standalone HTML and PDF reports with interactive charts.


## Architecture

The engine decouples document processing and model inference from the desktop interface via a lightweight local background daemon:

<p align="center">
  <img src="docs/high_level_architecture.drawio.svg" width="940" alt="Carbon Engine Client-Server Architecture and Libraries"/>
  <br/>
  <em>Client-server communication over local REST and internal engine library architecture.</em>
</p>

Detailed technical diagrams are available in `docs/`:
- **[System Architecture](docs/architecture.drawio.svg)** - Multi-layer ingestion, chunking, [FAISS](https://github.com/facebookresearch/faiss) vector indexing, & local [llama.cpp](https://github.com/ggerganov/llama.cpp) inference.
- **[Database Schema](docs/database_schema.drawio.svg)** - SQLite WAL relational tables, foreign key cascades, and embedding BLOB durability.
- **[Statutory Extraction Pipeline](docs/extraction_pipeline.drawio.svg)** - Two-tier scoped retrieval, context budgeting.


## System Requirements

### Hardware Requirements

| Component | Minimum | Recommended |
|---|---|---|
| **Processor** | 64-bit multi-core CPU (4+ cores) | Modern 8-core CPU |
| **Memory (RAM)** | 16 GB | 32 GB or more |
| **Graphics (GPU)** | *(Optional)* CPU-only mode supported | Dedicated NVIDIA GPU (6 GB+ VRAM) |
| **Storage** | 10 GB available space | SSD with 20 GB available space |

### Software Prerequisites

| Component | Requirement | Purpose |
|---|---|---|
| **Operating System** | Windows 10/11 (64-bit) or Linux (Ubuntu 22.04+) | Host platform |
| **C++ Toolchain** | MSVC 2022 / GCC 11+ / Clang 14+ (C++20) | Compilation |
| **CMake** | 3.24 or newer | Build configuration |
| **Qt 6** | Qt 6.10 or newer | Application framework & UI |
| **CUDA Toolkit** | *(Optional)* CUDA 12.x | GPU acceleration |


## Build & Installation

### 1. Clone Repository

```bash
git clone https://github.com/carbonservices/carbon-engine.git
cd carbon-engine
```

### 2. Build from Source

Third-party dependencies and local GGUF models are automatically fetched and configured via CMake.

#### Windows (Visual Studio 2022 & Qt 6)

```powershell
cmake -S . -B __Builds/x64/_build -G "Visual Studio 17 2022" -A x64 `
      -DCMAKE_PREFIX_PATH="C:/Qt/6.10.0/msvc2022_64"

cmake --build __Builds/x64/_build --config Release --target carbon-engine --target carbon-engine-client
```

Binaries are placed in `__Builds/x64/bin/`:
- `carbon-engine.exe` - Background daemon
- `carbon-engine-client.exe` - Desktop application


## Quick Start

### 1. Start the Engine Daemon
```powershell
./__Builds/x64/bin/carbon-engine.exe
```
The daemon initializes local models and listens on `http://localhost:8080`.

### 2. Launch the Desktop Client
```powershell
./__Builds/x64/bin/carbon-engine-client.exe
```

### Workflow
1. **Stage Documents**: Drop corporate annual report PDFs into the staging panel.
2. **Run Extraction**: Track live section extraction and system telemetry.
3. **Review & Edit**: Inspect extracted fields, verify page citations, and edit tabular grids directly.
4. **Lock & Export**: Finalize disclosures and export audit-ready HTML/PDF reports.


## Google Cloud & Gemini Setup

### 1. Get an API Key
Generate a free API key at [Google AI Studio](https://aistudio.google.com/) via **Get API key**.

### 2. Configure in Desktop Client
1. In the desktop client, open **Settings**.
2. Toggle **Google Cloud Processing** to **ON**.
3. Enter your **Gemini API Key** (the client automatically loads available models from Google AI Studio).
4. Click **Test Cloud Connection**, then click **Save**.


## Contributing

We welcome open-source contributions! Please review our [Contributing Guide](CONTRIBUTING.md) before starting.

- **Discuss First**: Open an issue to discuss design and approach before submitting a PR for new features.
- **Standards**: Follow modern C++20 conventions, RAII practices, and format code with `.clang-format`.
- **Policies**: Adhere to our [Code of Conduct](CODE_OF_CONDUCT.md) and [Security Policy](SECURITY.md).


## License

This project is licensed under the [GNU General Public License v3.0 (GPLv3)](LICENSE).


<p align="center">
  Built with ❤️ for a transparent, sustainable, and data-driven future.
</p>
