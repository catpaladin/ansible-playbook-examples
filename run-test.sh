#!/usr/bin/env bash

set -eu

alias docker-compose=/usr/local/bin/docker-compose
SSH_KEY_PATH=~/.ssh/dev.key

# gen SSH key if does not exist
if [[ -e ${SSH_KEY_PATH} ]]; then
    echo "Key exists."
else
    echo "No key found. Creating key..."
    ssh-keygen -t rsa -N "" -f ${SSH_KEY_PATH}
fi

# build to ensure docker-compose doesn't use a stale image
docker-compose -f docker-compose.test.yml build

docker-compose -f docker-compose.test.yml up -d \
    dns-proxy target

docker-compose -f docker-compose.test.yml run --rm \
    validate-deployment-playbooks

docker-compose -f docker-compose.test.yml run --rm \
    test ansible-playbook test/remote-test.yml -i test/inventory -vvv

# shut down any lingering service dependencies
docker-compose -f docker-compose.test.yml down -v

# get oldest running containers
TARGET_CONTAINER=$(docker ps --all --quiet --filter 'name=ansible_target' | tail -n 1)
ANSIBLE_CONTAINER=$(docker ps --all --quiet --filter 'name=ansible_docker' | tail -n 1)
PLAYBOOK_VALIDATION_CONTAINER=$(docker ps --all --quiet --filter 'name=validate-deployment-playbooks' | tail -n 1)
DNS_PROXY_CONTAINER=$(docker ps --all --quiet --filter 'name=dns-proxy-server' | tail -n 1)

# pull artifacts into working directory
#docker cp ${BUILD_CONTAINER}:/artifacts ./

echo ""

# exit with non-zero code if any of the test containers exited non-zero
if [[ $(docker inspect -f '{{ .State.ExitCode }}' ${TARGET_CONTAINER}) -ne 0 ]]; then
    echo "FAIL: target container failure(s)"
    exit 1;
elif [[ $(docker inspect -f '{{ .State.ExitCode }}' ${ANSIBLE_CONTAINER}) -ne 0 ]]; then
    echo "FAIL: test failure(s)"
    exit 1;
elif [[ $(docker inspect -f '{{ .State.ExitCode }}' ${PLAYBOOK_VALIDATION_CONTAINER}) -ne 0 ]]; then
    echo "FAIL: Playbook validation failure(s)"
    exit 1;
elif [[ $(docker inspect -f '{{ .State.ExitCode }}' ${DNS_PROXY_CONTAINER}) -ne 0 ]]; then
    echo "FAIL: DNS proxy failure(s)"
    exit 1;
else
    echo "SUCCESS: All tests passed"
fi
