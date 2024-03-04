# yugabyted-compose
Docker compose to start YugabyteDB with yugabyted

Example to start a RF=3 lab:
```
docker compose up -d --scale yb=3
docker compose logs psql
```
On port 8080 you have SQLPad to connect to any node

You can run it on Gitpod free VM:

[![Open in Gitpod](https://gitpod.io/button/open-in-gitpod.svg)](https://gitpod.io/#https://github.com/FranckPachot/yugabyted-compose)

Once initialized, open the port 8080 in your browser:

![image](https://github.com/FranckPachot/yugabyted-compose/assets/33070466/11c6cc31-fc1f-4518-bbaf-e98b1a976787)

and run your queries:

![image](https://github.com/FranckPachot/yugabyted-compose/assets/33070466/c09cab08-6da7-4318-a787-3f14c3853d79)
