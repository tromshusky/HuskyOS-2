# HuskyOS-2
HuskyOS with secure boot 

an HuskyOS version with:
- Uki as bootloader
- Stable bootloader entry for recovery
- Secure Boot, with root user as root of trust
- Minimal flake by default

how:
- installer create EFI and BTR partition, optionally SWP.
- installer creates boot entries for old (stable) and current.
- efi boot entries have init=/nix/closure and init=/nix/closure-old
- nixos-rebuild is rewritten to only update the current os.
- if sbctl is installed (with keys), efi files get signed.
