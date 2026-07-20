{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs =
    { nixpkgs, ... }:
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

          buildArg = {
            modules = [
              hardware-configuration
              ./filesystems.nix
              ./configuration.nix
              in {
                huskyos.btrfsDevice = builtins.readFile btrfs-device;
                huskyos.efiDevice = builtins.readFile efi-device;
                huskyos.swapDevice = firstLineOfFileElse swap-device null;
                huskyos.flakeFolder = selfArg.outPath;
                huskyos.hardwareUri = hardware-configuration;
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
