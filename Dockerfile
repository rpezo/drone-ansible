FROM python:2.7.14-alpine3.7

RUN apk update && \
	apk add ansible libffi-dev openssl-dev gcc musl-dev openssh && \
	mkdir ~/.ssh && mkdir -p ~/.ansible/tmp

RUN pip install packaging azure apache-libcloud pycrypto python-consul

ADD /inc/entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
