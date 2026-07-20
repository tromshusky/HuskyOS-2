#!/bin/sh
PATH=$PATH:${efibootmgr}/bin:${gnused}/bin:${gnugrep}/bin:${nix}/bin:${sbctl}/bin
unsigned=/boot/efi/boot/BOOTX64_NEXT-unsigned.EFI
signed=/boot/efi/boot/BOOTX64_NEXT.EFI

unshare -m /bin/sh << 'EOF'

  sbctl --help >/dev/mull || exit 1;
  NEXT_NUM=$(efibootmgr | grep -oP "^Boot\K.{4}(?=..HuskyOS Next)") || { echo please create all boot entries including HuskyOS Next; exit 1; }

  echo building new system...
  newUki=$(nix build .#nixosConfigurations.nixos.config.system.build.uki --no-link --print-out-paths --no-write-lock-file)/nixos.efi || exit 1;
  cp $newUki $unsigned || exit 1;
  mount --bind /boot/sbctl /var/lib/sbctl &&
  sbctl status --json | grep '"installed": true' && {
    sbctl sign $unsigned;
  } || true;
  mv -f $unsigned $signed;
  efibootmgr -u -n $NEXT_NUM || exit 1;

EOF
