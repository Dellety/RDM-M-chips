# RDM (Retina Display Menu)

A menu bar tool for switching MacBook Pro Retina displays to higher native
resolutions that Apple does not expose in System Settings.

**This fork** is a native **Apple Silicon (arm64)** port of RDM 2.2. The
upstream 2.2 binary is Intel-only (x86_64) and runs under Rosetta 2 on modern
Macs, which Apple is phasing out. This version is rebuilt natively for arm64 so
it runs without Rosetta on current macOS.

- Architecture: **arm64** (native Apple Silicon)
- Language: Objective-C++ (unchanged from upstream)
- macOS deployment target: 11.0 (Big Sur) and later

## What it does

From the menu bar you can pick any display mode the hardware reports — including
HiDPI / 2× modes that Apple's UI hides. For example, a Retina MacBook Pro 13"
can be set to a native 3360×2100 instead of Apple's max 1680×1050.

## Install from a release

1. Download `RDM-2.3.dmg` from the [Releases page](../../releases).
2. Open the DMG and drag `RDM.app` to `/Applications`.
   - If the upstream RDM 2.2 is already installed, this **overwrites it in
     place** — your preferences are preserved (same bundle ID
     `net.alkalay.RDM`).
3. Launch `RDM.app`. A monitor icon appears in the menu bar.

### First launch on a colleague's Mac (unsigned build)

This build is **not code-signed** (no paid Apple Developer account), so macOS
Gatekeeper will warn that it cannot verify the developer. To open it the first
time, do **one** of:

- **Right-click** `RDM.app` → **Open** → confirm in the dialog. After the first
  launch it opens normally.
- Or if it's already blocked: open **System Settings → Privacy & Security**,
  scroll to the RDM notice, click **Open Anyway**.

After the first confirmation, Gatekeeper remembers the app and won't ask again.

### Run on login

Add `RDM.app` to your login items so it starts automatically:
**System Settings → General → Login Items** → add RDM under "Open at Login".

## Build from source

Requirements: macOS Command Line Tools (no full Xcode needed).

```sh
make build      # produces RDM.app
make dmg        # produces RDM-2.3.dmg (also runs build + pkg)
make clean      # remove build artifacts
```

It uses the private CoreGraphics `CGS*` symbols
(`CGSGetCurrentDisplayMode`, `CGSConfigureDisplayMode`,
`CGSGetNumberOfDisplayModes`, `CGSGetDisplayModeDescriptionOfLength`) — still
exported in current macOS — to enumerate and switch display modes.

## Credits & original description

RDM was originally written by **Avi Alkalay**. The block below is the original
upstream README, preserved verbatim as a quotation and for attribution:

> This is a tool that lets you use MacBook Pro Retina's highest and unsupported resolutions.
> As an example, a Retina MacBook Pro 13" can be set to 3360×2100 maximum resolution, as
> opposed to Apple's max supported 1680×1050. It is accessible from the menu bar.
>
> You should prefer resolutions marked with ⚡️ (lightning), which indicates the resolution
> is HiDPI or 2× or more dense in pixels.
>
> For more practical results, add RDM.app to your Login Items in **System Preferences ➡ Users & Groups ➡ Login Items**.
> This way RDM will run automatically on startup.
>
> This software was studied and released [here](http://garethjenkins.com/2012/07/01/investigating-a-high-resolution-retina-utility-for-macbook-pro-1x-and-2x-modes/#comment-623)
> and [here](http://www.reddit.com/r/apple/comments/vi9yf/set_your_retina_macbook_pros_resolution_to/)
> by its original authors. I just improved the build system and Makefile, fixed the icon,
> added support for easy installable package (PKG, DMG) and improved the way menu is
> displayed. I don't know what is the license by its authors because it came 100%
> uncommented and undocumented. But I'm sure they would enjoy you to freely use it. Me too.

## License

Distributed under the GNU General Public License v3.0, same as upstream. The
core display-switching logic is the work of the original authors; this fork
only ports the build to native arm64.
