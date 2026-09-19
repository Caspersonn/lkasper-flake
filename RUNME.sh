#!/usr/bin/env sh
#(C)2019-2022 Pim Snel - https://github.com/mipmip/RUNME.sh
ALLARGS=("$@");CMDS=();DESC=();NARGS=$#;ARG1=$1;make_command(){ CMDS+=($1);DESC+=("$2");};usage(){ printf "\nUsage: %s [command]\n\nCommands:\n" $0;line="              ";for((i=0;i<=$(( ${#CMDS[*]} -1));i++));do printf "  %s %s ${DESC[$i]}\n" ${CMDS[$i]} "${line:${#CMDS[$i]}}";done;echo;};runme(){ if test $NARGS -gt 0;then eval "$ARG1"||usage;else usage;fi;}


EXTRA_ARG=$2

make_command "nixclean" "Run nix garbage collector"
nixclean(){
  sudo nix-collect-garbage -d
  nix-collect-garbage -d
  sudo rm -Rf /root/.cache/nix/eval-cache-v2
}
make_command "nixcleanyesterday" "Run nix garbage collector delete yesterday and older"
nixcleanyesterday(){
  sudo nix-collect-garbage --delete-older-than 1d
  nix-collect-garbage -d
  sudo rm -Rf /root/.cache/nix/eval-cache-v2
}

make_command "nixoptimise" "Run nix store optimise"
nixoptimise(){
  sudo nix store optimise
}

make_command "reload_tmux" "Reload TMUX Configuration"
reload_tmux(){
  tmux source ~/.config/tmux/tmux.conf
}

make_command "pcirescan" "Rescan for devices that don't wake up"
pcirescan(){
  sudo echo "1" /sys/bus/pci/rescan
}

check_untracked(){

  # Check for untracked files only
  if [[ -n $(git status --porcelain | grep '^??') ]]; then
    echo "Error: There are untracked files. Please add or remove them first."
    git status --short | grep '^??'
    exit 1
  fi

}

make_command "git_sync_machine" "Commit latest version with hostname tag"
git_sync_machine(){
  if [[ -z "$EXTRA_ARG" ]]; then
    echo "Please enter a small commit message"
    exit 1
  fi
  git commit -m "$EXTRA_ARG" -a
  TAG_NAME="$(hostname)-$(date --iso-8601)"
  # Remove existing tag locally and remotely if it exists
  git tag -d "$TAG_NAME" 2>/dev/null || true
  git push origin --delete "$TAG_NAME" 2>/dev/null || true
  # Create new tag and push
  git tag "$TAG_NAME"
  git push --tags
}

make_command "up_home" "Add latest home-manager updates"
up_home(){
  RICING=$(hmrice status | grep RICING | wc -l)
  if [ $RICING -gt 0 ]; then
    echo "Unrise first (hmrice unrice), then run again"
  else
    check_untracked
    home-manager switch -b $(date --iso-8601=minutes) --impure --flake .\#$USER@$(hostname)
  fi

  # Only sync if home-manager succeeded
  #if [ $? -eq 0 ]; then
  #  EXTRA_ARG="auto run after home-manager switch"
  #  git_sync_machine
  #else
  #  echo "home-manager switch failed, skipping git sync"
  #  exit 1
  #fi


}

make_command "up_machine" "Add latest home-manager updates"
up_machine(){

  check_untracked

  HOSTNAME=$(hostname)
  # List of hostnames that need resource limitations
  LIMITED_HOSTS="harry hurry"

  if echo "$LIMITED_HOSTS" | grep -wq "$HOSTNAME"; then
    sudo nixos-rebuild switch --flake .#$HOSTNAME --max-jobs 1 -j 1 --cores 1
  else
    sudo nixos-rebuild switch --flake .#$HOSTNAME
  fi

  # Only sync if nixos-rebuild succeeded
  #if [ $? -eq 0 ]; then
  #  EXTRA_ARG="auto run after nixos-rebuild switch"
  #  git_sync_machine
  #else
  #  echo "nixos-rebuild failed, skipping git sync"
  #  exit 1
  #fi
}

# MACHINE BOOTSTRAP COMMAND
make_command "setup_aws_key" "bootstrap AWS configuration on new machine"
setup_aws_key(){
  mkdir -p ~/.aws
  chmod 700 ~/.aws

  if [ ~/.aws/credentials ]; then
    cp ~/.aws/credentials ~/.aws/credentials.bak
    chmod 600 ~/.aws/credentials.bak
  fi
  age --decrypt -i ~/.ssh/id_ed25519 ./secrets/aws_credentials.age > ~/.aws/credentials
  chmod 600 ~/.aws/credentials

  if [ ~/.aws/config ]; then
    cp ~/.aws/config ~/.aws/config.bak
    chmod 600 ~/.aws/config.bak
  fi
  age --decrypt -i ~/.ssh/id_ed25519 ./secrets/aws_config.age > ~/.aws/config
  chmod 600 ~/.aws/config

  copy_aws_other_accounts
  technativeawsupdate
}

make_command "technativeawsupdate" "update AWS account info from technative"
technativeawsupdate(){
  aws-mfa --profile technative --device arn:aws:iam::521402697040:mfa/Ideapad15
  aws --profile=TN-web_dns s3 cp s3://docs-mcs.technative.eu-longhorn/managed_service_accounts.json ~/.aws/
  echo "Don't forget to run home-manager again"
}

make_command "copy_aws_other_accounts" "copy AWS other accounts"
copy_aws_other_accounts(){
  age --decrypt -i ~/.ssh/id_ed25519 ./secrets/aws-accounts.json.age > ~/.aws/other_accounts.json
  chmod 600 ~/.aws/other_accounts.json
  echo "Don't forget to run home-manager again"

}

make_command "copy_privkey_to_remote" "copy personal privkey to remote host I trust"
copy_privkey_to_remote(){
  if [[ -z ${ALLARGS[1]} ]] then
    echo "enter something like pim@...."
  fi
  echo
  echo "making 1st SSH connection"
  ssh -o PubkeyAuthentication=no -o PreferredAuthentications=password ${ALLARGS[1]} "mkdir -p ~/.ssh && chmod 700 ~/.ssh"
  echo
  echo "Decrypt key for sending to remote"
  KEY="$(age --decrypt -i ~/.ssh/id_ed25519 ./secrets/pimprived.age)"
  echo
  echo "Making 2nd SSH connection"
  echo "$KEY" | ssh -o PubkeyAuthentication=no -o PreferredAuthentications=password ${ALLARGS[1]} "cat > ~/.ssh/id_ed25519"

  echo
  echo "Making last SSH connection"
  ssh -o PubkeyAuthentication=no -o PreferredAuthentications=password ${ALLARGS[1]} "chmod 600 ~/.ssh/id_ed25519"
}

make_command "nebula" "Manage the nebula mesh PKI (list | init-ca | sign <host> | sign-all)"
nebula(){
  nix run .#nebula-admin -- "${ALLARGS[@]:1}"
}

runme
