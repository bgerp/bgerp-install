FROM ubuntu:20.04
#
LABEL MAINTAINER="Milan Enev <milan@mreji.net>"
#
ADD ./files /tmp/
ADD bgerp /var/www/bgerp
USER root
RUN /bin/bash /tmp/install_packages.sh && \
    /bin/bash /tmp/configure_packages.sh && \
    /bin/bash /tmp/cleanup.sh
#
USER www-data
#
STOPSIGNAL SIGQUIT
CMD ["/tmp/start.sh"]
WORKDIR /var/www/html
#
EXPOSE 8080
