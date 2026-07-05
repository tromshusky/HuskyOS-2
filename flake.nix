{
  inputs.nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-26.05";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs =
    { nixpkgs, ... }:
    {
      withSelf =
        selfArg:
        let
          keyboard-layout = "${selfArg.outPath}/KBD";
          hashed-root-password = "${selfArg.outPath}/RPW";
          btrfs-device = "${selfArg.outPath}/BTR";
          efi-device = "${selfArg.outPath}/EFI";
          swap-device = "${selfArg.outPath}/SWP";
          hardware-configuration-no-filesystems = "${selfArg.outPath}/hardware-configuration-no-filesystems.nix";
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

          buildArg = {
            modules = [
              hardware-configuration-no-filesystems
              ./configuration.nix
              {
                huskyos.btrfsDevice = builtins.readFile btrfs-device;
                huskyos.efiDevice = builtins.readFile efi-device;
                huskyos.swapDevice = builtins.readFile swap-device;
                huskyos.flakeFolder = selfArg.outPath;
                huskyos.hardwareUri = hardware-configuration-no-filesystems;
                huskyos.keyboardLayout = firstLineOfFileElse keyboard-layout "us";
                huskyos.hashedRootPassword = firstLineOfFileElse hashed-root-password null;
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
