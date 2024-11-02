{
  description = "Wasm-friendly rust development flake";

  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      eachSystem =
        with nixpkgs.lib;
        f: foldAttrs mergeAttrs { } (map (s: mapAttrs (_: v: { ${s} = v; }) (f s)) systems);
    in
    eachSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        pkgsWasm = import nixpkgs {
          inherit system;
          crossSystem = {
            config = "wasm32-unknown-unknown";
            rustc.config = "wasm32-unknown-unknown";
          };
        };
      in
      {
        devShells.default = pkgs.mkShell {
          CARGO_TARGET_WASM32_UNKNOWN_UNKNOWN_RUNNER = "wasm-bindgen-test-runner";
          nativeBuildInputs = with pkgs; [
            cargo
            cargo-watch
            nodejs
            wasm-bindgen-cli
            wasm-pack
          ];
          # shellHook = "";
        };

        packages = {
          default = self.outputs.packages.${system}.webapp;
          wasm = pkgs.callPackage ./. { };
          webapp = pkgs.runCommandLocal "app" { } ''
            mkdir -p $out
            cp "${self.outputs.packages.${system}.wasm}/pkg/icwasm.js" $out/
            cp ${./index.html} $out/index.html
            substituteInPlace $out/index.html \
              --replace-fail '"./result/pkg/icwasm.js"' '"${
                self.outputs.packages.${system}.wasm
              }/pkg/icwasm.js"'
          '';
        };

        apps.default = {
          type = "app";
          program =
            let
              script = pkgs.writeShellScriptBin "runner" ''
                ${pkgs.python3}/bin/python -m http.server -d ${self.outputs.packages.${system}.webapp} &
                pid=$!
                trap "kill \"$pid\"" EXIT
                sleep 0.5
                OPEN=$([[ "$(uname -s)" = Darwin ]] && printf open || printf xdg-open)
                "$OPEN" http://localhost:8000
                wait
              '';
            in
            "${script}/bin/runner";
        };
      }
    );
}
