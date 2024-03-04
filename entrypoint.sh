##########################################
# start PgBouncer
##########################################
cat > /etc/pgbouncer/pgbouncer.users <<'CAT'
 "yugabyte" "yugabyte"
CAT
cat > /etc/pgbouncer/pgbouncer.ini <<INI
 [databases]
 yugabyte = port=5433 dbname=yugabyte host=$(hostname)
 [pgbouncer]
 listen_addr = $(hostname)
 listen_port = 6432
 auth_type = md5
 auth_file = /etc/pgbouncer/pgbouncer.users
 logfile = /var/tmp/pgbouncer.log
 pidfile = /var/tmp/pgbouncer.pid
 admin_users = admin
 user = pgbouncer
 pool_mode = transaction
 default_pool_size=5
 min_pool_size=5
INI
usermod pgbouncer /bin/bash
pgbouncer -dv /etc/pgbouncer/pgbouncer.ini

##########################################
# start YugabyteDB
##########################################
yugabyted_args=""
if [ -f /root/var/conf/yugabyted.conf ]
then # config already exists, ignore init flags
 tserver_flags="" 
 rm -rf /tmp/.yb.* 
else
 if host "$yugabyted_join" | grep " $(hostname -i)" 
 then
  echo "Ignoring join: $yugabyted_join == $(host $yugabyted_join)"
 else
  until postgres/bin/pg_isready -h "$yugabyted_join" ; do sleep 1 ; done | uniq
  yugabyted_args="--join=$yugabyted_join $yugabyted_args"
 fi
fi
sleep $( host $(hostname -i) | cut -c1 ) # try to not get all at the same time
yugabyted_args="$yugabyted_args --cloud_location=$yugabyted_cloud_location"
yugabyted start --background=false $yugabyted_args --tserver_flags=$tserver_flags
