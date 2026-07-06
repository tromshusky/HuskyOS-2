{
  inputs.nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-26.05";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs =
    { nixpkgs, nixpkgs-stable, ... }:
    {
      withSelf =
        selfArg:
        let
          stateVersion = "26.05";
          keyboard-layout = "${selfArg.outPath}/KBD";
          hashed-root-password = "${selfArg.outPath}/RPW";
          btrfs-device = "${selfArg.outPath}/BTR";
          efi-device = "${selfArg.outPath}/EFI";
          swap-device = "${selfArg.outPath}/SWP";
          hardware-configuration = "${selfArg.outPath}/hardware-configuration.nix";
          extra-config = fileThatExistsElse "${selfArg.outPath}/config.nix" { };

          fileThatExistsMapElse =
            fPath: mapFileFunction: els:
            if (builtins.pathExists fPath) && (builtins.readFileType fPath == "regular") then
              (mapFileFunction fPath)
            else
              els;
          fileThatExistsElse = fPath: els: fileThatExistsMapElse (_: _) els;
          firstLine = text: (builtins.head (builtins.split "\n" (builtins.readFile text)));
          firstLineOfFileElse = fPath: els: (fileThatExistsMapElse fPath firstLine els);

          stableConf = nixpkgs-stable.lib.nixosSystem { modules = [
            hardware-configuration
            ./filesystems.nix
            { pkgs, ... }: let
              nmAndBash = pkgs.writeShellScript "nmtuiBash" ''
                ${pkgs.brightnessctl}/bin/brightnessctl set 50% || true;
                nmtui;
                /usr/bin/env bash;
              '';
              launchTerm = pkgs.writeShellScript "termSession" ''
                exec ${pkgs.foot}/bin/foot ${nmAndBash}
              '';
            in {
              system.stateVersion = stateVersion;
              boot.loader.grub.enable = false;
#              services.desktopManager.gnome.enable = true;
#              services.displayManager.gdm.enable = true;
#              services.gnome.core-apps.enable = false;
              services.cage.enable = true;
              services.cage.user = "root";
              networking.networkmanager.enable = true;
              services.cage.program = launchTerm;
              fonts.enableDefaultPackages = true;
              system.tools.nixos-rebuild.enable = false;
            }
          ]; };

          buildArg = {
            modules = [
              hardware-configuration
              ./filesystems.nix
              ./configuration.nix
              { lib, pkgs, ... }: let
                nixos-rebuild = pkgs.writeShellScriptBin "nixos-rebuild" ''
                  PATH=$PATH:${pkgs.nix}/bin:${pkgs.sbctl}/bin:${pkgs.gnugrep}/bin:${pkgs.gnused}/bin
                  echo This is a custom nixos-rebuild script for the omly purpose of updating the OS, eg. via systemd/nixos-upgrade.service
                  mapfile -t result < <(nix build ${selfArg.outPath}#nixosConfigurations."huskyos".config.system.build.toplevel ${selfArg.outPath}#nixosConfigurations."huskyos".config.system.build.uki --no-link --print-out-paths --experimental-features "nix-command flakes") || exit 1;
                  toplvl=$(echo ${"$"}{result[0]} | sed 's|/nix/store|./store|')
                  uki1=${"$"}{result[1]}/nixos.efi
                  cp -f $uki1 /boot/efi/boot/BOOTX64-unsigned.EFI;
                  sbctl status | grep "sbctl is installed" && { sbctl sign /boot/efi/boot/BOOTX64-unsigned.EFI || exit 1; }
                  # we replace the kernel atomically, always leaving it in a bootable state 
                  mv -f /boot/efi/boot/BOOTX64-unsigned.EFI /boot/efi/boot/BOOTX64.EFI;
                  ln -snf $toplvl /nix/closure;
                '';
              in {
                huskyos.btrfsDevice = builtins.readFile btrfs-device;
                huskyos.efiDevice = builtins.readFile efi-device;
                huskyos.swapDevice = builtins.readFile swap-device;
                huskyos.flakeFolder = selfArg.outPath;
                huskyos.hardwareUri = hardware-configuration;
                huskyos.keyboardLayout = firstLineOfFileElse keyboard-layout "us";
                huskyos.hashedRootPassword = firstLineOfFileElse hashed-root-password null;
                config.system.build.nixos-rebuild = lib.mkForce nixos-rebuild;
              }
              extra-config
            ];
          };
        in
        {
          nixosConfigurations."huskyos" = nixpkgs.lib.nixosSystem buildArg;
        };
    };
}
