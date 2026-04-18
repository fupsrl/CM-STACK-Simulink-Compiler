# CM-STACK — Simulink Compiler with Native XCP

> **One script. Raspberry Pi. Full XCP measurement & calibration.**

This repo integrates [Vector XCPlite](https://github.com/vectorgrp/XCPlite) directly into the Simulink code-generation and cross-compilation workflow for Raspberry Pi — no manual Makefile editing, no manual A2L patching, no toolchain gymnastics. Run the script, connect CANape or INCA, start measuring.
The repo hosts the workflow for programming a raspberry Pi with Simulink and model-based approach and be compatibile with the automotive tool for measurement and calibration. The main application is developing algorithms for [CM-STACK](https://github.com/fupsrl/CM-STACK) but it can be used in many other projects.

---

## What it does

```
Simulink model  ──►  slbuild  ──►  cross-compile on RPi  ──►  XCP-enabled executable
                                                                        │
                                           A2L (INCA-ready) ◄───────────┘
                                           HEX / S19 artifacts
```

- **Automated build & deploy** — generates ERT C code, copies the bundle to the Raspberry Pi over SSH, triggers the remote `make`, and fetches the artifacts back to your PC.
- **Native XCPlite integration** — the full Vector XCPlite stack is linked into the binary; all original XCPlite commands and transport-layer options are preserved and configurable.
- **A2L generation & patching** — produces a clean A2L file ready for direct import into **INCA** and **CANape**, including correct display formats, event names, EPK address, memory segments, and lookup-table axis definitions.
- **HEX / S19 artifacts** — generates INCA-compatible Intel HEX and Motorola S19 files with correct address ranges extracted from the ELF.
- **CDFX calibration data** — optionally patches an existing CDFX file to align calibration names with the patched A2L.
- **Multi-core scheduling** — model tasks and the XCP server are pinned to independent CPU cores via configurable core masks.

---

## Requirements

| Item | Details |
|---|---|
| MATLAB / Simulink | R2024b tested |
| Embedded Coder | Required for C code generation |
| Raspberry Pi | Any 64-bit model (tested on RPi 4 & 5) |
| SSH access | Password or key-based, `sshpass` or native OpenSSH |
| MATLAB on RPi | Cross-compiler toolchain (GCC aarch64) |

---

## Quick start

```matlab
% 1. Add the workflow folder to your MATLAB path
addpath("path/to/CM-STACK/workflow/matlab")

% 2. Run the workflow
result = run_native_xcp_workflow("MyModel", ...
    "RaspberryHost", "192.168.1.10", ...
    "RaspberryUser", "pi");
```

---

## Usage

- **Minimal call — build, deploy and run in one shot:**
  ```matlab
  run_native_xcp_workflow("MyModel", ...
      "RaspberryHost", "192.168.1.10", ...
      "RaspberryUser", "pi")
  ```

- **With SSH password and host-key pinning:**
  ```matlab
  run_native_xcp_workflow("MyModel", ...
      "RaspberryHost",  "192.168.1.10", ...
      "RaspberryUser",  "pi", ...
      "SSHPassword",    "raspberry", ...
      "SSHHostKey",     "ssh-ed25519 255 SHA256:xxxx...")
  ```

- **Custom CPU core assignment (model on cores 1-2, XCP server on core 3):**
  ```matlab
  run_native_xcp_workflow("MyModel", ...
      "RaspberryHost", "192.168.1.10", ...
      "ModelCores",    [1 2], ...
      "XcpCore",       3)
  ```

- **Skip rebuild, reuse existing generated code:**
  ```matlab
  run_native_xcp_workflow("MyModel", ...
      "RaspberryHost", "192.168.1.10", ...
      "BuildModel",    false)
  ```

- **Run without launching the executable (deploy only):**
  ```matlab
  run_native_xcp_workflow("MyModel", ...
      "RaspberryHost",    "192.168.1.10", ...
      "RunExecutable",    false)
  ```

- **Pass base-workspace calibration parameters before build:**
  ```matlab
  run_native_xcp_workflow("MyModel", ...
      "RaspberryHost",           "192.168.1.10", ...
      "BaseWorkspaceVariables",  struct("Kp", 1.2, "Ti", 0.05))
  ```

- **Enable calibration debug output (verbose A2L patching log):**
  ```matlab
  run_native_xcp_workflow("MyModel", ...
      "RaspberryHost",         "192.168.1.10", ...
      "EnableCalibrationDebug", true)
  ```

---

## Output artifacts

After a successful run `result` contains:

| Field | Description |
|---|---|
| `result.LocalHex` | INCA-compatible Intel HEX |
| `result.LocalS19` | INCA-compatible Motorola S19 |
| `result.LocalIncaA2L` | Patched A2L ready for INCA / CANape import |
| `result.LocalIncaCdfx` | Patched CDFX (if a source CDFX was found) |
| `result.ExecutableRemotePath` | Path of the running binary on the Raspberry Pi |
| `result.RemotePid` | PID of the launched process |

---

## XCP connection (CANape / INCA)

| Parameter | Default |
|---|---|
| Transport | TCP |
| Port | `5555` |
| Address | `RaspberryHost` value (configurable via `AdvertisedAddress`) |
| Bind address | `0.0.0.0` (configurable via `XcpBindAddress`) |

The XCP server starts automatically when the executable launches. Import the generated A2L and HEX into your tool and connect [INCA SETUP](https://github.com/fupsrl/CM-STACK-Simulink-Compiler/blob/main/INCASetup.md)

---

## Simulink model setup:

- **Hardware implementation** — Choose Raspberry pi (64bit).
- **Hardware implementation > Target Hardware Resources > Board Parameters** — set up ip, user and password for SSH to your raspberry.
- **Code generation > Optimization** — default parameter behavior: Tunable (or setup manually parameter by parameter).
- **Code generation > Interface** — generate C API for: &#x2611; signals &#x2611; parameters - states - root-level I/O.

- **To log signals with XCP** — name your signal, right click on it: Properties> &#x2611; Test Point

After this settings, simply run runAndBuildModel.m

---

## License

See [LICENSE.txt](LICENSE.txt).<br />
Code cleaned and refactored with LLMs<br />
Critical workflow obscured because I do not want that Mathworks steals years of work just for free<br />
