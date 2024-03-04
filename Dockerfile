FROM  yugabytedb/yugabyte:latest
# install PgBouncer
RUN yum install -y pgbouncer
# entrypoint for yugabyted
ADD   entrypoint.sh .
HEALTHCHECK --interval=5s --timeout=5s --start-period=15s CMD postgres/bin/pg_isready -h $(hostname)
CMD   bash -x entrypoint.sh 
