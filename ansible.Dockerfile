FROM alpine:3.7

ENV ANSIBLE_VERSION 2.4.3.0

ENV BUILD_PACKAGES \
  bash \
  curl \
  tar \
  openssh-client \
  sshpass \
  git \
  python \
  py-boto \
  py-dateutil \
  py-httplib2 \
  py-jinja2 \
  py-paramiko \
  py-pip \
  py-setuptools \
  py-yaml \
  ca-certificates

RUN apk --update add --virtual build-dependencies \
  gcc \
  musl-dev \
  libffi-dev \
  openssl-dev \
  python-dev

ADD requirements.txt .

RUN set -x && \
  apk update && apk upgrade && \
  apk add --no-cache ${BUILD_PACKAGES} && \
  pip install --upgrade pip && \
  pip install -r requirements.txt && \
  pip install python-keyczar docker-py && \
  apk del build-dependencies && \
  rm -rf /var/cache/apk/*

RUN mkdir /etc/ansible/ /ansible
RUN echo "[local]" >> /etc/ansible/hosts && \
    echo "localhost" >> /etc/ansible/hosts

RUN curl -fsSL https://releases.ansible.com/ansible/ansible-${ANSIBLE_VERSION}.tar.gz -o ansible.tar.gz && \
  tar -xzf ansible.tar.gz -C /ansible --strip-components 1 && \
  rm -fr ansible.tar.gz /ansible/docs /ansible/examples /ansible/packaging

RUN mkdir -p /ansible/playbooks
WORKDIR /ansible/playbooks

ENV ANSIBLE_GATHERING smart
ENV ANSIBLE_HOST_KEY_CHECKING false
ENV ANSIBLE_RETRY_FILES_ENABLED false
ENV ANSIBLE_ROLES_PATH /ansible/playbooks/roles
ENV ANSIBLE_SSH_PIPELINING True
ENV PATH /ansible/bin:$PATH
ENV PYTHONPATH /ansible/lib

# if using ansible-galaxy
#ADD roles/requirements.yml .
#RUN ansible-galaxy install \
#    --role-file requirements.yml \
#    --roles-path ./roles

COPY . $WORKDIR

CMD ["ansible-playbook"]
