# Git-Builds
Git Builds For ARM64 & AMD64

# Automated Git Compiler

An optimized, cloud-native automation pipeline that monitors upstream kernel.org mirrors for stable Git releases and automatically builds highly portable, headless executable packages for **linux/amd64** and **linux/arm64** architectures.

---

## 🚀 Key Features

* **Native Multi-Architecture Compilation**: Avoids slow QEMU emulation overhead by utilizing GitHub’s native AMD64 and ARM64 runners.
* **Minimalistic & Highly Portable**: Compiled against critical system dependencies (`libssl-dev`, `libcurl4-openssl-dev`, `libexpat1-dev`, `zlib1g-dev`) with GUI tools disabled (`NO_TCLTK=1`) to maximize headless portability across various Linux environments.
<!-- ❌ Delete This Block Later, When Re-Enable Caching. ❌
* **Robust Docker Remote Caching**: Implements `--cache-to/from type=gha` layers to guarantee subsequent code builds complete within minutes. -->
* **Automatic Security Checksums**: Every build dynamically computes and attaches an authoritative `checksums.sha256` verification manifest to the GitHub Release.
* **Autonomous Pipeline Maintenance**: Integrated self-cleaning logic stores only the latest 4 production releases while automated keepalive protocols prevent GitHub Actions from sleeping.

---

## ⚙️ Automated Pipeline Policies

### 🕒 Build Schedule
* **Execution Interval**: Builds trigger automatically every week at **12:00 AM UTC On Mondays, Wednesdays & Fridays**, as well as on manual execution via `workflow_dispatch`.
* **Smart Verification**: The compiler checks upstream kernel.org releases first, utilizing advanced RegEx to filter out beta/RC versions. If a brand-new stable upstream version of `Git` is detected, a **Clean Build** is triggered. If no updates exist, the workflow automatically force-rebuilds the current version to apply the latest security patches to all bundled dependencies.

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
    B -- Upstream == Local Tag --> C[Force Rebuild <br> Security Updates]
    B -- New Version Found --> D[New Release <br> Clean Build]
    C --> M[Parallel Build Matrix]
    D --> M

    subgraph Build Platforms.
    M --> E[linux/amd64 <br> ubuntu-26.04]
    M --> F[linux/arm64 <br> ubuntu-26.04-arm]
    end

    E --> G[Generate Hashes <br> sha256sum]
    F --> G
    G --> H[Overwrites Old Tag <br> If Rebuilding]
    H --> I[Publishes Assets]
    I --> J[Purges Old Releases]

    style C fill:#ffeb99,stroke:#333,stroke-width:2px
    style D fill:#baffc9,stroke:#333,stroke-width:2px
    style H fill:#e3a6c3,stroke:#333,stroke-width:2px
    style I fill:#e3a6c3,stroke:#333,stroke-width:2px
    style J fill:#e3a6c3,stroke:#333,stroke-width:2px
```