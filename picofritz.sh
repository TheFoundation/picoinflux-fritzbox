#!/bin/sh
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
			
			) |sed 's/<\/.\+//g;s/^<//g;s/>/=/g;s/NewX_AVM_DE_TotalBytesSent64/trafficmonthly_wan_tx/g;s/NewX_AVM_DE_TotalBytesReceived64/trafficmonthly_wan_tx/g;s/NewByteSendRate/uplink_wan_current_tx/g;s/NewByteReceiveRate/uplink_wan_current_rx/g;s/NewLayer1UpstreamMaxBitRate/uplink_wan_linkspeed_tx/g;s/NewLayer1DownstreamMaxBitRate/uplink_wan_linkspeed_rx/g;s/NewUptime/uptime/g'|while read a ;do if [[ "$a" =~ ^uplink_wan_linkspeed.* ]] ;then echo $(echo $a|cut -d"=" -f1)"="$(expr $(echo $a|cut -d"=" -f2) "/" 8 );else echo "$a";fi;done |grep -e ^uplink -e ^traffic -e ^uptime 2>/dev/null |grep -v =$ | sed 's/=/,host='"$hostname"' value=/g'|sed 's/$/ '$(timestamp_nanos)'/g' >> $HOME/.influxdata.fritz
		
		#cat $HOME/.influxdata.fritz
		(curl -s -k -u $(head -n1 ~/.picoinflux.conf) -i -XPOST "$(head -n2 ~/.picoinflux.conf|tail -n1)" --data-binary @$HOME/.influxdata.fritz 2>&1 && rm  $HOME/.influxdata.fritz 2>&1 ) >/tmp/picoinfluxfritz.log 
		
		done
 )

