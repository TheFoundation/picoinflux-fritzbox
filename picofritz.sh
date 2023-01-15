#!/bin/sh

SHELL=/bin/sh
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/opt/bin:~/.bin
test -e /dev/shm || mkdir /dev/shm
test -e /tmp || mkdir /tmp
mount |grep " / " |grep -q -e overlay  -e  jffs -e mmcbl && {   mount |grep -q /tmp     ||  mount -t tmpfs -o size=50m none /tmp ; } ;
mount |grep -q /dev/shm ||  mount -t tmpfs -o size=50m none /dev/shm

test  -e /system/bin/grep 2>/dev/null && export PATH=$PATH:/system/bin
test  -e /data/data/com.termux/files/usr/bin/grep 2>/dev/null && export PATH=$PATH:/data/data/com.termux/files/usr/bin/


echo >/dev/shm/picoinflux.stderr.run.log

TMPDATABASE=~/.influxdata.fritz
## if our storage is on sd card , we write to /dev/shm
mount |grep -e boot -e " / "|grep -q -e mmc -e ^overlay && TMPDATABASE=/dev/shm/.influxdata.fritz

test -e "${TMPDATABASE}" || echo > "${TMPDATABASE}"
timestamp_nanos() { if [[ $(date +%s%N |wc -c) -eq 20  ]]; then date -u +%s%N;else expr $(date -u +%s) "*" 1000 "*" 1000 "*" 1000 ; fi ; } ;

	test -f /etc/picoinfluxfritzboxes  && test -f ~/.picoinflux.conf &&	(
	 cat /etc/picoinfluxfritzboxes | while read myline;do
		hostname=${myline/:*/};
		  hostip=${myline/*:/};
		#echo $hostname $hostip
			mkdir /tmp/.picofritz &>/dev/null
			(
			#echo CONN
			echo "PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0idXRmLTgiID8+CiAgICA8czpFbnZlbG9wZSBzOmVuY29kaW5nU3R5bGU9Imh0dHA6Ly9zY2hlbWFzLnhtbHNvYXAub3JnL3NvYXAvZW5jb2RpbmcvIiB4bWxuczpzPSJodHRwOi8vc2NoZW1hcy54bWxzb2FwLm9yZy9zb2FwL2VudmVsb3BlLyI+CiAgICAgICAgPHM6Qm9keT4KICAgICAgICAgICAgPHU6R2V0U3RhdHVzSW5mbyB4bWxuczp1PSJ1cm46c2NoZW1hcy11cG5wLW9yZzpzZXJ2aWNlOldBTklQQ29ubmVjdGlvbjoxIiAvPgogICAgICAgIDwvczpCb2R5PgogICAgPC9zOkVudmVsb3BlPgoK" | base64 -d > /tmp/.picofritz/conn_st.xml
			curl -s --connect-timeout 3 "http://"$hostip":"49000"/igdupnp/control/WANIPConn1" -H "Content-Type: text/xml; charset="utf-8"" -H "SoapAction:urn:schemas-upnp-org:service:WANIPConnection:1#GetStatusInfo" -d "@/tmp/.picofritz/conn_st.xml" 2>&1 |grep New
			#echo EXTIP
			curl -s --connect-timeout 3 "http://"$hostip":"49000"/igdupnp/control/WANIPConn1" -H "Content-Type: text/xml; charset="utf-8"" -H "SoapAction:urn:schemas-upnp-org:service:WANIPConnection:1#GetExternalIPAddress" -d "@/tmp/.picofritz/conn_st.xml"  2>&1 |grep New
			#echo LINK
			echo "PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0idXRmLTgiID8+CiAgICA8czpFbnZlbG9wZSBzOmVuY29kaW5nU3R5bGU9Imh0dHA6Ly9zY2hlbWFzLnhtbHNvYXAub3JnL3NvYXAvZW5jb2RpbmcvIiB4bWxuczpzPSJodHRwOi8vc2NoZW1hcy54bWxzb2FwLm9yZy9zb2FwL2VudmVsb3BlLyI+CiAgICAgICAgPHM6Qm9keT4KICAgICAgICAgICAgPHU6R2V0Q29tbW9uTGlua1Byb3BlcnRpZXMgeG1sbnM6dT0idXJuOnNjaGVtYXMtdXBucC1vcmc6c2VydmljZTpXQU5Db21tb25JbnRlcmZhY2VDb25maWc6MSIgLz4KICAgICAgICA8L3M6Qm9keT4KICAgIDwvczpFbnZlbG9wZT4KCg==" |base64 -d  > /tmp/.picofritz/link_st.xml |grep New
			curl -s --connect-timeout 3 "http://"$hostip":"49000"/igdupnp/control/WANCommonIFC1" -H "Content-Type: text/xml; charset="utf-8"" -H "SoapAction:urn:schemas-upnp-org:service:WANCommonInterfaceConfig:1#GetCommonLinkProperties" -d "@/tmp/.picofritz/link_st.xml" 2>&1 |grep New
			#echo TRAFFIC
			curl -s --connect-timeout 3 "http://"$hostip":"49000"/igdupnp/control/WANCommonIFC1" -H "Content-Type: text/xml; charset="utf-8"" -H "SoapAction:urn:schemas-upnp-org:service:WANCommonInterfaceConfig:1#GetAddonInfos" -d "@/tmp/.picofritz/link_st.xml" 2>&1 |grep -e NewX_AVM_DE_TotalBytes -e NewByteSendRate -e NewByteReceiveRate 
			) |sed 's/<\/.\+//g;s/^<//g;s/>/=/g;s/NewX_AVM_DE_TotalBytesSent64/traffic_since_uptime_wan_tx/g;s/NewX_AVM_DE_TotalBytesReceived64/traffic_since_uptime_wan_rx/g;s/NewByteSendRate/uplink_wan_current_tx/g;s/NewByteReceiveRate/uplink_wan_current_rx/g;s/NewLayer1UpstreamMaxBitRate/uplink_wan_linkspeed_tx/g;s/NewLayer1DownstreamMaxBitRate/uplink_wan_linkspeed_rx/g;s/NewUptime/uptime/g'|while read a ;do if [[ "$a" =~ ^uplink_wan_linkspeed.* ]] ;then echo $(echo $a|cut -d"=" -f1)"="$(expr $(echo $a|cut -d"=" -f2) "/" 8 );else echo "$a";fi;done | while read b ;do if [[ "$b" =~ ^traffic_since_uptime.* ]] ;then echo $(echo $b|cut -d"=" -f1)"="$(expr $(echo $b|cut -d"=" -f2) "/" 1172951 );else echo "$b";fi;done|grep -e ^uplink -e ^traffic -e ^uptime 2>/dev/null |grep -v =$ | sed 's/=/,host='"$hostname"' value=/g'|sed 's/$/ '$(timestamp_nanos)'/g' >> $TMPDATABASE
		#cat $HOME/.influxdata.fritz.fritz
		

		done
 )

##TRANSMISSION STAGE::
##
## shall we use a proxy ?
##grep -q ^PROXYFFLUX= ${HOME}/.picoinflux.conf && export ALL_PROXY=$(grep ^PROXYFFLUX= ${HOME}/.picoinflux.conf|tail -n1 |cut -d= -f2- )

PROXYSTRING=""

##check config presence of secondary host and replicate in that case
grep -q "^SECONDARY=true" ${HOME}/.picoinflux.conf && (
    ( ( test -f ${TMPDATABASE} && cat ${TMPDATABASE} ; test -f ${TMPDATABASE}.secondary && cat ${TMPDATABASE}.secondary ) | sort |uniq > ${TMPDATABASE}.tmp ;
     mv ${TMPDATABASE}.tmp ${TMPDATABASE}.secondary )  ##
    grep -q ^PROXYFLUX_SECONDARY= ${HOME}/.picoinflux.conf && PROXYSTRING='-x '$(grep ^PROXYFLUX_SECONDARY= ${HOME}/.picoinflux.conf|tail -n1 |cut -d= -f2- )
    grep -q "^TOKEN2=true" $HOME/.picoinflux.conf && ( echo using header auth > /dev/shm/piconiflux.secondary.log; (curl $PROXYSTRING -v -k --header "Authorization: Token $(grep ^AUTH2= $HOME/.picoinflux.conf|cut -d= -f2-)" -i -XPOST "$(grep ^URL2 ~/.picoinflux.conf|cut -d= -f2-)" --data-binary @${TMPDATABASE}.secondary 2>&1 && rm ${TMPDATABASE}.secondary 2>&1 ) >/tmp/picoinflux.secondary.log  )
    grep -q "^TOKEN2=true" $HOME/.picoinflux.conf || ( echo using passwd auth > /dev/shm/piconiflux.secondary.log; (curl $PROXYSTRING -v -k -u $(grep ^AUTH2= $HOME/.picoinflux.conf|cut -d= -f2-) -i -XPOST "$(grep ^URL2 $HOME/.picoinflux.conf|cut -d= -f2-|tr -d '\n')" --data-binary @${TMPDATABASE}.secondary 2>&1 && rm ${TMPDATABASE}.secondary 2>&1 ) & ) >/tmp/picoinflux.secondary.log   )

    grep -q ^PROXYFFLUX= ${HOME}/.picoinflux.conf && PROXYSTRING='-x '$(grep ^PROXYFFLUX= ${HOME}/.picoinflux.conf|tail -n1 |cut -d= -f2- )

grep -q "^TOKEN=true" ~/.picoinflux.conf && (
  (echo using header auth > /dev/shm/piconiflux.log;echo "size $(wc -l ${TMPDATABASE})lines ";curl  $PROXYSTRING -v -k --header "Authorization: Token $(head -n1 $HOME/.picoinflux.conf)" -i -XPOST "$(head -n2 ~/.picoinflux.conf|tail -n1)" --data-binary @${TMPDATABASE} 2>&1 && mv ${TMPDATABASE} ${TMPDATABASE}.last 2>&1 ) >/tmp/picoinflux.fritz.log  )

grep -q "^TOKEN=true" ~/.picoinflux.conf || ( \
  (echo using passwd auth > /dev/shm/piconiflux.log;echo "size $(wc -l ${TMPDATABASE})lines ";curl  $PROXYSTRING -v -k -u $(head -n1 $HOME/.picoinflux.conf) -i -XPOST "$(head -n2 $HOME/.picoinflux.conf|tail -n1)" --data-binary @${TMPDATABASE} 2>&1 && mv ${TMPDATABASE} ${TMPDATABASE}.last 2>&1 ) >/tmp/picoinflux.fritz.log  )

#(curl -s -k -u $(head -n1 ~/.picoinflux.conf) -i -XPOST "$(head -n2 ~/.picoinflux.conf|tail -n1)" --data-binary @${TMPDATABASE} 2>&1 && mv ${TMPDATABASE} ${TMPDATABASE}.sent 2>&1 ) >/tmp/picoinflux.fritz.log




## picoinflux.conf examples (FIRST LINE OF THE FILE(!!) is the pass/token,second line url URL , rest is ignored except secondary config and socks )
##example V1
#user:buzzword
#https://corlysis.com:8086/write?db=mydatabase



## example V2
#KJAHSKDUHIUHIuh23ISUADHIUH2IUAWDHiojoijasd2asodijawoij12e_asdioj2ASOIDJ3==
#https://eu-central-1-1.aws.cloud2.influxdata.fritz.com/api/v2/write?org=deaf13beef12&bucket=sys&&precision=ns
#TOKEN=true


### add the following lines for a backup/secondary write with user/pass auth:
# SECONDARY=true
# URL2=https://corlysis.com:8086/write?db=mydatabase
# AUTH2=user:buzzword
# TOKEN2=false
#

##  add the following lines for a backup/secondary write with token (influx v2):
# SECONDARY=true
# URL2=https://eu-central-1-1.aws.cloud2.influxdata.fritz.com/api/v2/write?org=deaf13beef12&bucket=sys&&precision=ns
# AUTH2=KJAHSKDUHIUHIuh23ISUADHIUH2IUAWDHiojoijasd2asodijawoij12e_asdioj2ASOIDJ3==
# TOKEN2=true
#

### to use socks proxy
#PROXYFFLUX=socks5h://127.0.0.1:9050