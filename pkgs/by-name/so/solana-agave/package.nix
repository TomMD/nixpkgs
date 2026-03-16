{
  lib,
  stdenv,
  buildPackages,
  fetchFromGitHub,
  rustPlatform,
  rustfmt,
  installShellFiles,
  pkg-config,
  apple-sdk_15,
  udev,
  openssl,
  libz,
  protobuf,
  cmake,
  gnumake,
  clang,
  llvm,
  llvmPackages,
  rocksdb,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "solana-agave";
  version = "2.3.12";

  src = fetchFromGitHub {
    owner = "TomMD";
    repo = "agave";
    rev = "b91351fbd8bae1a6148cff75904c358b187898ee";  # FOLLOW fix-platform-tools-path-handling branch
    hash = "sha256-Cp4n2+6pxE3wq78SG28i82+5p8Xa50UYy2cjx0lllzs=";
  };

  cargoHash = "sha256-zfydH8HiRjJDw4wH/3sF3tch+NIaHUf+2TLrNDWPAb0=";

  cargoPatches = [
  ];

  nativeBuildInputs = [
    installShellFiles
    protobuf
    cmake
    gnumake
    clang
    llvm
    llvmPackages.bintools
    openssl.dev
    pkg-config
    rustfmt
  ];
  buildInputs = [
    openssl
    libz
    rustPlatform.bindgenHook
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [ apple-sdk_15 ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [ udev ];

  doInstallCheck = false;

  env = {
    # If set, always finds OpenSSL in the system, even if the vendored feature is enabled.
    OPENSSL_NO_VENDOR = 1;
    # Agave uses deny(warnings) which breaks when nixpkgs updates rustc.
    # Cap lints to warnings so the build doesn't fail on new compiler lints.
    RUSTFLAGS = "--cap-lints warn";
    # Use the pre-built rocksdb from nixpkgs instead of compiling from source.
    # This avoids GCC 13+ compatibility issues with missing <cstdint> includes.
    ROCKSDB_LIB_DIR = "${rocksdb}/lib";
  };

  # Disabling tests because:
  #
  # ```
  # running 3 tests
  # test args::tests::test_max_genesis_archive_unpacked_size_constant ... ok
  # test bigtable::tests::test_missing_blocks ... ok
  # error: test failed, to rerun pass `-p agave-ledger-tool --bin agave-ledger-tool`
  #
  # Caused by:
  #   process didn't exit successfully: `/build/source/target/x86_64-unknown-linux-gnu/release/deps/agave_ledger_tool-b8aca978c218ed51` (signal: 4, SIGILL: illegal instruction)
  # ```
  #
  # Almost certainly caused by the ledger-tool test calling `Command::cargo_bin` which assumes a good bit about the current environment.
  doCheck = false;

  meta = {
    description = "Solana Network Validator";
    homepage = "https://github.com/TomMD/agave";
    changelog = "https://github.com/TomMD/agave/releases/tag/${finalAttrs.version}";
    license = with lib.licenses; [
      asl20
    ];
    maintainers = with lib.maintainers; [
      TomMD
    ];
    mainProgram = "agave";
  };
})
