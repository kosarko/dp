#!/bin/bash
set -e

export SHELL=/bin/bash
MAKE="make"
#MAKE="make -j6"

apt-get -y update && apt-get -y upgrade
apt-get -y install git build-essential zlib1g-dev automake libtool autoconf subversion libatlas3gf-base unzip sox python3 gawk openjdk-7-jre-headless

locale-gen cs_CZ
locale-gen cs_CZ.UTF-8
update-locale

mkdir srilm
pushd srilm
tar -xvzf ~vagrant/projects/srilm.tar.gz

export SRILM=/home/vagrant/srilm/

$MAKE World
$MAKE cleanest

popd

git clone https://github.com/kaldi-asr/kaldi/ && pushd kaldi && git reset --hard 95668a

pushd tools
$MAKE
popd

pushd src
./configure --shared
$MAKE depend
$MAKE

########
#### to save space
#######
mkdir /tmp/kaldi_bin
find ./ -executable -type f -exec cp -f {} /tmp/kaldi_bin/ \;
rsync -avzL lib/ /tmp/kaldi_lib
$MAKE clean
rm -rf lib
mv /tmp/kaldi_lib lib
mv /tmp/kaldi_bin .

popd #src

pushd tools
mkdir /tmp/openfst
cp -R openfst/{bin,lib} /tmp/openfst
$MAKE distclean
mv /tmp/openfst .
ln -s openfst openfst-1.3.4

popd #tools
popd #kaldi
#####end saving space

cp -R projects/system/ /home/vagrant/system
pushd /home/vagrant/system
sed -e"s#^SRILM.*#SRILM=${SRILM}bin/i686-m64#" -e"s#export KALDI_DIR.*#export KALDI_DIR=/home/vagrant/kaldi#" -i local_paths
make install

popd

mkdir /tmp/output

cp -R /home/vagrant/projects/poc .
pushd system
./run_single.sh /home/vagrant/poc/2014-03-10-200004-CT_24-HYDEPARK.{wav,srt} /tmp/output
popd

for i in kaldi system srilm poc /tmp/output; do
	chown -R vagrant:vagrant $i
done
