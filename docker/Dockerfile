FROM ubuntu:latest

###VARIABLES
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Paris
ARG GO=go1.16.6.linux-amd64.tar.gz
ARG MONIKER='Moniker name'
ARG GENESIS=https://columbus-genesis.s3-ap-northeast-1.amazonaws.com/columbus-4-genesis.json
ARG USER=terra
ARG SNAPSHOT_FILE=columbus-4-default.20210805.0410.tar.lz4
ARG ADDRESS_BOOK_URL=https://network.terra.dev/addrbook.json

###INSTALL ALL NECESSARY PACKAGES
RUN apt update && apt upgrade -y &&\
    apt install -y build-essential git wget liblz4-tool nodejs npm jq curl lz4 vim &&\
    apt autoremove -y

###CREATE NEW USER $USER
RUN mkdir -p /home/$USER/.ssh && touch /home/$USER/.ssh/authorized_keys &&\
    useradd -d /home/$USER $USER && usermod -aG sudo $USER && chown -R $USER:$USER /home/$USER/ &&\
    chmod 700 /home/$USER/.ssh && chmod 644 /home/$USER/.ssh/authorized_keys &&\
    echo $USER ALL=NOPASSWD: ALL >> /etc/sudoers &&\
    sed -i 's#terra:/bin/sh#/terra:/bin/bash#' /etc/passwd

###EXPORT THE GO PATHS
RUN echo export GOROOT=/usr/local/go >> /etc/profile &&\
    echo export GOPATH=/home/$USER/go >> /etc/profile && . /etc/profile &&\
    echo export PATH=$GOPATH/bin:$GOROOT/bin:$PATH >> /etc/profile &&\ 
    echo '. /etc/profile' >> ~/.bashrc && su $USER -c 'echo ". /etc/profile" >> ~/.bashrc'   #/etc/profile is not sourced on session open, so.

###DOWNLOAD AND INSTALL GO AND GO LINTER 
RUN wget https://golang.org/dl/${GO} &&\
    tar xf $GO && mv go /usr/local

RUN curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(/usr/local/go/bin/go env GOPATH)/bin v1.41.1

###INCREASE MAXIMUM NUMBER OF OPEN FILES
RUN echo "*                soft    nofile          65535" >> /etc/security/limits.conf
RUN echo "*                hard    nofile          65535" >> /etc/security/limits.conf

###INSTALL AND CONFIGURE TERRA
RUN su $USER -c 'cd && . ~/.bashrc && git clone https://github.com/terra-project/core/ &&\
    cd core && git checkout master &&  make install'

RUN su $USER -c ". ~/.bashrc && cd /home/$USER/core && terrad init '$MONIKER'"

RUN su $USER -c 'curl $GENESIS > /home/$USER/.terrad/config/genesis.json'

RUN su $USER -c "curl $ADDRESS_BOOK_URL > ~/.terrad/config/addrbook.json"

#update app.tomland config.toml
RUN sed -i 's#seeds = ""#seeds = "87048bf71526fb92d73733ba3ddb79b7a83ca11e@public-seed.terra.dev:26656,b5205baf1d52b6f91afb0da7d7b33dcebc71755f@public-seed2.terra.dev:26656,5d9b8ac70000bd4ab1de3ccaf85eb43f8e315146@seed.terra.delightlabs.io:26656"#' /home/$USER/.terrad/config/config.toml
RUN sed -i 's#persistent_peers = ""#persistent_peers = "cf1097bd5542f83af2aa95119d02c1526a45b55a@terra-sentry01.dokia.cloud:26656,\
dc02367d1c959d0cf263ee9e4d2090faf4467837@188.40.78.235:15633,5d76903068130a09e754f6230b127bf6a8cd634b@terra.sentries.us-west1.gcp.iqext.net:26656"#' /home/$USER/.terrad/config/config.toml
RUN sed -i 's#max_num_inbound_peers = 40#max_num_inbound_peers = 100#' /home/$USER/.terrad/config/config.toml"
RUN sed -i 's#max_num_outbound_peers = 10#max_num_outbound_peers = 100#' /home/$USER/.terrad/config/config.toml"
RUN sed -i 's#prometheus = false#prometheus = true#' /home/$USER/.terrad/config/config.toml"
RUN sed -i 's#minimum-gas-prices = ""#minimum-gas-prices = "0.01133uluna,0.15uusd,0.104938usdr,169.77ukrw,428.571umnt,0.125ueur,0.98ucny,16.37ujpy,0.11ugbp,10.88uinr,\
0.19ucad,0.14uchf,0.19uaud,0.2usgd,4.62uthb,1.25usek,1.25udkk,2180.0uidr,7.6uphp"#' /home/$USER/.terrad/config/app.toml

###Download and unpack the latest snapshot, then delete it
#If the snapshot is already present on the local machine, uncomment the following 3 lines and comment the next one.

#COPY /path/to/${SNAPSHOT_FILE} /home/$USER/.terrad/
#RUN chown $USER:$USER $SNAPSHOT_FILE
#RUN  lz4 -d $SNAPSHOT_FILE | tar xf - && rm $SNAPSHOT_FILE"

#RUN su $USER -c ". ~/.bashrc && cd ~/.terrad && wget https://get.quicksync.io/${SNAPSHOT_FILE} && lz4 -d $SNAPSHOT_FILE | tar xf - && rm $SNAPSHOT_FILE"

###START TERRAD

#RUN su $USER -c "cd && terrad start"
