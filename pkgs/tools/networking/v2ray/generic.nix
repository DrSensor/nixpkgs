{ lib, linkFarm, buildGoPackage, runCommand, makeWrapper, go

# Version specific args
, version, src, assets
, ... }:

let
  assetsDrv = linkFarm "v2ray-assets" (lib.mapAttrsToList (name: path: {
    inherit name path;
  }) assets);

  core = buildGoPackage rec {
    pname = "v2ray-core";
    inherit version src;

    goPackagePath = "v2ray.com/core";
    goDeps = ./deps.nix;

    nativeBuildInputs = [ go ];

    buildPhase = ''
      runHook preBuild

      go build -o v2ray v2ray.com/core/main
      go build -o v2ctl v2ray.com/core/infra/control/main

      runHook postBuild
    '';

    installPhase = ''
      install -Dm755 v2ray v2ctl -t $bin/bin
    '';
  };

in runCommand "v2ray-${version}" {
  inherit version;

  buildInputs = [ assetsDrv core ];
  nativeBuildInputs = [ makeWrapper ];

  meta = {
    homepage = "https://www.v2ray.com/en/index.html";
    description = "A platform for building proxies to bypass network restrictions";
    license = with lib.licenses; [ mit ];
    maintainers = with lib.maintainers; [ servalcatty ];
  };

} ''
  for file in ${core}/bin/*; do
    makeWrapper "$file" "$out/bin/$(basename "$file")" \
      --set-default V2RAY_LOCATION_ASSET ${assetsDrv}
  done
''
