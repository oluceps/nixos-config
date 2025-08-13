{
  reIf,
  ...
}:
reIf {
  virtualisation.oci-containers.containers.ipex-llm-container = {

    image = "intelanalytics/ipex-llm-inference-cpp-xpu:latest";

    volumes = [ "/var/lib/ollama/models:/models" ];
    # # pull = "always";
    # # privileged = true;
    environment = {
      DEVICE = "Arc";
      no_proxy = "localhost,127.0.0.1";
      OLLAMA_ORIGINS = "http://192.168.*";
      SYCL_PI_LEVEL_ZERO_USE_IMMEDIATE_COMMANDLISTS = "1";
      ONEAPI_DEVICE_SELECTOR = "level_zero:0";
      OLLAMA_HOST = "[::]:11434";
    };
    devices = [
      "/dev/dri:/dev/dri:rwm"
    ];
    cmd = [
      "/bin/sh"
      "-c"
      "/llm/scripts/start-ollama.sh && echo 'Startup script finished, container is now idling.' && sleep infinity"
    ];
    extraOptions = [
      "--net=host"
      "--memory=32G"
      "--shm-size=16g"
    ];
  };
}
