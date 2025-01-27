{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib; let
  cfg = config.modules.services.tailscale;
  loginserver = "https://hs.nixlap.top";
  taildrop-dir = "/home/${username}/Downloads";
in {
  options = {
    modules.services.tailscale = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };
  config = mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      permitCertUid = username;
      extraSetFlags = [
        "--operator=${username}"
      ];
    };
    systemd.user.services.taildrop = {
      enable = true;
      description = "Automatically save TailDrop files, just like AirDrop";
      after = ["network.target"];
      wantedBy = ["default.target"];
      script = "${getExe pkgs.tailscale} file get --conflict rename --loop --verbose ${taildrop-dir}";
    };
    networking.firewall = {
      checkReversePath = "loose";
      trustedInterfaces = ["tailscale0"];
      allowedUDPPorts = [config.services.tailscale.port];
    };
    environment.persistence."/persist".directories = mkIf config.modules.sysconf.impermanence.enable [
      "/var/lib/tailscale"
    ];
    sops.secrets."tailscale_preauthkey" = {
      sopsFile = ../../../secrets/tailscale_preauthkey.psk;
      format = "binary";
    };

    # create a oneshot job to authenticate to Tailscale
    systemd.services.tailscale-autoconnect = {
      description = "Automatic connection to Tailscale";

      # make sure tailscale is running before trying to connect to tailscale
      after = [
        "network-pre.target"
        "tailscale.service"
      ];
      wants = [
        "network-pre.target"
        "tailscale.service"
      ];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        Type = "oneshot";
        Restart = "on-failure";
        RestartSec = "20";
      };

      path = with pkgs; [
        tailscale
        jq
        coreutils
      ];
      script = ''
        set -x
        set -eu
        sleep 2
        status="$(tailscale status -json | jq -r .BackendState)"
        if [ $status = "Running" ]; then # if so, then do nothing
          exit 0
        fi
        tailscale up --operator ${username} --login-server ${loginserver} --auth-key $(cat /run/secrets/tailscale_preauthkey)
      '';
    };
  };
}
