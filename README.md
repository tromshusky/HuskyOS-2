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
- efi boot entries have init=/nix/var/nix/profiles/system/init and init=/nix/closure-old
- nixos-rebuild is rewritten to only update the current os.
- if sbctl is installed (with keys), efi files get signed.


specs:
- btrfs partition to handle all big amounts of data and system files.
  - System Files reside on btrfs

Decisions to make:
- Do we have seperate nix stores for each update (AB root style) => we can isolate the systems better against "rm -rf /" || have a shared nix store between A and B root.
- AB root or more generations?
  - we do need 1 recovery boot option, one current and one next