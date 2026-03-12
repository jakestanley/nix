{ config, lib, pkgs, inputs, ... }:

let
  registry = lib.importJSON (pkgs.runCommandLocal "registry-json" {
    nativeBuildInputs = [ pkgs.yq-go ];
  } ''
    yq -o=json ${inputs.homelab-infra}/registry.yaml > $out
  '');
in

{ 
  _module.args.registry = registry;
}
