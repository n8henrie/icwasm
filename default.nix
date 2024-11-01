{
  lib,
  binaryen,
  llvmPackages,
  nodejs,
  rustPlatform,
  wasm-bindgen-cli,
  wasm-pack,
}:
rustPlatform.buildRustPackage {
  name = "icwasm";
  src = ./.;
  cargoLock.lockFile = ./Cargo.lock;
  cargoBuildFeatures = [ "console_error_panic_hook" ];

  RUSTFLAGS = [
    "-C"
    "linker=lld"
  ];

  # lld: error: unknown argument '-Wl,--undefined=AUDITABLE_VERSION_INFO'
  # https://github.com/cloud-hypervisor/rust-hypervisor-firmware/issues/249
  auditable = false;

  buildInputs = [
    wasm-pack
  ];
  nativeBuildInputs = [
    binaryen
    llvmPackages.bintools
    wasm-bindgen-cli
  ];

  configurePhase = ''
    # Error: Operation not permitted (os error 1)
    # Caused by: Operation not permitted (os error 1)
    export HOME=$(mktemp -d)

    # error: failed to get macosx SDK path: No such file or directory (os error 2)
    export SDKROOT=$(mktemp -d)
  '';

  buildPhase = ''
    ${lib.getExe wasm-pack} build . \
      --target web \
      --mode no-install
  '';

  installPhase = ''
    mkdir -p $out/pkg
    cp -r pkg/* $out/pkg
  '';

  nativeCheckInputs = [ nodejs ];

  checkPhase = ''
    WASM_BINDGEN_TEST_ONLY_NODE=1 \
      CARGO_TARGET_WASM32_UNKNOWN_UNKNOWN_RUNNER=wasm-bindgen-test-runner \
      cargo test --target wasm32-unknown-unknown
  '';
}
