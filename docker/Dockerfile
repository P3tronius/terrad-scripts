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
    apt install -y build-essential git wget liblz4-tool nodejs npm jq curl lz4 vim ssh &\
    apt autoremove -y

###CREATE NEW USER $USER
RUN mkdir -p /home/$USER/.ssh && useradd -d /home/$USER $USER && usermod -aG sudo $USER &&\ 
    echo $USER ALL=NOPASSWD: ALL >> /etc/sudoers &&\ 
    sed -i 's#terra:/bin/sh#/terra:/bin/bash#' /etc/passwd

#enable no password login from current user (as terra user has no password anyway). Local path to update in the variable above.
COPY $SSH_PUBLIC_KEY /home/$USER/.ssh/authorized_keys
RUN chown -R $USER:$USER /home/$USER/ && chmod 700 /home/$USER/.ssh && chmod 644 /home/$USER/.ssh/authorized_keys

###CONFIGURE AND RUN THE SSH SERVER
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
RUN /etc/init.d/ssh start

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

RUN su $USER -c "curl $GENESIS > /home/$USER/.terrad/config/genesis.json"

RUN su $USER -c "curl $ADDRESS_BOOK_URL > ~/.terrad/config/addrbook.json"

#update app.tomland config.toml
RUN sed -i 's#seeds = ""#seeds = "87048bf71526fb92d73733ba3ddb79b7a83ca11e@public-seed.terra.dev:26656,b5205baf1d52b6f91afb0da7d7b33dcebc71755f@public-seed2.terra.dev:26656,5d9b8ac70000bd4ab1de3ccaf85eb43f8e315146@seed.terra.delightlabs.io:26656"#' /home/$USER/.terrad/config/config.toml
RUN sed -i 's#persistent_peers = ""#persistent_peers = "cf1097bd5542f83af2aa95119d02c1526a45b55a@terra-sentry01.dokia.cloud:26656,\
dc02367d1c959d0cf263ee9e4d2090faf4467837@188.40.78.235:15633,5d76903068130a09e754f6230b127bf6a8cd634b@terra.sentries.us-west1.gcp.iqext.net:26656"#' /home/$USER/.terrad/config/config.toml
RUN sed -i 's#max_num_inbound_peers = 40#max_num_inbound_peers = 100#' /home/$USER/.terrad/config/config.toml
RUN sed -i 's#max_num_outbound_peers = 10#max_num_outbound_peers = 100#' /home/$USER/.terrad/config/config.toml
RUN sed -i 's#prometheus = false#prometheus = true#' /home/$USER/.terrad/config/config.toml
RUN sed -i 's#minimum-gas-prices = ""#minimum-gas-prices = "0.01133uluna,0.15uusd,0.104938usdr,169.77ukrw,428.571umnt,0.125ueur,0.98ucny,16.37ujpy,0.11ugbp,10.88uinr,\
0.19ucad,0.14uchf,0.19uaud,0.2usgd,4.62uthb,1.25usek,1.25udkk,2180.0uidr,7.6uphp"#' /home/$USER/.terrad/config/app.toml

###Install terrad as systemctl service
RUN echo $'[Unit] \n\
Description=Terra node \n\
After=network.target \n\
StartLimitIntervalSec=0 \n\
\n\
[Service] \n\
Type=simple \n\
Restart=always \n\
RestartSec=10 \n\
User=$USER \n\
ExecStart=$GOPATH/bin/terrad start \n\
LimitNOFILE=65535 \n\
Nice=-20 \n\
IOSchedulingPriority=0 \n\
IOSchedulingClass=realtime \n\
\n\
[Install] \n\
WantedBy=multi-user.target \n\
' >> /etc/systemd/system/terrad.service

###Install Prometheus
# create user and data folders
RUN groupadd --system prometheus
RUN useradd -s /sbin/nologin --system -g prometheus prometheus
WORKDIR /var/lib/prometheus
WORKDIR /etc/prometheus
WORKDIR /tmp
RUN curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest | grep browser_download_url | grep linux-amd64 | cut -d '"' -f 4 | wget -qi -
RUN tar xvf prometheus*.tar.gz
RUN mv /tmp/prometheus*/prometheus /tmp/prometheus*/promtool /usr/local/bin/
RUN mv /tmp/prometheus*/consoles/ /tmp/prometheus*/console_libraries/ /etc/prometheus/
RUN echo $'# my global config\n\
global: \n\
  scrape_interval:     15s # Set the scrape interval to every 15 seconds. Default is every 1 minute. \n\
  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute. \n\
  # scrape_timeout is set to the global default (10s). \n\
 \n\
# Alertmanager configuration \n\
alerting: \n\
  alertmanagers: \n\
  - static_configs: \n\
    - targets: \n\
      # - alertmanager:9093 \n\
 \n\
# Load rules once and periodically evaluate them according to the global evaluation_interval. \n\
rule_files: \n\
  # - "first_rules.yml" \n\
  # - "second_rules.yml" \n\
 \n\
# A scrape configuration containing exactly one endpoint to scrape: \n\
# Here its Prometheus itself. \n\
scrape_configs: \n\
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config. \n\
  - job_name: "node_explorer" \n\
    static_configs: \n\
    - targets: ["localhost:9100"] \n\
  - job_name: "terrad" \n\
    static_configs: \n\
    - targets: ["localhost:26660"] \n\
  - job_name: "prometheus" \n\
    static_configs: \n\
    - targets: ["localhost:9190"] \n\
 \n\
' >> /etc/prometheus/prometheus.yml

# TODO: install node_exporter too

# create service
RUN echo $'[Unit] \n\
Description=Prometheus \n\
Wants=network-online.target \n\
After=network-online.target \n\
\n\
[Service] \n\
User=prometheus \n\
Group=prometheus \n\
Type=simple \n\
ExecStart=/usr/local/bin/prometheus --config.file /etc/prometheus/prometheus.yml --storage.tsdb.path /var/lib/prometheus/ --web.console.templates=/etc/prometheus/consoles --web.console.libraries=/etc/prometheus/console_libraries --web.listen-address=:10090 \n\
\n\
[Install] \n\
WantedBy=multi-user.target \n\
' >> /etc/systemd/system/prometheus.service

###Install oracle-feeder services


###Start services
RUN systemctl daemon-reload
RUN systemctl enable terrad.service
RUN systemctl start terrad.service

###LOGIN BY DEFAULT AS $USER
USER $USER

###Download and unpack the latest snapshot, then delete it
#If the snapshot is already present on the local machine, uncomment the following 3 lines and comment the next one.

#COPY /path/to/${SNAPSHOT_FILE} /home/$USER/.terrad/
#RUN chown $USER:$USER $SNAPSHOT_FILE
#RUN  lz4 -d $SNAPSHOT_FILE | tar xf - && rm $SNAPSHOT_FILE"

#RUN su $USER -c ". ~/.bashrc && cd ~/.terrad && wget https://get.quicksync.io/${SNAPSHOT_FILE} && lz4 -d $SNAPSHOT_FILE | tar xf - && rm $SNAPSHOT_FILE"

###START TERRAD

#RUN su $USER -c "cd && terrad start"
