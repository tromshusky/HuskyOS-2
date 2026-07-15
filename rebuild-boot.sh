#!/bin/sh
NEXT_NUM=$(efibootmgr | grep -oP "^Boot\K.{4}(?=..HuskyOS Next)") || { echo please create all boot entries including HuskyOS Next; exit 1; }
newClosure=$(nix build .#nixosConfigurations.nixos.config.system.build.toplevel --no-link --print-out-paths | sed 's|/nix/store|store|' ) || exit 1;
newUki=$(nix build .#nixosConfigurations.nixos.config.system.build.uki --no-link --print-out-paths)/nixos.efi || exit 1;
mkdir -p /nix/var/nix/profiles || true;
ln -snf ../../../$newClosure /nix/var/nix/profiles/system-next;
cp $newUki /boot/efi/boot/BOOTX64_NEXT.EFI || exit 1;
efibootmgr -u -n $NEXT_NUM || exit 1;
