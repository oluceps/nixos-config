{
  lib,
  telegram-desktop,
  fetchFromGitHub,
}:
telegram-desktop.overrideAttrs (
  self: super: {
    pname = "materialgram";
    version = "5.4.1.1";

    src = fetchFromGitHub {
      owner = "kukuruzka165";
      repo = "materialgram";
      rev = "v${self.version}";
      fetchSubmodules = true;
      hash = "sha256-enA/8mIXcRTPGyZFgZ5Wg4fWq4fD4rtjH7bm/32FZaE";
    };

    meta = super.meta // {
      description = "Telegram Desktop fork with material icons and some improvements";
      longDescription = ''
        Telegram Desktop fork with Material Design and other improvements,
        which is based on the Telegram API and the MTProto secure protocol.
      '';
      homepage = "https://kukuruzka165.github.io/materialgram";
      changelog = "https://github.com/${self.src.owner}/${self.src.repo}/releases/tag/${self.src.rev}";
      mainProgram = "materialgram";
    };
  }
)
