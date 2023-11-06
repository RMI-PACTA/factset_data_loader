FROM ubuntu:jammy-20230916

# install system dependencies for R packages
RUN echo "deb http://archive.ubuntu.com/ubuntu/ focal-updates main" >> \
      /etc/apt/sources.list \
      && apt-get update && apt-get install --no-install-recommends -y \
      libexpat1=2.4.* \
      libldap-2.4-2=2.4.* \
      libnss3=2:3.68.* \
      netcat=1.* \
      odbc-postgresql=1:13.* \
      postgresql-client=14+* \
      unixodbc=2.3.* \
      unzip=6.* \
      && rm -rf /var/lib/apt/lists/*

# set up odbc and DSN
COPY system/etc/odbcinst.ini /etc/odbcinst.ini

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN echo export LD_LIBRARY_PATH="$(dpkg-query -L odbc-postgresql | grep psqlodbcw.so | xargs dirname)":"$LD_LIBRARY_PATH" >> ~/.bashrc

COPY system/etc/ /usr/local/etc/
COPY system/bin/ /usr/local/bin/

RUN groupadd -r fdsrunner \
      && useradd -r -g fdsrunner fdsrunner \
      && mkdir -p /home/fdsrunner \
      && chown -R fdsrunner /home/fdsrunner

USER fdsrunner
WORKDIR /home/fdsrunner

CMD ["run_data_loader.sh"]
