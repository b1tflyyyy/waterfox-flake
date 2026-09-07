{
  description = "Waterfox browser binary flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      version = "6.7.1.1";

      archConfig = {
        x86_64-linux = {
          urlArch = "Linux_x86_64";
          hash = "sha256-eJKCbcHfTU3LG/9bUm0guzH0LpDc2dSuoohOWVlBwd4=";
        };
        aarch64-linux = {
          urlArch = "Linux_aarch64";
          hash = "sha256-q3/hTI45Faeg3ueM5z0IoowtB8Lnyu4cdP8fCgbTnio=";
        };
      };

      supportedSystems = builtins.attrNames archConfig;
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      makePackage = system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          cfg = archConfig.${system};

          src = pkgs.fetchurl {
            url = "https://cdn.waterfox.com/waterfox/releases/${version}/${cfg.urlArch}/waterfox-${version}.tar.bz2";
            hash = cfg.hash;
          };

          libPath = pkgs.lib.makeLibraryPath (with pkgs; [
            stdenv.cc.cc.lib
            zlib
            glib
            gtk3
            atk
            cairo
            gdk-pixbuf
            pango
            fontconfig
            freetype
            dbus
            dbus-glib

            libx11
            libxcomposite
            libxcursor
            libxdamage
            libxext
            libxfixes
            libxi
            libxrandr
            libxrender
            libxt
            libxtst
            libxcb
            libxscrnsaver

            wayland
            libxkbcommon
            mesa
            libGL
            libglvnd

            alsa-lib
            libpulseaudio
            pipewire
            ffmpeg

            cups
            libva
            pciutils
            udev
            curl
          ]);
        in
        pkgs.stdenv.mkDerivation {
          pname = "waterfox-bin";
          inherit version src;

          nativeBuildInputs = with pkgs; [
            patchelf
            wrapGAppsHook3
            makeWrapper
            copyDesktopItems
          ];

          buildInputs = with pkgs; [
            gtk3
            adwaita-icon-theme
            gsettings-desktop-schemas
          ];

          sourceRoot = ".";

          installPhase = ''
            runHook preInstall

            mkdir -p $out/lib/waterfox $out/bin
            cp -r waterfox/* $out/lib/waterfox/

            INTERPRETER="$(cat $NIX_CC/nix-support/dynamic-linker)"

            for bin in waterfox waterfox-bin glxtest vaapitest; do
              if [ -f "$out/lib/waterfox/$bin" ]; then
                patchelf --set-interpreter "$INTERPRETER" "$out/lib/waterfox/$bin"
              fi
            done

            makeWrapper $out/lib/waterfox/waterfox $out/bin/waterfox \
              --prefix LD_LIBRARY_PATH : "${libPath}:$out/lib/waterfox" \
              --set MOZ_APP_LAUNCHER "waterfox"

            if [ -f "waterfox/browser/chrome/icons/default/default128.png" ]; then
              install -Dm644 waterfox/browser/chrome/icons/default/default128.png \
                $out/share/icons/hicolor/128x128/apps/waterfox.png
            fi

            runHook postInstall
          '';

          desktopItems = [
            (pkgs.makeDesktopItem {
              name = "waterfox";
              exec = "waterfox %u";
              icon = "waterfox";
              desktopName = "Waterfox";
              genericName = "Web Browser";
              categories = [ "Network" "WebBrowser" ];
              mimeTypes = [
                "text/html"
                "text/xml"
                "application/xhtml+xml"
                "x-scheme-handler/http"
                "x-scheme-handler/https"
              ];
            })
          ];

          meta = with pkgs.lib; {
            description = "Waterfox is a privacy-focused browser based on Firefox";
            homepage = "https://www.waterfox.com";
            license = licenses.mpl20;
            platforms = supportedSystems;
            mainProgram = "waterfox";
          };
        };
    in
    {
      overlays.default = final: prev: {
        waterfox = self.packages.${final.stdenv.hostPlatform.system}.default;
      };

      packages = forAllSystems (system: {
        default = makePackage system;
        waterfox = makePackage system;
      });
    };
}
