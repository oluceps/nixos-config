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
    rev = "9b0a5bfad61884c6d7197cbac38e2247a492076b";
    sha256 = "sha256-znZjAEzTDSVdvgrbML2w+PsCRkLiLmg6457MJ+jzVKM=";
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
