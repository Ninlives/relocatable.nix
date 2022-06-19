# relocatable.nix
This flake provide a nix bundler to package nix derivations into a single script that can deploy the target derivation to (hopefully) any distro.

# Benefits

- Do not need root access or `nix` for deployment.
- The deployed derivation does not rely on `userns` or `proot`, etc., to execute.

# Usage

## Package

To package chromium:
```sh
nix bundle --bundler github:Ninlives/relocatable.nix nixpkgs#chromium
```
After build, the script should be available at `./chromium-<version>-deploy/bin/chromium-<version>.deploy`.

## Deploy

To deploy chromium on another machine, copy the script and execute the following on the target machine:
```sh
./chromium-<version>.deploy -d /path/to/target/directory
```
After a few seconds you should be able to run chromium by executing `/path/to/target/directory/root/bin/chromium`.

## Verify Integrity

To verify the integrity of the above script, just run:
```sh
./chromium-<version>.deploy -v
```
This operation requires `sha256sum` command.

# Requirement

The following commands are required to run the deployment operation, which should be available on most distros:
- `dd`
- `ln`
- `sed`
- `tar`
- `gzip`

The following commands are required for integrity verification:
- `dd`
- `sed`
