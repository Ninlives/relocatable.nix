# relocatable.nix
This flake provide a nix bundler to package nix derivations into a single script that can deploy the target derivation to (hopefully) any distro.

# Benefits

- Do not need root access or `nix` for deployment.
- The deployed derivation does not rely on `userns` or `proot`, etc., to execute.

# Usage

To package chromium:
```sh
nix bundle --bundler github:Ninlives/relocatable.nix nixpkgs#chromium
```
After build, the script should be available at `./chromium-<version>-deploy/bin/chromium-<version>.deploy`.

To deploy chromium on another machine, copy the script and execute the following on the target machine:
```sh
./chromium-<version>.deploy -d /path/to/target/directory
```
After a few seconds you should be able to run chromium by executing `/path/to/target/directory/root/bin/chromium`.

# Requirement

The following commands are required to run the generated script, which should be available on most distros:
- `realpath`
- `cat`
- `base64`
- `gzip`
- `sed`
- `tar`
- `ln`
