{ pkgs ? import <nixpkgs> {} }:

let
  callPackage = pkgs.newScope self;
self = rec {
    jsonify-aws-dotfiles                  = pkgs.callPackage ./projects/jsonify-aws-dotfiles           { };
  };
in self
