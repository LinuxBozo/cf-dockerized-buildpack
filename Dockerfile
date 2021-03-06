FROM cloudfoundry/cflinuxfs2

ENV BUILDPACKS \
  http://github.com/cloudfoundry/python-buildpack

ENV \
  GO_VERSION=1.7 \
  DIEGO_VERSION=0.1482.0

RUN \
  curl -L "https://storage.googleapis.com/golang/go${GO_VERSION}.linux-amd64.tar.gz" | tar -C /usr/local -xz

RUN \
  mkdir -p /tmp/compile && \
  git -C /tmp/compile clone --single-branch https://github.com/cloudfoundry/diego-release && \
  cd /tmp/compile/diego-release && \
  git checkout "v${DIEGO_VERSION}" && \
  git submodule update --init --recursive \
    src/code.cloudfoundry.org/archiver \
    src/code.cloudfoundry.org/buildpackapplifecycle \
    src/code.cloudfoundry.org/bytefmt \
    src/code.cloudfoundry.org/cacheddownloader \
    src/github.com/cloudfoundry-incubator/candiedyaml \
    src/github.com/cloudfoundry/systemcerts

RUN \
  export PATH=/usr/local/go/bin:$PATH && \
  export GOPATH=/tmp/compile/diego-release && \
  go build -o /tmp/lifecycle/launcher code.cloudfoundry.org/buildpackapplifecycle/launcher && \
  go build -o /tmp/lifecycle/builder code.cloudfoundry.org/buildpackapplifecycle/builder

ENV CF_STACK=cflinuxfs2

USER vcap

ARG PYTHON_VERSION=3.6.0

RUN \
  mkdir -p /tmp/app && \
  echo ${PYTHON_VERSION} > /tmp/app/runtime.txt && \
  touch /tmp/app/requirements.txt && \
  mkdir -p /home/vcap/tmp && \
  cd /home/vcap && \
  /tmp/lifecycle/builder -buildpackOrder "$(echo "$BUILDPACKS" | tr -s ' ' ,)"

COPY staging_info.yml meta-launcher.sh sub-launcher.sh /home/vcap/

ENTRYPOINT ["/home/vcap/meta-launcher.sh"]
