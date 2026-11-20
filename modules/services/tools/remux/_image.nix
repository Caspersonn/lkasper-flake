{ dockerTools }:
dockerTools.pullImage {
  imageName = "ghcr.io/lostb1t/remux";
  imageDigest = "sha256:a4cc0703ba418b3826db04942482419460d4cc68eb70f8221874bde1e6358ab1";
  hash = "sha256-DCl2nU3JlxaoEwvZ/r0oEthYTxhwFA9zWfdMNW9uBM0=";
  finalImageTag = "latest";
  os = "linux";
  arch = "amd64";
}
