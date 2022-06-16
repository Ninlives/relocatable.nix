{ closureInfo, writers, runCommand, gnutar, coreutils, lib }:
drv:
with lib;
let
  normalize = path: "${builtins.toPath path}/";
  storeDir = normalize builtins.storeDir;
  rstoreDir = concatStrings (reverseList (stringToCharacters storeDir));
  storePaths = "${closureInfo { rootPaths = drv; }}/store-paths";
  rootPath = normalize "${rstoreDir}${baseNameOf drv}";
  computeMaxPathLength =
    writers.writePython3 "compute" { flakeIgnore = [ "E501" ]; } (builtins.readFile ./max-path-len.py);
in runCommand "${drv.name}-deploy" { inherit storeDir; buildInputs = [ gnutar coreutils ]; } ''
  mkdir -p $out/bin
  cat > $out/bin/${drv.name}.deploy << EOF
  ${builtins.replaceStrings [ "$" "#VAR_PLACEHOLDER" "#DATA_PLACEHOLDER" ] [
    "\\$"
    ''
      ROOT_PATH='${rootPath}'
      STORE='${storeDir}'
      RSTORE='${rstoreDir}'
      STORE_LEN=${toString (stringLength storeDir)}
      MAX_PATH_LEN='$(${computeMaxPathLength} ${storePaths})'
    ''
    "$(tar c --owner=0 --group=0 --mode=u+rw,uga+r --hard-dereference -P --transform='s#${storeDir}#${rstoreDir}#g' -T '${storePaths}'|gzip|base64)"
  ] (builtins.readFile ./template.sh)}
  EOF
  chmod +x $out/bin/${drv.name}.deploy
''
