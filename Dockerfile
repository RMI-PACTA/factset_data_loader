# FROM debian:12.1-slim
FROM ubuntu:jammy-20230916
# FROM ubuntu:focal-20230801

# RUN yes | unminimize

# install system dependencies for R packages
RUN echo "deb http://archive.ubuntu.com/ubuntu/ focal-updates main" >> \
      /etc/apt/sources.list \
      && apt-get update && apt-get install --no-install-recommends -y \
      libldap-2.4-2=2.4.* \
      libnss3=2:3.68.* \
      odbc-postgresql=1:13.* \
      postgresql-client=14+* \
      unixodbc=2.3.* \
      && rm -rf /var/lib/apt/lists/*

# set up odbc and DSN
COPY system/odbcinst.ini /etc/odbcinst.ini
COPY system/DSN-template.ini /root/DSN-template.ini
RUN odbcinst -i -s -f /root/DSN-template.ini

RUN echo export LD_LIBRARY_PATH="$(dpkg-query -L odbc-postgresql | grep psqlodbcw.so | xargs dirname)":"$LD_LIBRARY_PATH" >> ~/.bashrc

COPY system/run_data_loader.sh /usr/local/bin/run_data_loader
