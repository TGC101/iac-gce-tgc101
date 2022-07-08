FROM rockylinux:8.5.20220308

LABEL maintainer="howhow  -> https://how64bit.com"
USER root
RUN curl https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo -o /etc/yum.repos.d/hashicorp.repo
RUN dnf install -y wget python39-devel terraform git openssh-*
RUN pip3 install ansible && \
  ssh-keygen -A && \
  ssh-keygen -q  -N  "" -f ~/.ssh/id_rsa && \
  mkdir -p /root/lab/iac-gce-tgc101 && \
  dnf clean all && rm -fr /var/cache 
COPY ./iac-gce-tgc101 /root/lab/iac-gce-tgc101
WORKDIR /root/lab/iac-gce-tgc101
RUN chmod +x /root/lab/iac-gce-tgc101/*.sh

CMD ["tail","-f","/dev/null"]