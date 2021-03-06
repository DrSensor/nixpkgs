{ lib, stdenv, fetchurl, copyDesktopItems, makeDesktopItem, unzip, jre8 }:

stdenv.mkDerivation rec {
  pname = "jquake";
  version = "1.6.1";

  src = fetchurl {
    url = "https://fleneindre.github.io/downloads/JQuake_${version}_linux.zip";
    sha256 = "0nw6xjc3i1b8rk15arc5d0ji2bycc40rz044qd03vzxvh0h8yvgl";
  };

  nativeBuildInputs = [ unzip copyDesktopItems ];

  sourceRoot = ".";

  postPatch = ''
    # JQuake emits a lot of debug-like messages in console, but I
    # don't think it's in our interest to void them by default. Log them at
    # the appropriate level.
    sed -i "/^java/ s/$/\ | logger -p user.debug/" JQuake.sh

    # By default, an 'errors.log' file is created in the current directory.
    # cd into a temporary directory and let it be created there.
    substituteInPlace JQuake.sh \
      --replace "java -jar " "exec ${jre8.outPath}/bin/java -jar $out/lib/" \
      --replace "[JAR FOLDER]" "\$(mktemp -p /tmp -d jquake-errlog-XXX)"
  '';

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    chmod +x JQuake.sh

    mkdir -p $out/{bin,lib}
    mv JQuake.sh $out/bin/JQuake
    mv {JQuake.jar,JQuake_lib} $out/lib
    mv sounds $out/lib

    mkdir -p $out/share/licenses/jquake
    mv LICENSE* $out/share/licenses/jquake

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "JQuake";
      desktopName = "JQuake";
      exec = "JQuake";
      comment = "Real-time earthquake map of Japan";
    })
  ];

  meta = with lib; {
    description = "Real-time earthquake map of Japan";
    homepage = "http://jquake.net";
    downloadPage = "https://jquake.net/?down";
    changelog = "https://jquake.net/?docu";
    maintainers = with maintainers; [ nessdoor ];
    license = licenses.unfree;
    platforms = platforms.linux;
  };
}
