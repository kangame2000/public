FROM ubuntu:22.04

RUN apt update 
RUN apt install -y vim git wget curl net-tools vim make gcc libpcre3-dev libssl-dev zlib1g-dev zlib1g build-essential bzip2 unzip libgeoip-dev  libxslt-dev libgd-dev lsb-release

RUN mkdir -p /tmp/build && cd /tmp/build && useradd -s /sbin/nologin -M nginx && \
    wget https://github.com/vision5/ngx_devel_kit/archive/refs/tags/v0.3.2.tar.gz && tar xvf v0.3.2.tar.gz && \
    wget https://github.com/openresty/set-misc-nginx-module/archive/refs/tags/v0.33.tar.gz && tar xvf v0.33.tar.gz && \
    wget https://github.com/vozlt/nginx-module-vts/archive/refs/tags/v0.2.1.tar.gz && tar xvf v0.2.1.tar.gz && \
    wget https://github.com/openresty/lua-nginx-module/archive/refs/tags/v0.10.21.tar.gz && tar xvf v0.10.21.tar.gz && \
    wget https://github.com/openresty/headers-more-nginx-module/archive/refs/tags/v0.34.tar.gz && tar xvf v0.34.tar.gz && \
    wget https://github.com/Refinitiv/nginx-sticky-module-ng/archive/refs/tags/1.2.6.tar.gz && tar xvf 1.2.6.tar.gz && \
    wget https://github.com/openresty/lua-upstream-nginx-module/archive/refs/tags/v0.07.tar.gz && tar xvf v0.07.tar.gz

RUN apt -y install --no-install-recommends gnupg ca-certificates && \
    wget -O - https://openresty.org/package/pubkey.gpg |  gpg --dearmor -o /usr/share/keyrings/openresty.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/openresty.gpg] http://openresty.org/package/ubuntu $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/openresty.list > /dev/null && \
    apt update && apt -y install openresty && \
    cd /usr/local/openresty/lualib/ && \
    wget https://raw.githubusercontent.com/bungle/lua-resty-template/master/lib/resty/template.lua


ENV LUAJIT_LIB=/usr/local/openresty/luajit/lib
ENV LUAJIT_INC=/usr/local/openresty/luajit/include/luajit-2.1

RUN cd /tmp/build && \
    wget https://nginx.org/download/nginx-1.21.4.tar.gz && tar xvf nginx-1.21.4.tar.gz

RUN cd /tmp/build/nginx-1.21.4 && \
    ./configure \
    --prefix=/usr/share/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --http-log-path=/var/log/nginx/access.log \
    --error-log-path=/var/log/nginx/error.log \
    --lock-path=/var/lock/nginx.lock \
    --pid-path=/run/nginx.pid \
    --http-client-body-temp-path=/var/lib/nginx/body \
    --http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
    --http-proxy-temp-path=/var/lib/nginx/proxy \
    --http-scgi-temp-path=/var/lib/nginx/scgi \
    --http-uwsgi-temp-path=/var/lib/nginx/uwsgi \
    --with-debug \
    --with-pcre-jit \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-http_realip_module \
    --with-http_auth_request_module \
    --with-http_addition_module \
    --with-http_dav_module \
    --with-http_geoip_module \
    --with-http_gzip_static_module \
    --with-http_sub_module \
    --with-http_v2_module \
    --with-stream \
    --with-stream_ssl_module \
    --with-stream_ssl_preread_module \
    --with-threads \
    --with-file-aio \
    --without-mail_pop3_module \
    --without-mail_smtp_module \
    --without-mail_imap_module \
    --without-http_uwsgi_module \
    --without-http_scgi_module \
    --with-ld-opt=-Wl,-rpath,/usr/local/openresty/luajit/lib \
    --with-cc-opt='-O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector --param=ssp-buffer-size=4 -m64 -mtune=generic' \
    --add-module=/tmp/build/ngx_devel_kit-0.3.2 \
    --add-module=/tmp/build/set-misc-nginx-module-0.33 \
    --add-module=/tmp/build/nginx-module-vts-0.2.1 \
    --add-module=/tmp/build/headers-more-nginx-module-0.34 \
    --add-module=/tmp/build/lua-nginx-module-0.10.21 \
    --add-module=/tmp/build/lua-upstream-nginx-module-0.07 && \ 
    make -j4 && make install 

RUN rm -rf /tmp/* && apt clean && mkdir -p /var/lib/nginx/body
COPY nginx.conf   /etc/nginx/
COPY run.sh /usr/local/bin/run.sh
RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80
EXPOSE 443
EXPOSE 8088

CMD ["/bin/bash" , "/usr/local/bin/run.sh"]
