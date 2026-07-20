{ pkgs, ... }:
let
  rb = with pkgs; writeShellScriptBin "rebuild-boot" (builtins.readFile ./rebuild-boot.sh);
in
{
  environment.systemPackages = [ rb ];
  system.tools.nixos-rebuild.enable = false;
}
