{ pkgs ? import <nixpkgs> {} }:

let
  callPackage = pkgs.newScope self;
  self = rec {
    jsonify-aws-dotfiles                  = pkgs.callPackage ./projects/jsonify-aws-dotfiles           { };
    matterbridge                          = pkgs.callPackage ./matterbridge                            { };
  };
in self
