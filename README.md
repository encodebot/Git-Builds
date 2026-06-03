# Git-Builds
Git Builds For ARM64 & AMD64

# Automated Git Compiler

An optimized, cloud-native automation pipeline that monitors upstream kernel.org mirrors for stable Git releases and automatically builds highly portable, headless executable packages for **linux/amd64** and **linux/arm64** architectures.

---

## 🚀 Key Features

* **Native Multi-Architecture Compilation**: Avoids slow QEMU emulation overhead by utilizing GitHub’s native AMD64 and ARM64 runners.
* **Minimalistic & Highly Portable**: Compiled against critical system dependencies (`libssl-dev`, `libcurl4-openssl-dev`, `libexpat1-dev`, `zlib1g-dev`) with GUI tools disabled (`NO_TCLTK=1`) to maximize headless portability across various Linux environments.
* **Robust Docker Remote Caching**: Implements `--cache-to/from type=gha` layers to guarantee subsequent code builds complete within minutes.
* **Automatic Security Checksums**: Every build dynamically computes and attaches an authoritative `checksums.sha256` verification manifest to the GitHub Release.
* **Autonomous Pipeline Maintenance**: Integrated self-cleaning logic stores only the latest 4 production releases while automated keepalive protocols prevent GitHub Actions from sleeping.

---

## ⚙️ Automated Pipeline Policies

### 🕒 Build Schedule
* **Execution Interval**: Builds trigger automatically at **00:00 UTC on Mondays, Wednesdays, and Fridays**, as well as on manual execution via `workflow_dispatch`.
* **Smart Verification**: The compiler checks upstream kernel.org releases first, utilizing advanced RegEx to filter out beta/RC versions. A compilation run triggers **only** if a brand-new stable upstream version of Git is detected. If no updates exist, the workflow safely exits early to save system resources.

### 💻 Target Architectures
This project focuses explicitly on delivering high-performance, optimized **64-bit Linux environments**. 
* **Supported Architectures**: Native executable directory structures are compiled and packaged into `.tar.xz` archives for **linux/amd64** (`x86_64`) and **linux/arm64** (`aarch64`).
* **Non-Supported Environments**: There are no active automated builds for Windows or 32-bit platforms. However, you can use the provided standalone `Dockerfile` to manually compile your target configurations locally.

### 🗑️ Release Retention Policy
To prevent repository bloat while maintaining quick access to stable historical versions, the pipeline enforces a strict self-cleaning cycle:
* **The Last 4 Releases Are Kept**: The cleanup script evaluates the storage history on every successful release and retains exactly the **4 most recent production versions**.
* **Automatic Tag Purging**: Releases older than the top 4 are automatically removed along with their corresponding git repository tags.
* **Deterministic Version Tags**: Releases use explicit upstream version naming conventions (e.g., `v2.45.0`), allowing you to anchor your production scripts to unchanging, specific versions.

---

## 🛠️ Infrastructure Overview

```mermaid
graph TD
    A[Cron Schedule / Manual Dispatch] --> B{Version Check}
    B -- Upstream == Local Tag --> C[Skip Execution]
    B -- New Version Found --> D[Parallel Build Matrix]
    
    subgraph Build Platforms
    D --> E[linux/amd64 <br> ubuntu-latest]
    D --> F[linux/arm64 <br> ubuntu-24.04-arm]
    end
    
    E --> G[Generate Hashes <br> sha256sum]
    F --> G
    G --> H[GitHub Release <br> Publishes Assets & Purges Old Releases]
    
    style C fill:#f9f,stroke:#333,stroke-width:2px
    style H fill:#bbf,stroke:#333,stroke-width:2px