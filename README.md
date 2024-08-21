# yblab
Small Docker Compose to start a YugabyteDB lab with docker compose

Start a RF3:
```
docker compose down
docker compose up -d --scale yb=3 --no-recreate
```

Connect to first node:
```
docker compose exec -it yb ysqlsh -h yb-compose-yb-1
```

add more nodes (one after the other as balances to regions by conting the existing ones):

```
for i in {4..6} ; do docker compose up -d --scale yb=$i --no-recreate ; done
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

## Tablespaces
The nodes are placed in region1, region2 and region 3
You can create the following tablespaces:
```
docker compose run -it pg psql -h yb-compose-yb-1

select * from yb_servers();

create tablespace "region1" with ( replica_placement= $$
{ "num_replicas":1,"placement_blocks":[{ "cloud":"cloud","region":"region1","zone": "zone","min_num_replicas": 1 } ] }
$$) ;
create tablespace "region2" with ( replica_placement=$$
{ "num_replicas":1,"placement_blocks":[{ "cloud":"cloud","region":"region2","zone": "zone","min_num_replicas": 1 } ] }
$$) ;
create tablespace "region3" with ( replica_placement=$$
{ "num_replicas":1,"placement_blocks":[{ "cloud":"cloud","region":"region3","zone": "zone","min_num_replicas": 1 } ] }
$$) ;

create tablespace "pref1" with ( replica_placement=$$
{ "num_replicas":3,"placement_blocks":[
 { "cloud":"cloud","region":"region1","zone": "zone","min_num_replicas":1,"leader_preference":1 },
 { "cloud":"cloud","region":"region2","zone": "zone","min_num_replicas":1,"leader_preference":2 },
 { "cloud":"cloud","region":"region3","zone": "zone","min_num_replicas":1,"leader_preference":3 }
] }
$$) ;

select * from pg_tablespace;

```
