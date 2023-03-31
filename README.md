# picoinflux-fritzbox
minmal influx monitoring of recent trizboxes with shell

## Usage
* create a file named `/etc/picoinfluxfritzboxes` with the following (example ) syntax : 

   ```
   fritzboxa:192.16.178.1
   fritzboxb:192.16.111.1
   ```
   
   the entries in influxdb will be tagged with the hostname from the config 

* create picoinflux credentials if not already present
* run the script through cron
## exported values (measurements)

| name | unit |
|--|--|
| uptime | s |
| uplink_wan_linkspeed_rx | bits |
| uplink_wan_linkspeed_tx | bits |
| traffic_since_uptime_wan_tx | bytes |
| traffic_since_uptime_wan_tx | bytes |


## Storage

TMPDATABASE=~/.influxdata.fritz

---

<a href="https://the-foundation.gitlab.io/">
<h3>A project of the foundation</h3>
<div><img src="https://hcxi2.2ix.ch/gitlab/the-foundation/docker-perdition/README.md/logo.jpg" width="480" height="270"/></div></a>

