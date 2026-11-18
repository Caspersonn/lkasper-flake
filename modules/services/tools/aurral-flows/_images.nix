{ pkgs }:
{
  aurral = pkgs.aurral-flows-image or (pkgs.callPackage ../../../nix/overlays/_aurral-image.nix { });
  slskd = pkgs.dockerTools.pullImage {
    imageName = "slskd/slskd";
    imageDigest = "sha256:d7aa04ffa556df72ca207a6bcc6c64a728f40b7f9126b313da16f23eaf0c26fe";
    sha256 = "sha256-1Tt1S7UBXwztOjnumMuyzlqdO53TNr9xAQLJoTJch58=";
    finalImageTag = "latest";
    os = "linux";
    arch = "amd64";
  };
}
