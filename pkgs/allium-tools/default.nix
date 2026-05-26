{ lib, rustPlatform, fetchFromGitHub }:

rustPlatform.buildRustPackage rec {
  pname = "allium";
  version = "3.2.3";

  src = fetchFromGitHub {
    owner = "juxt";
    repo = "allium-tools";
    rev = "v${version}";
    hash = "sha256-5irbrB50JSY2QiWfLtzzXa2e5HAfsCk0M5j6W3C8syA=";
  };

  cargoHash = "sha256-Q6bbe9J7wIVzx/vMikFgqJHMVOnw2ZFaYS6hseb3en8=";

  cargoBuildFlags = [ "-p" "allium-cli" ];

  meta = {
    description = "CLI for checking and analysing Allium specification files";
    homepage = "https://github.com/juxt/allium-tools";
    license = lib.licenses.mit;
    maintainers = [ ];
    mainProgram = "allium";
  };
}
