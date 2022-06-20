{ closureInfo, writers, runCommand, lib }:
drv:
with lib;
let
  normalize = path: "${builtins.toPath path}/";
  storeDir = normalize builtins.storeDir;
  rstoreDir = concatStrings (reverseList (stringToCharacters storeDir));
  storePaths = "${closureInfo { rootPaths = drv; }}/store-paths";
  rootPath = normalize "${rstoreDir}${baseNameOf drv}";
  computeMaxPathLength =
    writers.writePython3 "compute" { flakeIgnore = [ "E501" ]; }
    (builtins.readFile ./max-path-len.py);
  computeOffset =
    writers.writePython3 "compute" { } (builtins.readFile ./offset.py);
  script = "${placeholder "out"}/bin/${drv.name}.deploy";
in runCommand "${drv.name}-deploy" { } ''
  mkdir -p $out/bin
  cat ${./template.sh} > ${script}

  substituteInPlace '${script}' \
    --replace '#ROOT_PATH#'    '${rootPath}' \
    --replace '#STORE#'        '${storeDir}' \
    --replace '#RSTORE#'       '${rstoreDir}' \
    --replace '#STORE_LEN#'    '${toString (stringLength storeDir)}' \
    --replace '#MAX_PATH_LEN#' "$(${computeMaxPathLength} '${storePaths}' '${storeDir}')"

  substituteInPlace '${script}' \
    --replace '#OFFSET#' "$(${computeOffset} '${script}' '#OFFSET#')"

  tar c \
    --owner=0 \
    --group=0 \
    --mode=u+r,uga+r \
    --hard-dereference \
    -P --transform='s#${storeDir}#${rstoreDir}#g' \
    -T '${storePaths}'|gzip >> ${script}

  HASH_PLACEHOLDER='#SHA256SUMXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX#'
  HASH=$(dd if='${script}'|sed -r "s/$HASH_PLACEHOLDER//"|sha256sum)
  sed -i -e "s/$HASH_PLACEHOLDER/$HASH/" '${script}'

  chmod +x '${script}'
''
