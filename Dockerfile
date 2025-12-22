FROM alpine/terragrunt

ENV VIRTUAL_ENV=/opt/venv

RUN apk update \
    && apk add --no-cache \
        gcc \
        make \
        musl-dev \
        python3 \
        python3-dev \
        py3-pip \
        curl \
        sed \
        jq \
        graphviz \
    && rm -rf /var/cache/apk/*

RUN python3 -m venv ${VIRTUAL_ENV}

ENV PATH="$VIRTUAL_ENV/bin:$PATH"

RUN pip3 install --upgrade pip \
    && pip3 install --no-cache-dir \
        awscli \
        jc

RUN adduser -D -u 100000 -g jenkins jenkins \
    && mkdir /home/jenkins/.ssh \
    && ssh-keyscan -H github.com >> /home/jenkins/.ssh/known_hosts \
    && chown -R jenkins:jenkins /home/jenkins/.ssh/ \
    && echo -e "[safe]\n        directory = *" > /home/jenkins/.gitconfig

USER jenkins

CMD ["aws", "--version", ";", "terraform", "--version", ";", "terragrunt", "--version"]