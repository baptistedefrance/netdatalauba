# ---- Stage 1: Uptime Kuma ----------------------------------------------------
FROM louislam/uptime-kuma:latest AS kuma
LABEL maintainer="baptiste@example.com"
LABEL org.opencontainers.image.title="Web Service Monitoring Dashboard - Baptiste"
ENV TZ=Europe/Paris

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD wget -qO- http://127.0.0.1:3001 || exit 1

EXPOSE 3001

RUN echo "Uptime Kuma personnalisé - Projet d’évaluation Docker"


# ---- Stage 2: Netdata --------------------------------------------------------
FROM netdata/netdata:latest AS netdata
LABEL maintainer="baptiste@example.com"
LABEL org.opencontainers.image.title="Laura & Baptiste Dashboard"
ENV TZ=Europe/Paris

RUN mkdir -p /etc/netdata/go.d /etc/netdata/health.d
RUN printf "[global]\n  hostname = MY-NETDATA-EVAL\n" > /etc/netdata/netdata.conf

COPY netdata-conf/go.d/ /etc/netdata/go.d/
COPY netdata-conf/health.d/ /etc/netdata/health.d/

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD wget -qO- http://127.0.0.1:19999/api/v1/info | grep -q '"version"' || exit 1

EXPOSE 19999
VOLUME ["/var/lib/netdata", "/var/cache/netdata"]

RUN echo "Build Netdata (light) — Laura & Baptiste"


# ---- Stage 3: Nginx (avec conf incluse) -------------------------------------
FROM nginx:alpine AS nginx
LABEL maintainer="baptiste@example.com"
LABEL org.opencontainers.image.title="Nginx Reverse Proxy - Laura & Baptiste"

# Ajout du webroot pour Let's Encrypt (challenge HTTP-01)
RUN mkdir -p /var/www/certbot

# Ta conf Nginx (inclut déjà les blocs HTTP/HTTPS et le reverse proxy)
COPY nginx/nginx.conf /etc/nginx/nginx.conf

# Exposer HTTP + HTTPS
EXPOSE 80 443

