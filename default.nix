{ closureInfo, writers, runCommand, coreutils, lib }:
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
  script = "$out/bin/${drv.name}.deploy";
in runCommand "${drv.name}-deploy" {
  inherit storeDir;
  buildInputs = [ coreutils ];
} ''
  mkdir -p $out/bin
  cat ${./template.head} > ${script}

  echo "ROOT_PATH='${rootPath}'" >> ${script}
  echo "STORE='${storeDir}'"     >> ${script}
  echo "RSTORE='${rstoreDir}'"   >> ${script}
  echo "STORE_LEN=${toString (stringLength storeDir)}"           >> ${script}
  echo "MAX_PATH_LEN='$(${computeMaxPathLength} ${storePaths})'" >> ${script}

  cat ${./template.body} >> ${script}
  tar c \
    --owner=0 \
    --group=0 \
    --mode=u+r,uga+r \
    --hard-dereference \
    -P --transform='s#${storeDir}#${rstoreDir}#g' \
    -T '${storePaths}'|gzip|base64 >> ${script}
  cat ${./template.tail}           >> ${script}

  chmod +x ${script}
''
