#!/usr/bin/env -S sh -c 'awk \'f{print} $0=="#runhere"{f=1}\' "$0" | unshare -m'
{ pkgs, ... }:
let

  res-sys = with pkgs; writeShellScriptBin cmdrbb (builtins.readFile ./reset-system.sh);
  cmdrbb = "rebuild-boot";
  rb-uw = with pkgs; writeShellScript "rebuild-boot-unwrapped" ''
#runhere
    PATH=$PATH:${efibootmgr}/bin:${sbctl}/bin:${nix}/bin:${gnugrep}/bin
    echo updating system...;
    unsigned=/boot/efi/boot/BOOTX64_NEXT-unsigned.EFI
    signed=/boot/efi/boot/BOOTX64_NEXT.EFI

    sbctl --help >/dev/mull || exit 1;
    NEXT_NUM=$(efibootmgr | grep -oP "^Boot\K.{4}(?=..HuskyOS Next)") || { echo please create all boot entries including HuskyOS Next; exit 1; }

    echo building new system...
    newUki=$(nix build .#nixosConfigurations.nixos.config.system.build.uki --no-link --print-out-paths --no-write-lock-file)/nixos.efi || exit 1;
    cp "$newUki" "$unsigned" || exit 1;
    mount --bind /boot/sbctl /var/lib/sbctl &&
    sbctl status --json | grep '"installed": true' && {
      sbctl sign $unsigned;
    } || true;
    mv -f $unsigned $signed;
    efibootmgr -u -n $NEXT_NUM || exit 1;
    echo ...done;
    exit 0;
  '';
  rb = with pkgs; writeShellScriptBin "rebuild-boot" "unshare -m ${rb-uw}";
in
{
  config.system.build.nixos-rebuild = lib.mkForce "${rb}/bin/${cmdrbb}";
  environment.systemPackages = [ rb res-sys ];
  system.tools.nixos-rebuild.enable = false;
}
