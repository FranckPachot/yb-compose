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

## Testing Block corruption resilience

Reproducing  a block corruption:

```
# docker compose to start 3 nodes RF3 with yugabyted

git clone git@github.com:FranckPachot/yb-compose.git
cd yb-compose
docker compose up -d

# create a table with 3 tablets

docker compose exec -it yb yugabyted connect ysql
 create table demo ( id bigint primary key, value text) split into 3 tablets;
 insert into demo select id, 'Hello Franck' from generate_series(1,1000) id;
 select count(*), value from demo group by value;
 \q

# flush the memtable and corrupt the files by changing two bytes

docker exec -it yb-compose-yb-3 bash
 yb-ts-cli -server_address yb-compose-yb-3 flush_all_tablets
 for corrupt_me in /root/var/data/yb-data/tserver/data/rocksdb/table-000033c0000030008000000000004000/tablet-*/*.sst.sblock.0
 do
 echo "Let's corrupt $corrupt_me"
  hexdump -C "$corrupt_me" > /var/tmp/before.txt
  cat "$corrupt_me" > /var/tmp/sst.tmp
  sed -e 's/Franck/Frank /g' /var/tmp/sst.tmp > "$corrupt_me"
  hexdump -C "$corrupt_me" > /var/tmp/after.txt
  diff /var/tmp/before.txt /var/tmp/after.txt
 done

 # query the table (there's a leader with the corrupted file)

 ysqlsh -h $(hostname) -c " select count(*), value from demo group by value "

```

The SELECT fails with:

```
ERROR:  Block checksum mismatch in file: /root/var/data/yb-data/tserver/data/rocksdb/table-000033c0000030008000000000004000/tablet-152b381ae7094616ba737fa0e4415415/000010.sst.sblock.0, block handle: BlockHandle { offset: 0 size: 6988 }, expected checksum: 3854809050, actual checksum: 953980222.
```

The log shows:
```
[root@e1943d0a5b6b yugabyte]# grep -iE "corrupt|checksum|000033c0000030008000000000004000" /root/var/logs/tserver/yb-tserver.INFO

W0328 11:23:52.761096   247 file_reader_writer.cc:99] Read attempt #1 failed in file /root/var/data/yb-data/tserver/data/rocksdb/table-000033c0000030008000000000004000/tablet-152b381ae7094616ba737fa0e4415415/000010.sst.sblock.0 : Corruption (yb/rocksdb/table/format.cc:345): Block checksum mismatch in file: /root/var/data/yb-data/tserver/data/rocksdb/table-000033c0000030008000000000004000/tablet-152b381ae7094616ba737fa0e4415415/000010.sst.sblock.0, block handle: BlockHandle { offset: 0 size: 6988 }, expected checksum: 3854809050, actual checksum: 953980222.
W0328 11:23:52.761144   247 file_reader_writer.cc:99] Read attempt #2 failed in file /root/var/data/yb-data/tserver/data/rocksdb/table-000033c0000030008000000000004000/tablet-152b381ae7094616ba737fa0e4415415/000010.sst.sblock.0 : Corruption (yb/rocksdb/table/format.cc:345): Block checksum mismatch in file: /root/var/data/yb-data/tserver/data/rocksdb/table-000033c0000030008000000000004000/tablet-152b381ae7094616ba737fa0e4415415/000010.sst.sblock.0, block handle: BlockHandle { offset: 0 size: 6988 }, expected checksum: 3854809050, actual checksum: 953980222.
E0328 11:23:52.761163   247 format.cc:466] ReadBlockContents: Corruption (yb/rocksdb/table/format.cc:345): Block checksum mismatch in file: /root/var/data/yb-data/tserver/data/rocksdb/table-000033c0000030008000000000004000/tablet-152b381ae7094616ba737fa0e4415415/000010.sst.sblock.0, block handle: BlockHandle { offset: 0 size: 6988 }, expected checksum: 3854809050, actual checksum: 953980222.
```

If I delete the corrupted tablets, they are bootstrapped and I can query the table again:
```
for tablet_to_delete in $(
awk '$0~re{print gensub(re,"\\1",1)}' re='.*ReadBlockContents: Corruption.*Block checksum mismatch in file: .*/tablet-([0-9a-f]+)/000010.sst.sblock.0, block handle:.*' /root/var/logs/tserver/yb-tserver.INFO | uniq
) ; do
 yb-ts-cli -server_address yb-compose-yb-3 delete_tablet "$tablet_to_delete" "ReadBlockContents: Corruption"
done

ysqlsh -h $(hostname) -c " select count(*), value from demo group by value "

```


