FROM rabbitmq:3.8-management

WORKDIR /

COPY .docker/development/rabbitmq/rabbitmq.conf /etc/rabbitmq/
COPY .docker/development/rabbitmq/hbx_rabbit_definitions.json /etc/rabbitmq/
COPY .docker/development/rabbitmq/advanced.config /tmp/

ARG HBX_ID
ARG ENV_NAME

CMD cp /tmp/rabbitmq.conf /etc/rabbitmq/ \
  && sed -r "s/HBX_ID/$HBX_ID/g" /tmp/hbx_rabbit_definitions.json >/etc/rabbitmq/hbx_rabbit_definitions.json \
  && sed -i -r "s/ENV_NAME/$ENV_NAME/g" /etc/rabbitmq/hbx_rabbit_definitions.json \
  && sed -r "s|RABBITMQ_URL|$RABBITMQ_URL|g" /tmp/advanced.config >/etc/rabbitmq/advanced.config \
  && sed -i -r "s/HBX_ID/$HBX_ID/g" /etc/rabbitmq/advanced.config \
  && sed -i -r "s/ENV_NAME/$ENV_NAME/g" /etc/rabbitmq/advanced.config \
  && chown rabbitmq:rabbitmq /etc/rabbitmq/rabbitmq.conf /etc/rabbitmq/hbx_rabbit_definitions.json /etc/rabbitmq/advanced.config \
  && rabbitmq-plugins enable rabbitmq_management && \
  && rabbitmq-server
