# SPDX-FileCopyrightText: 2022 Alyssa Ross <hi@alyssa.is>
# SPDX-License-Identifier: MIT

{ pkgs ? import <nixpkgs> {} }: pkgs.callPackage (

{ lib, runCommand, jekyll }:

runCommand "spectrum-docs" {
  src = with lib; cleanSourceWith {
    src = cleanSource ./.;
    filter = name: _type:
      name != ".jekyll-cache" &&
      name != "_site" &&
      !(hasSuffix ".nix" name);
  };

  nativeBuildInputs = [ jekyll ];

  passthru = { inherit jekyll; };
} ''
  jekyll build --disable-disk-cache -b /doc -s $src -d $out
''
) {
  jekyll = import ./jekyll.nix { inherit pkgs; };
}
