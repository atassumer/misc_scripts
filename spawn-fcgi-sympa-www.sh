#!/bin/sh

### BEGIN INIT INFO
# Provides:          spawn-fcgi-wwsympa-wrapper
# Required-Start:    $local_fs $remote_fs $network $syslog
# Required-Stop:     $local_fs $remote_fs $network $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: spawns the wwsympa-wrapper fastcgi processes
# Description:       spawns fastcgi using start-stop-daemon
### END INIT INFO

USER=sympa
USER_SOCKET=www-data
GROUP=sympa
PATH=/sbin:/bin:/usr/sbin:/usr/bin
SCRIPTNAME=/etc/init.d/spawn-fcgi-wwsympa-wrapper
SSD="/sbin/start-stop-daemon"
RETVAL=0

FCGI_DAEMON="/usr/bin/spawn-fcgi"
FCGI_PROGRAM="/usr/lib/cgi-bin/sympa/wwsympa.fcgi"
FCGI_PORT="4050"
FCGI_SOCKET="/var/run/sympa/spawn-fcgi-wwsympa-wrapper.sock"
FCGI_PIDFILE="/var/run/spawn-fcgi-wwsympa-wrapper.pid"
FCGI_CHILDREN=3

set -e

export FCGI_WEB_SERVER_ADDRS

. /lib/lsb/init-functions

case "$1" in
  start)
        log_daemon_msg "Starting spawn-fcgi"
        if ! $FCGI_DAEMON -s $FCGI_SOCKET -f $FCGI_PROGRAM -u $USER -U $USER_SOCKET -g $GROUP -P $FCGI_PIDFILE -F $FCGI_CHILDREN -C $FCGI_CHILDREN; then
            log_end_msg 1
        else
            log_end_msg 0
        fi
        RETVAL=$?
  ;;
  stop)
        log_daemon_msg "Killing all spawn-fcgi processes"
        if killall --signal 2 perl > /dev/null 2> /dev/null; then
            log_end_msg 0
        else
            log_end_msg 1
        fi
        RETVAL=$?
  ;;
  restart|force-reload)
        $0 stop
        $0 start
  ;;
  *)
        echo "Usage: $SCRIPTNAME {start|stop|restart|reload|force-reload}" >&2
        exit 1
  ;;
esac

exit $RETVAL
