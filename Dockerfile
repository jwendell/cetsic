FROM centos:latest
MAINTAINER Jonh Wendell <jonh.wendell@redhat.com>

USER root

RUN yum install -y centos-release-scl centos-release-openshift-origin
RUN yum install -y rh-maven33 git origin-clients java-1.8.0-openjdk-devel && yum clean all

RUN groupadd -r test -g 175 && \
    useradd -u 175 -r -g test -m -d /home/test -s /bin/bash -c "Test user" test && \
    echo "test:test" | chpasswd

ADD files/ /home/test/
RUN chown -R test:test /home/test

USER test
ENV HOME /home/test
WORKDIR /home/test

RUN git config --global http.sslVerify false

CMD ["/home/test/run-tests.sh"]

