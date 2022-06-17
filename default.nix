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
  script = "$out/bin/${drv.name}.deploy";
in runCommand "${drv.name}-deploy" {
  inherit storeDir;
} ''
  mkdir -p $out/bin
  cat ${./template.sh} > ${script}
  extraVars=$(cat <<EOF
  ROOT_PATH='${rootPath}'
  STORE='${storeDir}'
  RSTORE='${rstoreDir}'
  STORE_LEN=${toString (stringLength storeDir)}
  MAX_PATH_LEN=$(${computeMaxPathLength} ${storePaths})
  EOF
  )
  substituteInPlace ${script} \
    --replace '#VAR_PLACEHOLDER' "$extraVars"

  skip=$(cat ${script}|wc -l)
  substituteInPlace ${script} \
    --replace '#SKIP_PLACEHOLDER' "$skip"

  tar c \
    --owner=0 \
    --group=0 \
    --mode=u+r,uga+r \
    --hard-dereference \
    -P --transform='s#${storeDir}#${rstoreDir}#g' \
    -T '${storePaths}'|gzip >> ${script}

  chmod +x ${script}
''
