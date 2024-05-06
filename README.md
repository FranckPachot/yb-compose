# yblab
Small Docker Compose to start a YugabyteDB lab with docker compose

Start a RF3:
```
docker compose up -d
```

Connect to first node:
```
docker compose exec -it yb ysqlsh -h yb-compose-yb-1
```

Start a RF1 and then add 2 more nodes to be RF3 then add more nodes:

```
docker compose up yb -d --scale yb=1 --no-recreate
docker compose up yb -d --scale yb=3 --no-recreate
docker compose up yb -d --scale yb=6 --no-recreate
```

You can scale down, but one node at a time, waiting 15 minutes, as that's the default to re-create replicas. 
(Or blacklist the nodes before and wait for rebalance completion)

You can get the environment to connect to the exposed ports with:
```
export PGLOADBALANCEHOSTS=random
export PGHOST=$( docker compose ps yb --format json | jq -r '[ .[].Publishers[]|select(.TargetPort==5433)| "localhost"   ] | join(",")' )
export PGPORT=$( docker compose ps yb --format json | jq -r '[ .[].Publishers[]|select(.TargetPort==5433)|.PublishedPort ] | join(",")' )
export PGUSER=yugabyte
export PGDATABASE=yugabyte
set | grep ^PG
```

## Network Delay
The NET_DELAY_MS variable adds network latency between the nodes. For example:
```
docker compose --env-file=.env.delay up -d
```
