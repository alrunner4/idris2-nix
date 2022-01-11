{ nixpkgs ? import <nixpkgs> {}
, idris2 ? if builtins.pathExists ~/.idris2/default.nix
           then builtins.trace "using ~/.idris2" (import ~/.idris2 nixpkgs)
           else nixpkgs.idris2
, APP_NAME
, IDRIS2_SOURCE_DIR
, IDRIS2_MAIN ? "Main.idr"
, IDRIS2_PREFIX ? if builtins.hasAttr "IDRIS2_PREFIX" idris2
                  then idris2.IDRIS2_PREFIX
                  else builtins.toString ~/.idris2
, LAUNCHER_LD_LIBRARY_PATH ? ""
}: let

CHMODX = "${nixpkgs.coreutils}/bin/chmod +x";
COPY   = "${nixpkgs.coreutils}/bin/cp";
IDRIS2 = "${idris2}/bin/idris2";
MKDIRP = "${nixpkgs.coreutils}/bin/mkdir -p";
SCHEME = "${nixpkgs.chez}/bin/scheme";
SHELL  = "${nixpkgs.bash}/bin/bash";

DD = filename: "${nixpkgs.coreutils}/bin/dd of=${filename}";

in derivation {
   name = APP_NAME;
   system = builtins.currentSystem;
   inherit APP_NAME IDRIS2 IDRIS2_MAIN IDRIS2_PREFIX LAUNCHER_LD_LIBRARY_PATH SCHEME IDRIS2_SOURCE_DIR;
   builder = nixpkgs.writeScript "idris-app-builder" ''
      #!${SHELL}
      set -e
      PATH+=:$SCHEME/bin:${nixpkgs.coreutils}/bin
      $IDRIS2 --source-dir $IDRIS2_SOURCE_DIR --build-dir $TMP --output $APP_NAME \
         $IDRIS2_SOURCE_DIR/$IDRIS2_MAIN

      ${MKDIRP} $out/lib
      ${COPY} $TMP/exec/"$APP_NAME"_app/*.so $out/lib/

      ${MKDIRP} $out/bin
      ${DD "$out/bin/$APP_NAME"} <<LAUNCHER
      #!${SHELL}
      export LD_LIBRARY_PATH=$out/lib:$LAUNCHER_LD_LIBRARY_PATH
      exec $out/lib/$APP_NAME.so "\$@"
      LAUNCHER
      ${CHMODX} $out/bin/$APP_NAME
      '';
}
