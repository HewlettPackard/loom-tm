FROM ubuntu

# Set proxy
#RUN bash -c 'echo "Acquire::http::proxy \"http://proxy:8088/\";" > /etc/apt/apt.conf'
#RUN bash -c 'echo "Acquire::https::proxy \"http://proxy:8088/\";" >> /etc/apt/apt.conf'

RUN apt update -y \
&& apt dist-upgrade -y \
&& apt -y install \
	openjdk-8-jre-headless \
	dos2unix \
&& rm -rf /var/lib/apt/lists/*

COPY target /loom/target
COPY adapters /loom/adapters
COPY src/main/docker/myadapter.properties /loom/adapters
COPY src/main/docker/log4j.properties /loom/
COPY jetty.xml /loom/
COPY deployment.properties /loom/
COPY run.sh /loom/
RUN dos2unix /loom/run.sh
RUN chmod a+x /loom/run.sh

EXPOSE 9099

WORKDIR /loom

ENTRYPOINT ["./run.sh"]
