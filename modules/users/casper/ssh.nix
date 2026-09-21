
{ lib, inputs, self, ... }: {
  flake.modules.homeManager.casper-ssh = { pkgs, config, ... }: {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings = {
        "github.com" = {
          HostName = "github.com";
          User = "caspersonn";
          IdentityFile = "~/.ssh/id_ed25519";
        };

        "Host i-*" = {
          IdentityFile = "~/.ssh/technative-awsaccounts-workloads-key";
          User = "root";
          ProxyCommand = lib.concatStringsSep " " [ "sh -c" "\"aws ec2-instance-connect send-ssh-public-key" "--instance-id %h --instance-os-user %r" "--ssh-public-key 'file:///home/casper/.ssh/technative-awsaccounts-workloads-key.pub'" "--availability-zone \\\"$(aws ec2 describe-instances --instance-ids %h" "--query 'Reservations[0].Instances[0].Placement.AvailabilityZone' --output text)\\\"" "&& aws ssm start-session --target %h --document-name AWS-StartSSHSession" "--parameters 'portNumber=%p'\"" ];
        };

        "Host arcana-one" = {
          IdentityFile = "~/.ssh/id_ed25519";
          User = "casper";
          Hostname = "54.93.81.45";
          Port = "7002";
        };
      };
    };
  };
}
