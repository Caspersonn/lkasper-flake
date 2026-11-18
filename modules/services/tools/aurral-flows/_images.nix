{ pkgs }:
{
  aurral = pkgs.dockerTools.pullImage {
    imageName = "ghcr.io/lklynet/aurral";
    imageDigest = "sha256:b8ceecf5e749474dc54f0393ad8b79e49cb2811f09e646d23ea93f347317c434";
    sha256 = "sha256-VO2zdToFh0CUND05CEzMIf9vVSy3z3lQUCItzpZK6WA=";
    finalImageTag = "latest";
    os = "linux";
    arch = "amd64";
  };
  slskd = pkgs.dockerTools.pullImage {
    imageName = "slskd/slskd";
    imageDigest = "sha256:d7aa04ffa556df72ca207a6bcc6c64a728f40b7f9126b313da16f23eaf0c26fe";
    sha256 = "sha256-1Tt1S7UBXwztOjnumMuyzlqdO53TNr9xAQLJoTJch58=";
    finalImageTag = "latest";
    os = "linux";
    arch = "amd64";
  };
}
