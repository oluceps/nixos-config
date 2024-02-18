{ pkgs ? import <nixpkgs> }: (builtins.getFlake (toString ./.)).packages.x86_64-linux

