# CM-STACK — Simulink Compiler with Native XCP

> **One script. One Raspberry Pi. Real XCP. No black magic.**

This repo wires [Vector XCPlite](https://github.com/vectorgrp/XCPlite) straight into the Simulink code-generation and cross-compilation flow for Raspberry Pi.

No manual Makefile surgery.  
No hand-patching A2L files at 2 a.m.  
No toolchain acrobatics.  

Run the script, deploy to the Pi, connect with **INCA** or **CANape** or any other calibration tool supporting XCP over TCP, and start measuring.

Originally built around [CM-STACK](https://github.com/fupsrl/CM-STACK), but useful anywhere you want **model-based development on Raspberry Pi with proper automotive-grade measurement and calibration**.

> **Also: no heavy, sluggish, proprietary Simulink External Mode nonsense.**

---

## Why this repo exists

The usual Simulink-to-target workflow gets ugly fast when you want actual XCP-based measurement and calibration on an embedded Linux target.

This repo fixes that.

It gives you a workflow that is:

- **scriptable**
- **repeatable**
- **transparent**
- **automotive-tool friendly**
- **much less painful than the default way**

The goal is simple: take a Simulink model, build it, cross-compile it on Raspberry Pi, generate the right calibration artifacts, and make it ready for **INCA** or **CANape** without a pile of manual cleanup.

---

## What it does

```text
Simulink model  ──►  slbuild  ──►  cross-compile on Raspberry Pi  ──►  XCP-enabled executable
                                                                              │
                                                 A2L (INCA / CANape ready) ◄──┤
                                                 HEX / S19 artifacts        ◄──┤
                                                 Optional CDFX patching     ◄──┘
```

---

## Features

- **One-command build / deploy / run**  
  Generates ERT C code, pushes everything to the Raspberry Pi over SSH, launches the remote build, and pulls the artifacts back to your machine.

- **Native XCPlite integration**  
  The full Vector XCPlite stack is linked directly into the executable. No weird wrappers, no fake “support”, no feature amputation.

- **A2L generation that does not suck**  
  Produces an A2L ready for **INCA** and **CANape**, including display formats, event names, EPK address, memory segments, and lookup-table axis definitions.

- **HEX / S19 artifact generation**  
  Creates Intel HEX and Motorola S19 calibration files using address ranges extracted from the ELF.

- **Optional CDFX patching**  
  Can patch an existing CDFX so calibration names stay aligned with the patched A2L.

- **Multi-core scheduling**  
  Model tasks and the XCP server can be pinned to different CPU cores via configurable core masks.

- **Built for real workflows**  
  This is not a toy demo. It is meant to slot into actual development loops.

---

## Known Issues

| Item | Details |
|---|---|
| HEX file export | Currently bugged. HEX is not fully working yet. Upload calibration from INCA for now. |
| Working / Reference page flashing to target | Work in progress. |

---

## Requirements

| Item | Details |
|---|---|
| MATLAB / Simulink | R2024b tested |
| Embedded Coder | Required for C code generation |
| Raspberry Pi | Any 64-bit model (tested on RPi 4 and RPi 5) |
| SSH access | Password or key-based; `sshpass` or native OpenSSH |
| Toolchain | GCC aarch64 toolchain available on the Raspberry Pi side |

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

### Minimal call — build, deploy, and run in one shot

```matlab
run_native_xcp_workflow("MyModel", ...
    "RaspberryHost", "192.168.1.10", ...
    "RaspberryUser", "pi")
```

### With SSH password and host-key pinning

```matlab
run_native_xcp_workflow("MyModel", ...
    "RaspberryHost",  "192.168.1.10", ...
    "RaspberryUser",  "pi", ...
    "SSHPassword",    "raspberry", ...
    "SSHHostKey",     "ssh-ed25519 255 SHA256:xxxx...")
```

### Custom CPU core assignment

Model on cores 1–2, XCP server on core 3:

```matlab
run_native_xcp_workflow("MyModel", ...
    "RaspberryHost", "192.168.1.10", ...
    "ModelCores",    [1 2], ...
    "XcpCore",       3)
```

### Skip rebuild and reuse existing generated code

```matlab
run_native_xcp_workflow("MyModel", ...
    "RaspberryHost", "192.168.1.10", ...
    "BuildModel",    false)
```

### Deploy without launching the executable

```matlab
run_native_xcp_workflow("MyModel", ...
    "RaspberryHost", "192.168.1.10", ...
    "RunExecutable", false)
```

### Inject base-workspace calibration parameters before build

```matlab
run_native_xcp_workflow("MyModel", ...
    "RaspberryHost",          "192.168.1.10", ...
    "BaseWorkspaceVariables", struct("Kp", 1.2, "Ti", 0.05))
```

### Enable verbose calibration debug output

```matlab
run_native_xcp_workflow("MyModel", ...
    "RaspberryHost",            "192.168.1.10", ...
    "EnableCalibrationDebug",   true)
```

---

## Output artifacts

After a successful run, `result` contains:

| Field | Description |
|---|---|
| `result.LocalHex` | INCA-compatible Intel HEX |
| `result.LocalS19` | INCA-compatible Motorola S19 |
| `result.LocalIncaA2L` | Patched A2L ready for INCA / CANape import |
| `result.LocalIncaCdfx` | Patched CDFX, if a source CDFX was found |
| `result.ExecutableRemotePath` | Path to the running binary on the Raspberry Pi |
| `result.RemotePid` | PID of the launched process |

---

## XCP connection (CANape / INCA)

| Parameter | Default |
|---|---|
| Transport | TCP |
| Port | `5555` |
| Address | `RaspberryHost` value (or `AdvertisedAddress`, if configured) |
| Bind address | `0.0.0.0` (configurable via `XcpBindAddress`) |

The XCP server starts automatically when the executable launches.

Import the generated **A2L** and **HEX** into your tool, connect, and start measuring.

For setup notes, see [INCASetup.md](https://github.com/fupsrl/CM-STACK-Simulink-Compiler/blob/main/INCASetup.md).

---

## Simulink model setup

Before running the workflow, set up the model like this:

- **Hardware implementation** → Raspberry Pi (64-bit)
- **Target Hardware Resources → Board Parameters** → configure Raspberry Pi IP, username, and password
- **Code Generation → Optimization** → set default parameter behavior to **Tunable**  
  or manually mark parameters as tunable where needed
- **Code Generation → Interface** → enable generated C API for:
  - signals
  - parameters
  - states
  - root-level I/O

### To log signals through XCP

Give the signal a name, then:

**Right click → Properties → enable `Test Point`**

After these settings, just run:

```matlab
runAndBuildModel.m
```

---

## Why this is nicer than External Mode

Because you get:

- actual XCP workflows
- proper calibration artifacts
- compatibility with the tools people already use
- less latency
- less vendor lock-in
- less “why is this hidden behind six menus and a proprietary checkbox?”

---

## License

See [LICENSE.txt](LICENSE.txt).

---

## Notes

This repository has been cleaned up and refactored with help from LLMs.

Some critical workflow details are intentionally not fully exposed.  
That is a deliberate choice to make a little bit more difficult to reverse engineering it for MathWorks.

---

## Final vibe check

If your desired workflow is:

> **build model → deploy to Pi → connect INCA/CANape → calibrate like a civilized person**

that is exactly what this repo is for.
