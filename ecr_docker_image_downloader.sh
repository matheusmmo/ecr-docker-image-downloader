#!/bin/bash

set -e

[[ -x "$(command -v jq)" ]] || (echo "You need to have jq installed. Go to https://stedolan.github.io/jq/download to see how you can install it." >&2; exit 1;)

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

echo $(aws ecr describe-repositories)
exit;

repositories="$(aws ecr describe-repositories | jq '.repositories')"

options=()
i=0;
for row in $(echo "${repositories}" | jq -r '.[] | @base64'); do  
  _jq() {
   echo ${row} | base64 --decode | jq -r ${1}
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
  [[ "${choices[i]}" ]] && docker pull $options;
done