{ pkgs, ... }:
let
  cmdrbb = "rebuild-boot";
  rb = with pkgs; writeShellScriptBin cmdrbb (builtins.readFile ./rebuild-boot.sh);
  res-sys = with pkgs; writeShellScriptBin cmdrbb (builtins.readFile ./reset-system.sh);
in
{
  config.system.build.nixos-rebuild = lib.mkForce "${rb}/bin/${cmdrbb}";
  environment.systemPackages = [ rb res-sys ];
  system.tools.nixos-rebuild.enable = false;
}
