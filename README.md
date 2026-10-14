# Intel Arc Pro B50 on Legacy OEM PCs

## Read-only diagnostics for a runtime 16 GiB BAR2 experiment

**Experimental: validated on one physical machine.** This repository documents an Intel Arc Pro B50 16GB experiment on an HP EliteDesk 800 G4 SFF. The initial release contains the owner's tested `diagnose.sh` v0.2, an English diagnostic tutorial, and [safety notes](docs/safety.md).

The script observes an existing configuration. It does **not** enable ReBAR, resize a BAR, restore a GPU after reboot, or modify firmware. No PCIe write or recovery script is included.

## 1. Evidence and scope

The owner ran v0.2 as an ordinary Linux user and supplied output with all three checks passing:

```text
BAR2_16G: PASS
XE_DRIVER: PASS
DRM_NODE: PASS

READ-ONLY DIAGNOSTIC COMPLETE
```

| Item | Reported configuration or observation |
|---|---|
| Computer | HP EliteDesk 800 G4 SFF |
| GPU | Intel Arc Pro B50 16GB |
| GPU PCI vendor/device ID | `8086:e212` |
| Linux kernel | `6.18.18.c1126-trim` |
| BAR2 | `lspci` reported `[size=16G]` |
| Driver | `xe`, resolved through the GPU's sysfs driver link |
| Render association | A DRM render entry resolved to the same PCI device |

This is an owner-reported, single-machine validation of the published v0.2 source. Preparing this release did not involve reconnecting to the machine or rerunning its hardware tests. The script is preserved from the version immediately preceding the owner's successful run.

The three checks concern BAR reporting, driver binding, and the sysfs render-device association. They do not establish successful GPU computation, permission to open the render node, direct confirmation of the ReBAR control register, or long-term reliability.

## 2. Background: what this project investigates

The [original experiment report](https://www.reddit.com/r/IntelArc/comments/1x46jib/) describes an older OEM platform without an exposed BIOS ReBAR setting, a B50 initially reporting a 256 MiB BAR2, and a later runtime allocation of 16 GiB without flashing a BIOS image.

PCIe BARs describe address windows used to access device resources. A large GPU memory capacity and a large CPU-visible BAR are different observations; a small BAR alone does not establish how much VRAM a particular application can use. Bridge resource allocation also matters. Device capability alone does not prove that the host has allocated a matching window.

The owner's observed GPU path traversed a CPU root port and PCIe switch bridges. Device addresses, bridge relationships, and render-node numbers are machine-specific and can change. v0.2 discovers matching PCI IDs through sysfs instead of hard-coding the owner's PCI address or render-node number.

The original report also discusses XPU computation, TTS measurements and one reboot restoration. Those historical reports are separate from the v0.2 diagnostic run. This release does not independently reproduce them, provide a performance guarantee, or distribute a runtime recovery procedure.

## 3. Requirements

- Linux with readable PCI and DRM sysfs entries.
- Bash, `lspci` from pciutils, and the ordinary `cat`, `basename`, `readlink`, `grep`, `head`, `date`, and `uname` utilities.
- A device with PCI ID `8086:e212` for the targeted checks. Other Intel GPUs are outside this version's validated scope.
- An ordinary user account. Do not add `sudo` to obtain more complete output.

The tested version uses human-readable `lspci` output. Use an English/C locale as shown below. Distribution, pciutils, permission and output-format differences may produce `NOT VERIFIED` even when the hardware is usable. The tested kernel version is an observation, not a minimum-version promise.

## 4. Download, inspect, and run

Read [the safety notes](docs/safety.md) first. Download the repository through GitHub's **Code > Download ZIP**, or clone it on the computer where you intend to inspect it:

```sh
git clone https://github.com/ewkeee/intel-arc-rebar-legacy-oem.git
cd intel-arc-rebar-legacy-oem
```

Inspect [scripts/diagnose.sh](scripts/diagnose.sh) before execution. Then, on the Linux machine you intend to diagnose, run:

```sh
bash -n scripts/diagnose.sh
LC_ALL=C bash scripts/diagnose.sh
```

The first command checks shell syntax; it does not run the diagnostic. The second prints the observations to the terminal. Neither command requires making the file executable. The script does not install dependencies, change drivers or contact a remote service.

If you choose to save the output, shell redirection writes a local file. Choose a new filename because `>` replaces an existing file:

```sh
(umask 077; LC_ALL=C bash scripts/diagnose.sh > b50-v0.2-result.txt 2>&1)
```

Inspect the saved text and redact it before sharing. Do not publish a whole terminal transcript.

## 5. Interpret the output precisely

| Check | What v0.2 actually tests | What it does not test |
|---|---|---|
| `BAR2_16G` | The first `Region 2:` line contains the literal text `[size=16G]` | Direct ReBAR control-register validation, usable VRAM, allocation success for a workload |
| `XE_DRIVER` | The PCI device's sysfs driver symlink resolves to a directory named `xe` | Successful GPU execution or absence of driver errors |
| `DRM_NODE` | A sysfs `renderD*` entry resolves to the same PCI device | Opening `/dev/dri/renderD*`, access permissions, or a compute test |

The script prints a `/dev/dri/` path derived from the matching sysfs entry; it does not separately verify that the character device exists or is accessible. If more than one matching GPU is present, read each GPU's block separately.

`NOT VERIFIED` means this version did not establish the check. It is not a diagnosis of defective hardware. `NOT FOUND` means no readable matching PCI device was found. A missing `lspci` or no matching device causes exit status 1.

**Exit status 0 and `READ-ONLY DIAGNOSTIC COMPLETE` are not an aggregate PASS.** v0.2 may finish successfully with individual checks marked `NOT VERIFIED`, and it does not comprehensively propagate command failures. Read all three results and any error output. This baseline should not be used as an unattended health gate.

Unprivileged `lspci` may show `Capabilities: <access denied>`. That limits the available evidence; it is not by itself a GPU failure. The owner's diagnostic output showed the allocated 16 GiB BAR2 but did not directly validate the ReBAR control register.

## 6. Troubleshooting without changing device state

1. If `lspci` is missing, identify the pciutils package for your distribution before deciding whether to install anything.
2. If the GPU is not found, check the reported PCI device ID and whether this environment exposes host PCI sysfs. v0.2 is not a universal Intel Arc detector.
3. If BAR2 is not verified, inspect the printed BAR line and command errors. Do not treat a parser mismatch as permission to resize hardware resources.
4. If `xe` or a matching render entry is absent, record the result. This script neither loads drivers nor repairs device enumeration.
5. Stop here if the next step would require PCIe writes, driver unbinding, device removal, rescanning, or rebooting a critical machine. Those actions need a separate, hardware-specific review and recovery plan.

## 7. Validation still needed

- Independent reproduction on other machines, motherboard models, BIOS revisions and GPUs.
- Repeated cold boots, power-loss recovery and kernel-upgrade resilience.
- Separate XPU compute and application-level tests with recorded software versions.
- Controlled performance testing; a before/after result with a reboot between runs cannot isolate the BAR change as the sole cause.

The current release includes no photographs, raw system logs, private infrastructure details, installation service, or PCIe modification tooling. No license is added in this release; public visibility alone is not a grant of reuse rights.

## 8. Reporting results

Use a GitHub issue for sanitized diagnostic findings: computer/GPU model, PCI ID, kernel and pciutils versions, the three validation lines, and only the relevant redacted output. Describe whether results are from physical hardware, a virtual machine, or a container. Do not include usernames, hostnames, network addresses, serial numbers, tokens, private paths, or unrelated storage/network configuration.

Experiment and hardware testing: repository owner. Documentation was prepared with AI assistance and checked against the supplied diagnostic source and output.

## References

- [Original owner experiment](https://www.reddit.com/r/IntelArc/comments/1x46jib/)
- [pciutils lspci manual](https://man7.org/linux/man-pages/man8/lspci.8.html): output, access restrictions, and format limitations.
- [Linux DRM userland interfaces](https://docs.kernel.org/gpu/drm-uapi.html): render-node interfaces.
- [Safety and privacy notes](docs/safety.md)
