#!/usr/bin/env bash

# exit when any check returns non-zero
set -eu

# look up any yml file in this directory, excluding others with '!'
find . -maxdepth 1 -name '*.yml' ! -name 'requirements.yml' ! -name 'docker-compose*.yml' \
| while read playbook; do
    echo "checking ${playbook}"
    ansible-playbook -i 'localhost' --syntax-check ${playbook}
done

echo "playbooks successfully syntax checked"
