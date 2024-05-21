{ lib, pkgs, ... }@args:
# https://gist.github.com/thalesmg/ae5dc3c5359aed78a33243add14a887d
let
  configPlace = "~/.config";

  inherit (builtins) readDir foldl' attrNames;
  inherit (lib.attrsets) filterAttrs setAttrByPath recursiveUpdate;
  inherit (lib.lists) singleton;
  inherit (lib)
    removeSuffix
    concatStringsSep
    drop
    reverseList
    splitString
    ;
  inherit (pkgs) writeText;

  listRecursive = pathStr: listRecursive' { } pathStr;
  listRecursive' =
    acc: pathStr:
    let
      toPath = s: path + "/${s}";
      path = ./. + pathStr;
      contents = readDir path;
      dirs = filterAttrs (k: v: v == "directory") contents;
      files = filterAttrs (k: v: v == "regular" && k != "default.nix") contents;
      dirs' = foldl' (acc: d: recursiveUpdate acc (listRecursive (pathStr + "/" + d))) { } (
        attrNames dirs
      );
      files' = foldl' (
        acc: f:
        recursiveUpdate acc (
          setAttrByPath [ "${configPlace}${pathStr}/${(removeSuffix ".nix" f)}" ] (
            if lib.hasSuffix ".nix" f then
              (writeText (removeSuffix ".nix" f) (import (toPath f) args))
            else
              (toPath f)
          )

        )
      ) { } (attrNames files);
    in
    recursiveUpdate dirs' files';
  parent = p: concatStringsSep "/" (reverseList (drop 1 (reverseList (splitString "/" p))));
in
lib.concatStringsSep "\n" (
  lib.foldlAttrs (
    acc: n: v:
    acc ++ singleton "mkdir -p ${parent n}; ln -sf ${v} ${n}"
  ) [ ] (listRecursive "")
)
