# Safety and privacy

## Release boundary

This release publishes only the owner's tested `scripts/diagnose.sh` v0.2 and documentation. The script reads PCI information with `lspci`, reads sysfs attributes and symlinks, and prints results. Its command paths contain no PCIe register writes, driver unbinding, device removal, rescans, resets, firmware updates, service changes, package installation or reboot commands.

The source has been retained as the tested baseline. Known diagnostic limitations are documented in the [README](../README.md); preserving a tested version does not imply that its error handling or portability is complete.

## Read-only does not mean zero risk

`lspci -vv` reads PCI configuration information. No hardware diagnostic can promise zero risk for every device, driver or platform. Run as an ordinary user in a context you control. Do not escalate privileges or add full configuration-space dumps just to remove an access-denied message. The pciutils manual warns that some devices can fail when certain configuration areas are read.

The script writes output to the terminal. Saving output with shell redirection is a separate filesystem write and can overwrite an existing file. It prints the time, kernel version and a system-wide PCI topology, so its output can reveal more hardware detail than just the GPU.

## Runtime PCIe changes are outside this release

Resizing BARs, altering bridge windows, removing or rescanning a PCIe subtree, and unbinding drivers can interrupt attached devices. A bridge may lead to storage or network hardware as well as a GPU. A mistake can cause loss of remote access, interrupted storage I/O, data loss, failed initialization, or a system requiring local recovery.

Do not copy PCI addresses or register values from another machine. A successful experiment on one system does not make the procedure portable. A remote shell is not a recovery plan. Any future modification tooling requires separate source review, exact hardware/topology checks, and tested local recovery before use. The public diagnostic does not authorize or automate these actions.

## What the reported 3/3 PASS covers

The owner supplied a successful v0.2 run for one Intel Arc Pro B50 (`8086:e212`) on an HP EliteDesk 800 G4 SFF. The checks report a 16 GiB BAR2 text match, a driver link resolving to `xe`, and a matching sysfs render-device association.

They do not demonstrate direct ReBAR control-register validation, device-node accessibility, working PyTorch XPU computation, benchmark reproducibility, stability under load, repeated cold boots, power-loss recovery, or compatibility with other hardware. No new NAS access or hardware retest was performed while preparing this release.

## Sharing diagnostics

Review every output file and screenshot before publishing it. Remove usernames, hostnames, IP/MAC addresses, credentials, tokens, serial numbers, personal paths, private service names and unrelated storage or network details. Avoid complete shell transcripts and full desktop screenshots. Prefer the three result lines and the minimum redacted evidence needed to explain a problem.

The diagnostic includes no upload or telemetry command. Posting its output is a separate decision. Do not put credentials or private logs in public GitHub issues. If a credential is exposed, revoke or rotate it; removing it from the latest file does not remove copies from Git history or other people's downloads.

## Disclaimer

This is an experimental, single-machine diagnostic baseline for research and education. It provides no warranty of compatibility, availability, data safety or fitness for production use. Hardware-changing procedures and future versions require their own review and validation.
