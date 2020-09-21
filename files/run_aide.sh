#!/bin/sh
#
# $Id: run_aide.sh,v 1.5 2004/11/02 02:00:51 root Exp $
#
# Run AIDE check and mail results to appropriate individuals.

case `/bin/uname` in
	SunOS) MAIL=/bin/mailx ;;
	Linux) MAIL=/bin/mail ;;
	*) MAIL=/bin/echo ;;
esac

# Check to see if there is a crontab entry for this script
/usr/bin/crontab -l 2>/dev/null | /bin/grep `/bin/basename $0` >/dev/null 2>&1

# If not, then create a crontab entry
if [ $? -ne 0 ] ; then
	/usr/bin/crontab -l > /var/tmp/crontab.root 2>/dev/null
	/bin/echo "5 3 * * 1-5 /usr/local/bin/run_aide.sh" >> /var/tmp/crontab.root
	/usr/bin/crontab /var/tmp/crontab.root
	rm /var/tmp/crontab.root

# Otherwise, run the AIDE check
else
	HOST=`hostname | awk -F. '{print $1}'`

	LOG=/tmp/.run_aide
	touch $LOG
	chmod 600 $LOG
	/usr/local/bin/aide --update | grep -v 'lgetfilecon_raw failed for' > $LOG
	/bin/grep 'All files match AIDE database. *Looks okay' $LOG > /dev/null 2>&1
	if [ $? -eq 0 ] ; then
		case "$HOST" in
			portappst01 ) S=`awk 'x == 0 && /^File.*in databases has different attributes/ {next} {x++} END {print x}' x=0 $LOG` ;;
			*) S=`/bin/cat $LOG | /usr/bin/wc -l`
		esac

		if [ $S -eq 7 ]; then
			exit 0
		fi
	fi

	case "$HOST" in
		awaftpp01) exit ;;
		ebiz01) exit ;;
		ebiz02) exit ;;
		ebiz03) exit ;;
		ebiz04) exit ;;
		pbsweb1) exit ;;
		sdnp01) exit ;;
		*) cat $LOG | $MAIL -s "Aide Run: `/bin/uname -n` `/bin/date +%x`" unix.mail@usairways.com ;;
	esac

	/bin/mv /usr/local/etc/aide.db.new.gz /usr/local/etc/aide.db.gz > /dev/null 2>&1
fi

exit 0
