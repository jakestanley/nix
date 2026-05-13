# kestrel runs on the same physical machine as shrike.
# Hardware configuration is imported directly from shrike.
{ ... }:
{
  imports = [ ../shrike/hardware-configuration.nix ];
}
