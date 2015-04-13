#!/bin/bash
set -e -x

# semaphore does not creates a virtualenv for us
sudo apt-get install -y python-virtualenv python-dev libxml2-utils
virtualenv ~/.venv
source ~/.venv/bin/activate

# fix users and groups
sudo groupadd -f -g 10 wheel
sudo groupadd -f -g 250 portage
sudo useradd -m -d /var/tmp/portage -g 250 -u 250 -s /bin/false portage

# install snakeoil as pkgcore dep
# snakeoil: we need explicit --install-headers because of pip bug
#   -> https://github.com/pypa/pip/pull/2421
pip install "https://github.com/pkgcore/snakeoil/archive/master.tar.gz" \
	--install-option="--install-headers=${VIRTUAL_ENV}/include/snakeoil"

# fetch pkgcore & pkgcheck
# their setup.py files are incompatible with pip
wget -O - "https://github.com/pkgcore/pkgcore/archive/master.tar.gz" | tar -xz
wget -O - "https://github.com/pkgcore/pkgcheck/archive/master.tar.gz" | tar -xz

# install pkgcore
cd pkgcore-master
git init
python setup.py build_ext -I "${VIRTUAL_ENV}"/include
python setup.py install --disable-man-pages --disable-html-docs
cd -

# install pkgcheck
cd pkgcheck-master
git init
python setup.py install
cd -

# configure pkgcore
sed -e "s^@path@^${PWD}^" "${0%/*}"/pkgcore.conf.in > ~/.pkgcore.conf
