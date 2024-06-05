{
  config,
  lib,
  hostname,
  ...
}:
with lib; let
  cfg = config.modules.sysconf.bluetooth;
in {
  options = {
    modules.sysconf.bluetooth = {
      enable = mkOption {
        type = types.bool;
        default = true;
      };
      blueman = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };
  config = mkIf cfg.enable {
    services.blueman.enable = mkIf cfg.blueman true;
    hardware.bluetooth.enable = true;
    hardware.bluetooth.settings = {
      General = {
        # uncomment this to allow pairing Airpods then restart the bluetooth stack sudo systemctl restart bluetooth
        # only required at initial pairing
        # ControllerMode = "bredr";
        #
        # Speaker icon
        Class = "0x040414";
        Name = hostname;
        DiscoverableTimeout = 0;
        PairableTimeout = 0;
      };
    };
    # Make sure to trust the device immediately when using pipewire as bluetooth speaker
    #
    # Save bluetooth settings
    environment.persistence."/persist".directories =
      lib.mkIf config.modules.sysconf.impermanence.enable
      ["/var/lib/bluetooth"];
  };
}
