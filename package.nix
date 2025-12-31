{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  makeWrapper,
  wrapGAppsHook3,
  autoPatchelfHook,
  # Runtime dependencies
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  curl,
  dbus,
  expat,
  glib,
  gtk3,
  libdrm,
  libGL,
  libxkbcommon,
  mesa,
  nspr,
  nss,
  pango,
  systemd,
  xorg,
  libxkbfile,
  # Wayland
  wayland,
}:

let
  version = "2.2.44";
  sha256 = "9f86f1dd34f8afae694667ce9a14f613589a31337d8d60c039d6920feb87f5d5";

  runtimeDeps = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    curl
    dbus
    expat
    glib
    gtk3
    libdrm
    libGL
    libxkbcommon
    mesa
    nspr
    nss
    pango
    systemd
    wayland
    libxkbfile
    xorg.libX11
    xorg.libXcomposite
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXrandr
    xorg.libxcb
  ];

in
stdenv.mkDerivation {
  pname = "cursor";
  inherit version;

  src = fetchurl {
    url = "https://downloads.cursor.com/aptrepo/pool/stable/c/cu/cursor_${version}_amd64.deb";
    inherit sha256;
  };

  nativeBuildInputs = [
    dpkg
    makeWrapper
    wrapGAppsHook3
    autoPatchelfHook
  ];

  buildInputs = runtimeDeps;

  unpackPhase = ''
    runHook preUnpack
    # Use dpkg-deb with --fsys-tarfile to extract without setuid issues
    mkdir -p extracted
    dpkg-deb --fsys-tarfile $src | tar -xf - -C extracted --no-same-owner --no-same-permissions
    mv extracted/* .
    rm -rf extracted
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib $out/share $out/bin

    # copy cursor app files
    cp -r usr/share/cursor $out/lib/cursor
    
    # copy desktop files, icons, completions, etc.
    cp -r usr/share/applications $out/share/ || true
    cp -r usr/share/appdata $out/share/ || true
    cp -r usr/share/bash-completion $out/share/ || true
    cp -r usr/share/icons $out/share/ 2>/dev/null || true
    cp -r usr/share/pixmaps $out/share/ 2>/dev/null || true

    # fix desktop file paths
    if [ -f $out/share/applications/cursor.desktop ]; then
      substituteInPlace $out/share/applications/cursor.desktop \
        --replace-fail "/usr/share/cursor/cursor" "$out/bin/cursor"
    fi
    
    if [ -f $out/share/applications/cursor-url-handler.desktop ]; then
      substituteInPlace $out/share/applications/cursor-url-handler.desktop \
        --replace-fail "/usr/share/cursor/cursor" "$out/bin/cursor"
    fi

    # wrap the binary with runtime deps and electron flags
    makeWrapper $out/lib/cursor/cursor $out/bin/cursor \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeDeps}" \
      --add-flags "--ozone-platform-hint=auto" \
      --add-flags "--enable-features=WaylandWindowDecorations"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Cursor - The AI Code Editor";
    homepage = "https://cursor.com";
    license = licenses.unfree;
    maintainers = [];
    platforms = [ "x86_64-linux" ];
    mainProgram = "cursor";
  };
}
