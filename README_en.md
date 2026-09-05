# Codex Capture Compat

[简体中文](README.md) | [English](README_en.md)

A screenshot compatibility layer for Codex Computer Use on Windows 10. The project builds a local x64 `version.dll` that supplies a missing capture border interface and changes where screenshot callbacks run in the existing Computer Use helper.

After installation, use Computer Use as usual. No separate proxy process or additional MCP service is required. This is an independent compatibility implementation and does not include the official helper's source code.

## Features

- **Capture border compatibility:** Handles `IsBorderRequired` property calls when the system lacks `IGraphicsCaptureSession3`, preserving the default Windows capture border.
- **Screenshot callback dispatch:** Sends eligible `FrameArrived` callbacks to MTA workers in the Windows thread pool, avoiding blocking waits for image conversion inside Windows Graphics Capture (WGC) callbacks.
- **Local installation and removal:** Installs the DLL and an installation record beside the helper. Removal verifies the recorded path and DLL hash.
- **Development tools:** Includes COM unit tests, a probe for real WGC capture, a standalone test window, and optional call tracing.

The project targets Windows 10 x64. Compatibility hooks are enabled for `codex-computer-use.exe` and the test program `compat_probe.exe`. Changes are confined to processes that load the DLL; system DLLs are not modified and no global hooks are registered.

## Quick start

Open PowerShell in the project root:

```powershell
Set-Location .\capture-compat
.\build.ps1
.\tests\install_tests.ps1
.\validate.ps1
```

Building requires the MSVC x64 C++ tools, MASM, and the Windows SDK. Live capture tests require a logged-in, unlocked Windows 10 interactive desktop. See the [build and usage guide (Chinese)](capture-compat/README.md) for toolchain requirements and build options.

Build outputs are written to `capture-compat/dist/`:

| Artifact | Purpose |
| --- | --- |
| `version.dll` | Compatibility layer to install beside the Computer Use helper |
| `compat_probe.exe` | Tests the border interface, real capture, and asynchronous callbacks |
| `capture_test_window.exe` | Standalone window for testing screenshots through Computer Use |

Building and running the probe do not automatically install or update the DLL in the runtime directory.

## Usage

### Installation

Locate the `codex-computer-use.exe` used by your Computer Use runtime. Replace the placeholder path below with its actual path.

Run these commands from the `capture-compat` directory:

```powershell
$helperPath = 'C:\path\to\codex-computer-use.exe'

# Preview the installation target
.\install.ps1 -HelperPath $helperPath -WhatIf

# Exit the running helper before installing
.\install.ps1 -HelperPath $helperPath -Action Install
```

Restart Computer Use so that the helper loads the new DLL. Install beside the helper, rather than beside the main desktop application or in a Windows system directory.

The installer adds `version.dll` and `codex-capture-compat.install.json`. It does not modify the helper executable or stop running processes.

### Verify operation

Open `dist/capture_test_window.exe`, select that window through Computer Use, and take a screenshot. Check the image, then test repeated screenshots and window resizing. You can close the test window manually; it also exits automatically after ten minutes.

A passing probe confirms the tested compatibility paths. Operation through the official helper must also be verified. See the [validation and troubleshooting guide (Chinese)](capture-compat/docs/validation.md) for the full procedure.

### Upgrade and uninstall

To upgrade, build the new version and exit any helper using the installed DLL. Then run:

```powershell
.\install.ps1 -HelperPath $helperPath -Action Uninstall
.\install.ps1 -HelperPath $helperPath -Action Install
```

To remove the compatibility layer, run only the uninstall command and restart Computer Use. The script refuses to overwrite a different existing DLL. Removal checks the helper path and installed DLL hash against the installation record.

The helper directory may change after a Codex update. Check the actual path again before installing. See the [build and usage guide (Chinese)](capture-compat/README.md) for the complete installation rules.

## Implementation overview

```text
Computer Use helper
  └─ Local version.dll
      ├─ System version exports → Original DLL in System32
      └─ RoGetActivationFactory import hook
          └─ WGC frame pools and capture sessions
              ├─ Missing border property interface → Compatibility interface
              └─ Eligible frame events → MTA thread pool workers
```

`SetIsBorderRequired` is a WinRT/COM property operation, not a `version.dll` export. The DLL serves as the loading entry point and forwards system version exports. The capture compatibility logic hooks interface queries and event subscriptions on WGC objects.

The border fallback applies only when the native interface query returns `E_NOINTERFACE`. Asynchronous dispatch also requires a frame pool without a `DispatcherQueue` and a callback that supports invocation across threads. See the [implementation guide (Chinese)](capture-compat/docs/implementation.md) for event cancellation, object lifetime, and error handling details.

## Project structure

```text
capture-compat/
├─ README.md              Build and usage guide (Chinese)
├─ build.ps1              Builds the DLL and tools; runs unit tests
├─ install.ps1            Installation, removal, and file verification
├─ validate.ps1           Live Windows 10 regression tests
├─ src/                   DLL proxy, COM hooks, and callback dispatch
├─ tests/                 Unit tests, capture probe, and test window
├─ docs/                  Implementation, validation, and troubleshooting
├─ build/                 Intermediate build files (generated)
├─ dist/                  Deployable artifacts (generated)
└─ validation/            Test reports and captured images (generated)
```

The project's `.gitignore` excludes `build/`, `dist/`, and `validation/`. These directories may not exist in a fresh source checkout.

## Scope and compatibility

- Only x64 builds are provided, targeting helpers that use Windows Graphics Capture.
- The helper must allow loading a local `version.dll` and directly import `RoGetActivationFactory` in its main EXE.
- Compatibility behavior is selected by actual interface support. It does not change the reported Windows version or capture permissions.
- Windows 11, other helper builds, and different graphics environments require separate validation. This layer does not address every possible screenshot failure.
- The DLL is unsigned. Asynchronous dispatch changes the callback thread and the timing of error returns; see the [implementation guide (Chinese)](capture-compat/docs/implementation.md) for the constraints.

## Documentation

The detailed guides are currently available in Chinese:

- [Build and usage](capture-compat/README.md)
- [Implementation](capture-compat/docs/implementation.md)
- [Validation and troubleshooting](capture-compat/docs/validation.md)

## License

This project is licensed under [WTFPL v2](https://www.wtfpl.net/about/). See [LICENSE](LICENSE) for the full text.
