# TODO: known issue: while first create if parent not exist, it created owned by root
{
  lib,
  pkgs,
  user,
  ...
}@args:
# https://gist.github.com/thalesmg/ae5dc3c5359aed78a33243add14a887d
# let
#   configPlace = "/home/${user}/.config";

#   inherit (builtins) readDir foldl' attrNames;
#   inherit (lib.attrsets) filterAttrs setAttrByPath recursiveUpdate;
#   inherit (lib) removeSuffix;
#   inherit (pkgs) writeText;

# listRecursive = pathStr: listRecursive' { } pathStr;
# listRecursive' =
#   acc: pathStr:
#   let
#     toThePath = s: path + "/${s}";
#     path = ./. + pathStr;
#     contents = readDir path;
#     dirs = filterAttrs (k: v: v == "directory") contents;
#     files = filterAttrs (k: v: v == "regular" && k != "default.nix") contents;
#     # dirs' = attrNames dirs;
#     dirs' = foldl' (acc: d: recursiveUpdate acc (listRecursive (pathStr + "/" + d))) { } (
#       attrNames dirs
#     );
#     files' = foldl' (
#       acc: f:
#       recursiveUpdate acc (
#         setAttrByPath [ "${configPlace}${pathStr}/${(removeSuffix ".nix" f)}" ] (
#           if lib.hasSuffix ".nix" f then
#             (writeText (removeSuffix ".nix" f) (import (toThePath f) args))
#           else
#             (toThePath f)
#         )

#       )
#     ) { } (attrNames files);
#   in
#   dirs';
# { lib }:
let
  collectDirs =
    path: prefix:
    let
      entries = builtins.readDir path;
      dirs = lib.filterAttrs (_: type: type == "directory") entries;
      self = lib.mapAttrs' (name: _: {
        name = if prefix == "" then name else "${prefix}/${name}";
        value = 1;
      }) dirs;
      children = lib.mapAttrsToList (
        name: _: collectDirs (path + "/${name}") (if prefix == "" then name else "${prefix}/${name}")
      ) dirs;
    in
    lib.foldl' (acc: child: acc // child) self children;
in
path: collectDirs path ""
# in
# listRecursive ""
