{ stdenv
, lib
, fetchFromGitHub
, meson
, gettext
, glib
, gjs
, ninja
, gtk4
, webkitgtk
, gsettings-desktop-schemas
, wrapGAppsHook
, desktop-file-utils
, gobject-introspection
, glib-networking
, pkg-config
, appstream-glib
, adw-gtk3
, libadwaita
, webkitgtk_6_0
}:

stdenv.mkDerivation {
  pname = "foliate";
  version = "unstable";

  src = fetchFromGitHub {
    owner = "johnfactotum";
    repo = "foliate";
    rev = "a3cfb71ab60a235103a565be4d269e2a5d84adee";
    hash = "sha256-BxNYg4Kxc7YW+L1Di/PdT1TKWZsOQ5VN8KpEgQ7X9L4=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [ meson ninja wrapGAppsHook pkg-config ];

  buildInputs = [
    gettext
    glib
    glib-networking
    gjs
    gtk4
    webkitgtk
    desktop-file-utils
    gobject-introspection
    gsettings-desktop-schemas
    appstream-glib
    libadwaita
    adw-gtk3
    webkitgtk_6_0
  ];

  meta = with lib; {
    description = "A simple and modern GTK eBook reader";
    homepage = "https://johnfactotum.github.io/foliate/";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ onny ];
  };
}
