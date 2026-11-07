# SteamFlow Recorder — Steam Frame improvements

This repository is a fork of [MWGIH/SFRecorder](https://github.com/MWGIH/SFRecorder) (GPL-3.0-only).
It retains the original Rust recording engine and uses the upstream prebuilt recording binary; the improvements below are to installation and the SteamVR dashboard. Credit and licensing for the original author remain intact.

## Hey Frame voice integration (SteamFlow fork)

This fork now supports **Hey Frame** voice commands through a user-private local UNIX socket in the existing SteamVR recorder dashboard, so Hey Frame never launches a second recording engine.

After updating **both** [Hey Frame](https://github.com/SteamFlowYT/HeyFrame) and this SFRecorder fork, say:

- **"Hey Frame, start recording"** to begin a recording with the current dashboard settings.
- **"Hey Frame, stop recording"** to finish and save the current video.
- **"Hey Frame, recording status"** to hear whether recording is active or paused.

There is also a **Hey Frame** Listening / Off toggle inside the recorder's SteamVR dashboard. It enables or disables the separate Hey Frame user service and remembers the choice at future user logins. It refuses to enable listening while the older `frame-dictation.service` is running, to avoid known Volume Up input grabs. No hardware button events are intercepted or changed.

The recorder continues to pause whenever its dashboard tab is visible. Speak "start recording" after closing that tab if you want to capture footage immediately; otherwise it will start paused. The recording control socket exists only when the recorder's dashboard process is running, and is accessible only to the headset user.

**Safety:** The voice bridge only accepts `start`, `stop` and `status`. It never accepts shell commands, never starts a second capture process, and inherits SFRecorder's low-storage safety checks and file-saving logic. Actual voice and dashboard use must still be validated on Steam Frame hardware.

## One-command install or update on Steam Frame

Open Konsole on the **Steam Frame itself** (not a Windows terminal) and run:

```bash
curl -fsSL https://raw.githubusercontent.com/SteamFlowYT/SFRecorder/main/steamflow-bootstrap.sh | bash
```

The bootstrap clones into `~/SteamFlowRecorder`, rather than overwriting an existing `~/SFRecorder` source checkout. The installer **does** replace the existing SFRecorder service, dashboard and binary in the normal per-user installation locations. It preserves recordings in `~/Videos/SFRecorder` and existing config in `~/.config/sfrecorder`. As in upstream, the helper requests privileged capability for reading headset panels.

**SteamFlow additions:**
- Repair broken/missing `pip` in the recorder's private Python environment (uses `ensurepip`, falling back to official PyPA over HTTPS).
- Verify Python modules before finishing setup.
- Prevent starting new recordings below 1 GiB free, and request a clean recording stop below 256 MiB (checked about every five seconds).
- Display remaining storage in the VR dashboard; provide a tap-to-reset height control.
- Read-only diagnostic script:
  ```bash
  bash ~/SteamFlowRecorder/scripts/steamflow-doctor.sh
  ```

**60 FPS capture cap (source change, awaiting a fork-built binary):** The Rust engine now defaults to a 60 FPS recording cap (custom CLI `--max-fps 90` retains the previous rate). Fractional frame pacing preserves 60 FPS on a 90 Hz headset instead of dropping to 45 FPS, skipping work **before GPU conversion and HEVC encoding**. Audio and MP4 timestamps still use the original clock. For modes above 60 Hz that are not multiples of 60, frame intervals can alternate; there is no interpolation and no guarantee of a specific gaming-performance improvement. The headset's own refresh rate is unchanged.

**Build needed before this affects recordings:** Your GitHub fork currently has no published recorder releases. In GitHub, open **Actions**, enable workflows for this fork if prompted, select **Release**, select **Run workflow** on main and set its `tag` input to `v0.2.0` (not the default `test`, which publishes only a pre-release). When the build finishes successfully and publishes `sfrecorder-aarch64.tar.gz` to a release, rerun the one-line install command above. Until that release exists, the installer intentionally falls back to the known-working upstream recorder binary, which still uses its original FPS behavior.

To confirm the new binary is actually in use, start and stop a short recording, then read `~/.cache/sfrecorder/last-recording.log`. Its startup line will say `at up to 60.00 fps`, including the panel refresh rate.

**Current limitations:** The 60 FPS source change has been checked with timing simulations but is not yet compiled and tested on actual Steam Frame hardware. No instant replay, independent mic track, or new hardware encoder modes are claimed. Storage safeguards are best-effort and cannot guarantee protection against a full disk.

---

## Original SFRecorder documentation

# SFRecorder

Records what the Steam Frame's panels show, Steam overlays included, with as
little cost to the game as possible. Start and stop it from its own tab in the
SteamVR dashboard.

> **Status: early version.** Recording, audio and the FPS overlay work on the
> Steam Frame; levelling the 16:9 picture is still being checked.

## Install

```sh
cd ~ && (git clone https://github.com/MWGIH/SFRecorder.git || git -C SFRecorder pull) && SFRecorder/install.sh
```

SFrameOverlay (the FPS HUD) is a separate app with its own repo. To get its HUD
in recordings, install it from there:

```sh
cd ~ && (git clone https://github.com/MWGIH/SFrameOverlay.git || git -C SFrameOverlay pull) && SFrameOverlay/install.sh
```

The installer asks for your password once, to let the recorder read the panels.

## Uninstall

Press **Uninstall** in the SFRecorder tab (twice, to confirm), or run:

```sh
~/.local/share/sfrecorder/uninstall.sh
```

If that file is already gone (a broken install), run `~/SFRecorder/uninstall.sh`
instead. It removes the tab and its service, the recorder, its settings and logs,
and the `~/SFRecorder` folder the install line downloaded (unless you changed
files in it). Your recordings in `~/Videos/SFRecorder` are kept.

## Test builds

For trying changes before they reach `main`. Run these in a terminal on the
Frame. They use the `claude/project-thread-vjosj1` branch and the `test`
pre-release.

**1. Mirror test** (no password, installs nothing). Start a game, turn the FPS
overlay on and open a Steam overlay, then run:

```sh
cd ~ && (git clone -b claude/project-thread-vjosj1 https://github.com/MWGIH/SFRecorder.git || git -C SFRecorder pull) && SFRecorder/scripts/probe-mirror.sh
```

It saves `mirror-test-left.bmp` and `mirror-test-right.bmp` in `~/Videos/SFRecorder`.

**Diagnose** (after installing). With a VR game running, this tests each step
of recording on its own and prints what happened:

```sh
~/.local/bin/sfrecorder --diagnose
```

It checks the eye picked in VR View; `sfrecorder --eye right --diagnose` (or
`--eye left`) checks the other one.

It also saves what the GPU made of the screen as `diagnose-frame.bmp` (the
16:9 view) and `diagnose-raw.bmp` (both panels, no framing) in
`~/Videos/SFRecorder`. If only the 16:9 one is black, the framing is wrong; if
both are, the GPU reads the panel's buffer as black.

**2. Install the test version.** To go back to normal releases, run
`git -C ~/SFRecorder checkout main` and then the Install line above.

```sh
cd ~ && (git clone -b claude/project-thread-vjosj1 https://github.com/MWGIH/SFRecorder.git || git -C SFRecorder pull) && SFRECORDER_TAG=test SFRecorder/install.sh
```

## The SFRecorder tab

| Option | What it does |
| --- | --- |
| **Record / Stop** | Starts and stops a recording. Recording pauses on its own while this tab is open, so the menu never ends up in the video. |
| **Shape** | **16:9** (default) frames one eye like Steam's own recorder. **Raw** records both panels exactly as shown; it asks you to confirm the first time and then shows ⚠ next to Shape. |
| **Eye** | Left or right for 16:9. It follows the eye picked in SteamVR's VR View window until you change it here; the **i** explains where that setting is. |
| **Microphone** | Off by default. When on, your voice is mixed into the game audio. |
| **Update** | Pulls the latest version from the folder the install line made and reinstalls. Not available while recording. It only asks for the password again (in a terminal) if the panel helper itself changed. |
| **FPS overlay** | Shows whether [SFrameOverlay](https://github.com/MWGIH/SFrameOverlay) is installed and on. When it is, choose whether its HUD is in recordings. Hiding it also hides it in the headset while recording, because the panels are recorded as shown. |

Game audio is always recorded. Recordings go to `~/Videos/SFRecorder` as
`SFRecorder_<date>_<time>.mp4` (HEVC + AAC). A file is only given its `.mp4`
name once it's finished; until then it's `.mp4.part`. Use
[SCopy](https://github.com/MWGIH/SCopy) to copy them to another device.

## How it works

```
panel scanout ──dmabuf──▶ one compute shader ──NV12──▶ hardware HEVC encoder ──▶ MP4
                          (crop + un-warp)              (V4L2)                    ▲
game audio (+ mic) ──────────────────────────────────────────────▶ AAC ───────────┘
```

- The compositor's on-screen buffer is borrowed, never copied. A tiny helper
  (`sfrecorder-grab`, the only part with extra rights) hands it over, and only
  for buffers that are on screen right now.
- One compute pass per frame reads it, removes the lens warp for 16:9 using
  SteamVR's own lens data (worked out once at start), and writes NV12 straight
  into the encoder's input buffer. The GPU queue runs at normal priority: on
  the Frame a low-priority queue never got a turn while a game was running.
- No pixels touch the CPU. The recorder only wakes on vblank.
- While recording, SFRecorder writes `$XDG_RUNTIME_DIR/sfrecorder/view.json`
  with the recorded view; SFrameOverlay uses it to keep its HUD inside the video
  (or hide it).

## Building

Needs Rust, `glslangValidator`, clang, and the headers for Vulkan, libdrm,
FFmpeg (libavcodec/libavformat) and libpulse.

```sh
cargo build --release
```

`install.sh` uses `target/release` when it exists, otherwise the latest release.

### FFmpeg

The recorder uses FFmpeg's libraries for the MP4 file and AAC audio. The
installer checks whether the recorder can load SteamOS's own copy. If it can't
(not installed, or a different version), it adds a small private copy to
`~/.local/lib/sfrecorder`, which the recorder looks in first. SteamOS's system
folders are read-only and reset by updates, so the installer never puts
anything there.

`scripts/build-ffmpeg.sh` builds that private copy (only the AAC encoder and
MP4 writer). Build release binaries against it so the versions match:

```sh
scripts/build-ffmpeg.sh
PKG_CONFIG_PATH=build/ffmpeg/lib/pkgconfig cargo build --release
```

### Releases

`.github/workflows/release.yml` builds the engine and the private FFmpeg for
the Frame (aarch64) on GitHub and attaches both to a release. Every push to
`main` publishes a new release (`v0.1.<build number>`), which `install.sh` and
the tab's Update button pick up. Pushes to the test branch update the `test`
pre-release. To
install a test build:

```sh
SFRECORDER_TAG=test SFRecorder/install.sh
```

## To check on the headset

- The 16:9 crop matches Steam's recorder and is level (canted panels).
- The encoder's input layout (NV12 vs NV12M, padded rows) and its largest size
  (Raw asks for 3840×1920).
- Whether SteamOS for the Frame has FFmpeg libraries the recorder can use, or
  the private copy gets installed.

## License

GPL-3.0-only. See [LICENSE](LICENSE).
