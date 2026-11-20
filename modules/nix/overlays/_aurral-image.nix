{ dockerTools }:
dockerTools.pullImage {
  imageName = "ghcr.io/lklynet/aurral";
  imageDigest = "sha256:139d892e3ebd45dd5948ca89e9b0aa679fd935d5848ce97873a6ef9db312f64a";
  sha256 = "sha256-MV7aG4Ui/bwk90xTchUFYAMkN7uZH2LMliMM6DFweCw=";
  finalImageTag = "latest";
  os = "linux";
  arch = "amd64";
}
