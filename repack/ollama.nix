{
  pkgs,
  lib,
  reIf,
  ...
}:
reIf {
  services.ollama = {
    enable = true;
    package = pkgs.ollama-ipex;
  };
  systemd.services.ollama.serviceConfig = lib.mkForce {
    DynamicUser = true;

    ExecStart = "${pkgs.ollama-ipex}/bin/ollama-ipex serve";

    PrivateTmp = true;

    Environment = [
      "HOME=/var/lib/ollama"
      "OLLAMA_HOST=[::]:11434"
      "OLLAMA_MODELS=/var/lib/ollama/models"
      "OLLAMA_ORIGINS=\"http://192.168.*\""
    ];
    ReadWritePaths = [ "/var/lib/ollama" ];
  };
}
