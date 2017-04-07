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

groupadd --gid 911 nginx
useradd --gid nginx \
        --uid 995 \
        --no-create-home \
        --home-dir /var/lib/nginx \
        --shell /sbin/nologin \
        --system \
        --comment "Nginx web server" nginx

mkdir -p /var/lib/nginx/tmp/client_body
mkdir -p /var/lib/nginx/tmp/proxy
chown -R nginx.nginx /var/lib/nginx

# logrotate
\cp -f /vagrant/settings/logrotate.nginx /etc/logrotate.d/nginx

# setting nginx.service
\cp -f /vagrant/settings/nginx.service /usr/lib/systemd/system/nginx.service
systemctl daemon-reload

