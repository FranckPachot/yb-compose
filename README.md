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
