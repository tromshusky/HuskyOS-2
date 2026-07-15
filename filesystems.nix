{ lib, config, ... }:
let
  BTR = config.huskyos.btrfsDevice;
  EFI = config.huskyos.efiDevice;
  SWP = config.huskyos.swapDevice;
in
{

  fileSystems."/" =
    { device = "tmpfs";
      fsType = "tmpfs";
      options = [ "size=16G" "mode=0755" ];
    };

  fileSystems."/nix" =
    { device = BTR;
      fsType = "btrfs";
      options = [ "subvol=@huskyos/@nix" ];
    };

  fileSystems."/userdata" =
    { device = BTR;
      fsType = "btrfs";
      options = [ "subvol=@huskyos/@userdata" ];
    };

  fileSystems."/boot" =
    { device = EFI;
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };

  swapDevices = lib.optional (SWP != null) SWP;

}
