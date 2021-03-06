#!/bin/bash

# install dependency package
yum install -y gcc-c++ pcre-devel zlib-devel make unzip openssl-devel perl-devel perl-ExtUtils-Embed gd-devel

# install nps
NPS_VERSION=1.11.33.4
cd
wget https://github.com/pagespeed/ngx_pagespeed/archive/v${NPS_VERSION}-beta.zip
unzip v${NPS_VERSION}-beta.zip
cd ngx_pagespeed-${NPS_VERSION}-beta/
psol_url=https://dl.google.com/dl/page-speed/psol/${NPS_VERSION}.tar.gz
[ -e scripts/format_binary_url.sh ] && psol_url=$(scripts/format_binary_url.sh PSOL_BINARY_URL)
wget ${psol_url}
tar -xzvf $(basename ${psol_url})

# install nginx
NGINX_VERSION=1.11.7
cd
wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
tar -xvzf nginx-${NGINX_VERSION}.tar.gz
cd nginx-${NGINX_VERSION}/
./configure --add-module=$HOME/ngx_pagespeed-${NPS_VERSION}-beta \
            --prefix=/etc/nginx \
            --sbin-path=/usr/sbin/nginx \
            --conf-path=/etc/nginx/nginx.conf \
            --http-client-body-temp-path=/var/lib/nginx/tmp/client_body \
            --http-proxy-temp-path=/var/lib/nginx/tmp/proxy \
            --http-fastcgi-temp-path=/var/lib/nginx/tmp/fastcgi \
            --pid-path=/var/run/nginx.pid \
            --lock-path=/var/run/nginx.lock \
            --error-log-path=/var/log/nginx/error.log \
            --http-log-path=/var/log/nginx/access.log \
            --with-http_gzip_static_module \
            --with-http_stub_status_module \
            --with-http_ssl_module \
            --with-pcre \
            --with-file-aio \
            --with-http_realip_module \
            --with-http_perl_module \
            --with-http_image_filter_module \
            --without-http_scgi_module \
            --without-http_uwsgi_module
make
make install

# create nginx user
groupadd --gid 911 nginx
useradd --gid nginx \
        --uid 995 \
        --no-create-home \
        --home-dir /var/lib/nginx \
        --shell /sbin/nologin \
        --system \
        --comment "Nginx web server" nginx

# create directory
mkdir -p /var/lib/nginx/tmp/client_body
mkdir -p /var/lib/nginx/tmp/proxy
chown -R nginx.nginx /var/lib/nginx

# set logrotate
\cp -f /vagrant/settings/logrotate.nginx /etc/logrotate.d/nginx

# set nginx.service
\cp -f /vagrant/settings/nginx.service /usr/lib/systemd/system/nginx.service
systemctl daemon-reload

# set nginx.conf
\cp -f /vagrant/settings/nginx.conf /etc/nginx/nginx.conf

# install docker
yum install -y yum-utils
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum-config-manager --enable docker-ce-edge
yum-config-manager --disable docker-ce-edge
yum makecache fast
yum install -y docker-ce
systemctl start docker
#docker run --rm hello-world

# install docker-compose
curl -L "https://github.com/docker/compose/releases/download/1.11.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# run memcached
\cp -r /vagrant/settings/docker-compose.yml ~/
cd
docker-compose up -d

# install memcached-cli
curl "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py"
python get-pip.py
pip install memcache-cli
# get_stats items
# get_stats cachedump 1 100

# run nginx
systemctl start nginx
