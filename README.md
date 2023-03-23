# Nix-Terminator

This Racket script is a part of a work in progress system that will allow pinning nix-packages by their own version (e.g. 1.5.1) rather than the hash of the nix-channel commit in which that version was published (e.g. 94c79393).

The task of this part of the system is to travel back in the git history of the nix channel and search for version changes - then output all found versions with the corresponding commit hash so that a nixos system can pin to that hash.

For usability purposes I suggest that the nix project will include the ability to read the json output of this generator and allow for pinning by version directly by parsing the given version and looking it up in the json. The commit hash can then be read and applied in the background while the user sees a pinned version.

## Version pinning now
```
inputs = {
  nixpkgs.url = github:nixos/nixpkgs/nixos-unstable;
  # i had to manually look this hash up (https://lazamar.co.uk/nix-versions/?channel=nixpkgs-unstable&package=jetty)
  # ugh, manual labor
  nixpkgs-jetty-9-4-45.url = github:nixos/nixpkgs/7592790b9e02f7f99ddcb1bd33fd44ff8df6a9a7;
}
```

## Version pinning with nix-terminator
```
inputs = {
  nixpkgs.url = github:nixos/nixpkgs/nixos-unstable;
  # yay, automatic
  nixpkgs-jetty-9-4-45.url = github:nixos/nixpkgs/jetty-9.4.45;
}
```
## CLI Arguments
0. name of the package to search
1. location of the nix channel in which to search (the git HEAD will be changed so be careful!)

```
./main.rkt hello /tmp/nix-channel
```

