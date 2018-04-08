#!/bin/bash -e

function prepare_env() {
  # add to $PATH
  mkdir -p bin
  PATH=$PATH:$TRAVIS_BUILD_DIR/bin

  # cidrmerge
  pushd tools/cidrmerge
  make
  mv cidrmerge ../../bin/
  popd
}

function build_chnroute() {
  # ipv4 chnroute
  mkdir -p build/chnroute
  pushd build/chnroute
  curl -kL 'http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest' | grep ipv4 | grep CN | awk -F\| '{ printf("%s/%d\n", $4, 32-log($5)/log(2)) }' > chnroute.txt.tmp
  curl -kL https://github.com/17mon/china_ip_list/raw/master/china_ip_list.txt > chnroute_ipip.txt.tmp
  cat chnroute.txt.tmp chnroute_ipip.txt.tmp | cidrmerge > chnroute.txt
  popd

  # ipv6 chnroute
  mkdir -p build/chnroute
  pushd build/chnroute
  curl -kL 'http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest' | grep ipv6 | grep CN | awk -F\| '{ printf("%s/%d\n", $4, 32-log($5)/log(2)) }' > chnroute_v6.txt.tmp
  mv chnroute_v6.txt.tmp chnroute_v6.txt
  popd
}

function build_dnsmasq_rules() {
  # dnsmasq rules
  mkdir -p build/dnsmasq
  pushd build/dnsmasq
  curl -kL https://easylist-downloads.adblockplus.org/easylistchina+easylist.txt | grep ^\|\|[^\*]*\^$ | sed -e 's:||:address\=\/:' -e 's:\^:/127\.0\.0\.1:' > easylistchina.conf.tmp
  curl -kL https://raw.githubusercontent.com/xinggsf/Adblock-Plus-Rule/master/ABP-FX.txt | grep ^\|\|[^\*]*\^$ | sed -e 's:||:address\=\/:' -e 's:\^:/127\.0\.0\.1:' > abp-fx.conf.tmp
  cat easylistchina.conf.tmp abp-fx.conf.tmp | sort | uniq > adblock.conf
  popd
}

function clean_up() {
  rm build/chnroute/chnroute.txt.tmp
  rm build/chnroute/chnroute_ipip.txt.tmp
  rm build/dnsmasq/easylistchina.conf.tmp
  rm build/dnsmasq/abp-fx.conf.tmp
}

function dist_release() {
  mkdir -p dist
  cp -r build/* dist
}

prepare_env

build_chnroute
build_dnsmasq_rules

clean_up
dist_release