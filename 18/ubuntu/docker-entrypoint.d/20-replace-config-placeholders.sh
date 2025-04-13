#!/bin/sh

###
# Search file contents of `/etc/asterisk` directory.
# If a placeholder with `{{ VARIABLE_EXAMPLE }}` format is found, it tries to replace it from corresponding
# environment variable ($VARIABLE_EXAMPLE). If the environment variable is not defined, script will exit
# with error code 1.
###

echo "Replacing placeholders in /etc/asterisk directory..."
counter=0

for match in $(grep -Pron /etc/asterisk -e "\{\{\s*\K(.+?)(?=\s*\}\})")
do
  file=$(echo $match | cut -d: -f1)
  line=$(echo $match | cut -d: -f2)
  variable=$(echo $match | cut -d: -f3)
  value="$(eval 'echo $'"$variable")"
  # value="${!variable}" # works in bash

  if [ "$value" ]; then
    sed -i "s|{{\s*$variable\s*\}\}|$value|g" $file
    echo "[SUCCESS] Replaced '{{ $variable }}' in '$file:$line' successfully."
    counter=$((counter + 1))
  else
    echo "[ ERROR ] $variable environment variable has been used in $file, line $line but is not declared." >&2
    exit 1
  fi
done

if [ "$counter" -eq "0" ]; then
  echo "Found no placeholders to replace."
else
  echo "Successfully replaced $counter placeholders."
fi
