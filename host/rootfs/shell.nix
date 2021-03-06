# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2021 Alyssa Ross <hi@alyssa.is>

{ pkgs ? import <nixpkgs> {} }:

with pkgs;

(import ./. { inherit pkgs; }).overrideAttrs (
{ passthru ? {}, nativeBuildInputs ? [], ... }:

{
  nativeBuildInputs = nativeBuildInputs ++ [
    jq netcat qemu_kvm reuse util-linux
  ];

  EXT_FS = pkgsStatic.callPackage ../initramfs/extfs.nix { inherit pkgs; };
  KERNEL = "${passthru.kernel}/${stdenv.hostPlatform.linux-kernel.target}";
})
