FROM ubuntu:20.04 AS shell

###VARIABLES
ARG DEBIAN_FRONTEND=noninteractive
ARG GO=go1.16.6.linux-amd64.tar.gz
ARG USER=terra

###INSTALL ALL NECESSARY PACKAGES
RUN apt update && apt upgrade -y
RUN apt install -y build-essential git wget liblz4-tool nodejs npm jq curl lz4 vim
RUN apt autoremove -y

###CREATE NEW USER $USER
RUN mkdir /home/$USER && useradd -d /home/$USER $USER && usermod -aG sudo $USER &&\ 
    echo $USER ALL=NOPASSWD: ALL >> /etc/sudoers &&\ 
    sed -i 's#terra:/bin/sh#/terra:/bin/bash#' /etc/passwd

###EXPORT THE GO PATHS
RUN echo "USER=$USER" >> /etc/profile
RUN echo 'export GOROOT=/usr/local/go' >> /etc/profile
RUN echo "export GOPATH=/home/$USER/go" >> /etc/profile
RUN echo 'export PATH=$GOPATH/bin:$GOROOT/bin:$PATH' >> /etc/profile
RUN cat /etc/profile >> /home/$USER/.bashrc

###DOWNLOAD AND INSTALL GO AND GO LINTER 
RUN wget https://golang.org/dl/${GO} && tar xf $GO && mv go /usr/local

RUN curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(/usr/local/go/bin/go env GOPATH)/bin v1.41.1

###INCREASE MAXIMUM NUMBER OF OPEN FILES
RUN echo "*                soft    nofile          65535" >> /etc/security/limits.conf
RUN echo "*                hard    nofile          65535" >> /etc/security/limits.conf


FROM shell AS terra

###INSTALL AND BUILD TERRA
ARG MONIKER='Sentry-01'
ARG ADDRESS_BOOK_URL=https://network.terra.dev/addrbook.json
ARG GENESIS=https://columbus-genesis.s3-ap-northeast-1.amazonaws.com/columbus-4-genesis.json

WORKDIR /home/$USER
RUN git clone https://github.com/terra-project/core/
WORKDIR ./core
RUN git checkout v0.4.6
RUN . /etc/profile && LEDGER_ENABLED=false make install

WORKDIR /home/$USER
RUN mkdir /home/$USER/.terrad
RUN chown $USER:$USER -R /home/$USER/.terrad

RUN su $USER -c ". /etc/profile && terrad init \"$MONIKER\""

#update app.tomland config.toml
RUN sed -i 's#seeds = ""#seeds = "87048bf71526fb92d73733ba3ddb79b7a83ca11e@public-seed.terra.dev:26656,b5205baf1d52b6f91afb0da7d7b33dcebc71755f@public-seed2.terra.dev:26656,5d9b8ac70000bd4ab1de3ccaf85eb43f8e315146@seed.terra.delightlabs.io:26656"#' /home/$USER/.terrad/config/config.toml
RUN sed -i 's#persistent_peers = ""#persistent_peers = "cf1097bd5542f83af2aa95119d02c1526a45b55a@terra-sentry01.dokia.cloud:26656,dc02367d1c959d0cf263ee9e4d2090faf4467837@188.40.78.235:15633,5d76903068130a09e754f6230b127bf6a8cd634b@terra.sentries.us-west1.gcp.iqext.net:26656"#' /home/$USER/.terrad/config/config.toml
RUN sed -i 's#max_num_inbound_peers = 40#max_num_inbound_peers = 100#' /home/$USER/.terrad/config/config.toml
RUN sed -i 's#max_num_outbound_peers = 10#max_num_outbound_peers = 100#' /home/$USER/.terrad/config/config.toml
RUN sed -i 's#prometheus = false#prometheus = true#' /home/$USER/.terrad/config/config.toml
RUN sed -i 's#minimum-gas-prices = ""#minimum-gas-prices = "0.01133uluna,0.15uusd,0.104938usdr,169.77ukrw,428.571umnt,0.125ueur,0.98ucny,16.37ujpy,0.11ugbp,10.88uinr,0.19ucad,0.14uchf,0.19uaud,0.2usgd,4.62uthb,1.25usek,1.25udkk,2180.0uidr,7.6uphp"#' /home/$USER/.terrad/config/app.toml
RUN sed -i 's#pex = true#pex = false#' /home/$USER/.terrad/config/config.toml
RUN sed -i 's#max_num_outbound_peers = 100#max_num_outbound_peers = 130#' /home/$USER/.terrad/config/config.toml
RUN sed -i 's#max_num_inbound_peers = 100#max_num_inbound_peers = 130#' /home/$USER/.terrad/config/config.toml
RUN sed -i 's#max_open_connections = 3#max_open_connections = 10#' /home/$USER/.terrad/config/config.toml

RUN curl $GENESIS > /home/$USER/.terrad/config/genesis.json
RUN curl $ADDRESS_BOOK_URL > /home/$USER/.terrad/config/addrbook.json

RUN chown $USER:$USER -R /home/$USER/.terrad

FROM terra

###LOGIN BY DEFAULT AS $USER
USER $USER

###Download and unpack the latest snapshot, then delete it
#If the snapshot is already present on the local machine, uncomment the following 3 lines and comment the next one.

#ARG SNAPSHOT_FILE=columbus-4-default.20210805.0410.tar.lz4

#COPY /path/to/${SNAPSHOT_FILE} /home/$USER/.terrad/
#RUN chown $USER:$USER $SNAPSHOT_FILE
#RUN  lz4 -d $SNAPSHOT_FILE | tar xf - && rm $SNAPSHOT_FILE"

#RUN su $USER -c ". ~/.bashrc && cd ~/.terrad && wget https://get.quicksync.io/${SNAPSHOT_FILE} && lz4 -d $SNAPSHOT_FILE | tar xf - && rm $SNAPSHOT_FILE"

###START TERRAD

CMD . /etc/profile && terrad start
