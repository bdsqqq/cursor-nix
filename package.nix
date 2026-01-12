{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  makeWrapper,
  wrapGAppsHook3,
  autoPatchelfHook,
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
  wayland,
}:

let
  version = "2.3.34";
  sha256 = "87ba3c55f8c2a4e5961df59be987f26426ddfef841bbdc71e9bc9c3ca074638a";
  upstreamFilename = "pool/stable/c/cu/cursor_2.3.34_amd64.deb";

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
    url = "https://downloads.cursor.com/aptrepo/${upstreamFilename}";
    inherit sha256;
  };

  nativeBuildInputs = [
    dpkg
    makeWrapper
    wrapGAppsHook3
    autoPatchelfHook
  ];

  buildInputs = runtimeDeps;

  # dpkg-deb --fsys-tarfile avoids fakeroot/setuid issues that break nix sandbox
  unpackPhase = ''
    runHook preUnpack
    mkdir -p extracted
    dpkg-deb --fsys-tarfile $src | tar -xf - -C extracted --no-same-owner --no-same-permissions
    mv extracted/* .
    rm -rf extracted
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib $out/share $out/bin

    cp -r usr/share/cursor $out/lib/cursor
    cp -r usr/share/applications $out/share/ || true
    cp -r usr/share/appdata $out/share/ || true
    cp -r usr/share/bash-completion $out/share/ || true
    cp -r usr/share/icons $out/share/ 2>/dev/null || true
    cp -r usr/share/pixmaps $out/share/ 2>/dev/null || true

    if [ -f $out/share/applications/cursor.desktop ]; then
      substituteInPlace $out/share/applications/cursor.desktop \
        --replace-fail "/usr/share/cursor/cursor" "$out/bin/cursor" \
        --replace-warn "Icon=co.anysphere.cursor" "Icon=$out/lib/cursor/resources/app/resources/linux/code.png"
    fi
    
    if [ -f $out/share/applications/cursor-url-handler.desktop ]; then
      substituteInPlace $out/share/applications/cursor-url-handler.desktop \
        --replace-fail "/usr/share/cursor/cursor" "$out/bin/cursor" \
        --replace-warn "Icon=co.anysphere.cursor" "Icon=$out/lib/cursor/resources/app/resources/linux/code.png"
    fi

    # --no-sandbox required: we strip setuid during extraction, so chrome-sandbox can't elevate
    makeWrapper $out/lib/cursor/cursor $out/bin/cursor \
      --add-flags "--no-sandbox" \
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
