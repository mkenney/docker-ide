FROM debian:latest

MAINTAINER Michael Kenney <mkenney@webbedlam.com>

ENV HOSTNAME 'devenv' # should get overridden
ENV DEBIAN_FRONTEND noninteractive
USER root
RUN apt-get update
RUN apt-get install -y apt-utils

##############################################################################
# Configuration
##############################################################################

ENV PHP_TIMEZONE 'America/Denver'

##############################################################################
# System logger
##############################################################################

RUN apt-get install -y rsyslog && \
	rm -rf /var/run/rsyslogd.pid

##############################################################################
# UTF-8 Locale
##############################################################################

RUN apt-get install -y locales && \

	locale-gen en_US.UTF-8 en_us && \
	dpkg-reconfigure locales && \
	dpkg-reconfigure locales && \
	locale-gen C.UTF-8 && \
	/usr/sbin/update-locale LANG=C.UTF-8

ENV LANG C.UTF-8
ENV LANGUAGE C.UTF-8
ENV LC_ALL C.UTF-8

##############################################################################
# PHP
##############################################################################

RUN apt-get install -y \
	libfreetype6-dev \
	libjpeg62-turbo-dev \
	libmcrypt-dev \
	libpng12-dev \
	libbz2-dev \
	php5-cli \
	php5-gd \
	php5-mcrypt \
	php-pear

# PHP configuration
ENV PHP_INI_DIR '/etc/php5/cli/conf.d'
RUN echo "memory_limit = -1"               > $PHP_INI_DIR/memory_limit.ini && \
	echo "date.timezone = ${PHP_TIMEZONE}" > $PHP_INI_DIR/date_timezone.ini && \
	echo "error_reporting = E_ALL"         > $PHP_INI_DIR/error_reporting.ini && \
	echo "display_errors = On"             > $PHP_INI_DIR/display_errors.ini && \
	echo "log_errors = On"                 > $PHP_INI_DIR/log_errors.ini && \
	echo "report_memleaks = On"            > $PHP_INI_DIR/report_memleaks.ini && \
	echo "error_log = syslog"              > $PHP_INI_DIR/error_log.ini

##############################################################################
# Composer
##############################################################################

ENV COMPOSER_HOME /root/composer
ENV COMPOSER_VERSION master
RUN apt-get install -y curl && \
	curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

##############################################################################
# phpDocumentor
##############################################################################

RUN apt-get install -y graphviz && \
	pear channel-discover pear.phpdoc.org && \
	pear install phpdoc/phpDocumentor

##############################################################################
# Apps
##############################################################################

RUN apt-get install -y \
	git \
	htop \
	less \
	rsync \
	sudo \
	tcpdump \
	telnet \
	tmux \
	unzip \
	wget

##############################################################################
# Vim
##############################################################################

RUN apt-get install -y \
	exuberant-ctags \
	vim

RUN pear install --alldeps php_codesniffer && \
	pear channel-discover pear.phpmd.org && \
	pear channel-discover pear.pdepend.org && \
    pear install phpmd/PHP_PMD && \
	export PATH=/root/.composer/vendor/bin:$PATH

##############################################################################
# Users
##############################################################################

# Add a user
RUN groupadd dev && \
	useradd dev -s /bin/bash -m -g dev -G root && \
	echo "dev:password" | chpasswd && \
	echo "dev ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers && \
	cd ~dev/ && \
	git clone https://github.com/mkenney/terminal_config.git && \
	rsync -av terminal_config/ ./ && \
	chown -R dev:dev . && \
	rsync -av terminal_config/ ~/ && \
	cd ~/ && \
	git submodule update --init --recursive && \
	vim +PluginInstall +qall > /dev/null

USER dev
RUN cd ~/ && \
	git submodule update --init --recursive && \
	vim +PluginInstall +qall > /dev/null
USER root


##############################################################################
# ~ fin ~
##############################################################################

RUN apt-get clean && \
	rm -rf /var/lib/apt/lists/*

COPY container/init.sh /
COPY container/attach.sh /
USER dev
VOLUME ["/app"]
CMD ["/bin/bash"]
