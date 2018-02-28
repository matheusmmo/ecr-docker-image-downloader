#!/bin/bash

set -e

[[ -x "$(command -v aws)" ]] || pip install --upgrade --user awscli 

[[ -d "$HOME/.aws" ]] || mkdir $HOME/.aws

[[ -d "$HOME/.aws/credentials" ]] && mv $HOME/.aws/credentials_original
[[ -d "$HOME/.aws/config" ]] && mv $HOME/.aws/config_original

echo "[default]
aws_access_key_id=$AWS_ACCESS_KEY
aws_secret_access_key=$AWS_SECRET_KEY" > $HOME/.aws/credentials

echo "[default]
region = $AWS_DEFAULT_REGION" > $HOME/.aws/config

eval $(aws ecr get-login --no-include-email)

repositories=`aws ecr describe-repositories`;
repositories=`docker run --rm -e R="$repositories" matheusmmo/docker-jq sh -c 'echo $R | jq .repositories'`;

options=()
i=0;
for row in `docker run --rm -e R="$repositories" matheusmmo/docker-jq sh -c 'echo $R | jq -r ".[] | @base64"'`; do
  row=`echo $row | python -m base64 -d`

  _jq() {
    docker run --rm -e R="$row" -e P="${1}" matheusmmo/docker-jq sh -c 'echo $R | jq -r $P';
  }

  options[i]=$(_jq '.repositoryUri')
  
  ((i+=1))
done

### options menu

menu() {
  echo "Avaliable options:"
  for i in ${!options[@]}; do 
      printf "%3d%s) %s\n" $((i+1)) "${choices[i]:- }" "${options[i]}"
  done
  [[ "$msg" ]] && echo "$msg"; :
}

prompt="Check an option (again to uncheck, ENTER when done): "
while menu && read -rp "$prompt" num && [[ "$num" ]]; do
  [[ "$num" != *[![:digit:]]* ]] &&
  (( num > 0 && num <= ${#options[@]} )) ||
  { msg="Invalid option: $num"; continue; }
  ((num--)); msg="${options[num]} was ${choices[num]:+un}checked"
  [[ "${choices[num]}" ]] && choices[num]="" || choices[num]="+"
done

printf "You selected"; msg=" nothing"
for i in ${!options[@]}; do 
  [[ "${choices[i]}" ]] && { printf " %s" "${options[i]}"; msg=""; }
done
echo "$msg"

for i in ${!options[@]}; do
  [[ "${choices[i]}" ]] && docker pull "${options[i]}";
done
