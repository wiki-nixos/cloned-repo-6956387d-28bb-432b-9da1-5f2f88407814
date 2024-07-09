{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.services.firejail;
in {
  options = {
    modules.services.firejail = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };
  config = mkIf cfg.enable {
    programs.firejail = {
      enable = true;
      wrappedBinaries = {
        tor-browser = {
          executable = "${pkgs.tor-browser}/bin/tor-browser";
          profile = "${pkgs.firejail}/etc/firejail/tor-browser.profile";
          desktop = "${pkgs.tor-browser}/share/applications/torbrowser.desktop";
        };
        vesktop = {
          executable = "${pkgs.vesktop}/bin/vesktop";
          profile = "${./firejail/vesktop.profile}";
          desktop = "${pkgs.vesktop}/share/applications/vesktop.desktop";
        };
      };
    };
    environment.systemPackages = [
      (
        let
          packages = with pkgs; [
            tor-browser
            vesktop
          ];
        in
          pkgs.runCommand "firejail-icons"
          {
            preferLocalBuild = true;
            allowSubstitutes = false;
            meta.priority = -1;
          }
          ''
            mkdir -p "$out/share/icons"
            ${lib.concatLines (map (pkg: ''
                tar -C "${pkg}" -c share/icons -h --mode 0755 -f - | tar -C "$out" -xf -
              '')
              packages)}
            find "$out/" -type f -print0 | xargs -0 chmod 0444
            find "$out/" -type d -print0 | xargs -0 chmod 0555
          ''
      )
    ];
  };
}