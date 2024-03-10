![Tests](https://github.com/jbdoumenjou/backend-master-class-golang-postgresql-kubernetes/actions/workflows/ci.yml/badge.svg)

This repository contains all notes and experimentation
following the Udemy course [Backend Master Class [Golang + Postgres + Kubernetes + gRPC]](https://www.udemy.com/course/backend-master-class-golang-postgresql-kubernetes/)

# Usage

Use the Makefile to launch and use the database.
```shell
$make help
help:                 Show this help.
pull-images:          Pull the needed docker images.
create-db:            Create the database.
drop-db:              Drop the database.
migrate-up:           Apply all up migrations.
migrate-up-1:         Apply the last up migration.
migrate-down:         Apply all down migrations.
migrate-down-1:       Apply the last down migration.
start-postgres:       Start postgresql database docker image.
stop-postgres:        Stop postgresql database docker image.
run-postgres-cli:     Run psql on the postgres15 docker container.
sqlc:                 sqlc generate.
docker-system-clean:  Docker system clean.
test:                 Test go files and report coverage.
server:               Run the application server.
mock:                 Generate a store mock.
```

# DataBase

* Use https://dbdiagram.io/ to create a schema, then export it in SQL
* Chose a client like:
    * [psql cli](https://www.postgresql.org/docs/13/app-psql.html)
    * [dbeaver](https://dbeaver.io/)
    * Goland data source
* A docker command line has been configured in the Makefile.
  Following this configuration,
  the attributes to use in the DB client are: `basename: root`, `user: root`, `password: secret`, `url: localhost:5432`

## ORM or Not ?

There are several choices to interact with the database from the code:
* using database/sql package and writing SQL requests by hand.
* using an orm like [gorm](https://github.com/go-gorm/gorm).
* slqx an in-between, providing some function but is not an ORM
* [sqlc](https://github.com/sqlc-dev/sqlc) another in-between but well suited for postgresql.

In this course, we will use sqlc.

## Driver

* https://github.com/lib/pq
```shell
go get github.com/lib/pq
```

## Migration 

Install [golang-migrate](https://github.com/golang-migrate/migrate) 
```shell
 go install github.com/golang-migrate/migrate/v4/cmd/migrate@latest
```

I had an issue with this installation: ` error: database driver: unknown driver postgresql (forgotten import?)`.  
I re-install with the following [command](https://github.com/golang-migrate/migrate/tree/master/cmd/migrate#versioned):
```shell
go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest
```
It seems to fix the issue.

Create a folder db/migration to store migration.
Initialize schema migration management:
```shell
migrate create -ext sql -dir db/migration -seq init_schema
```

Add users:

```shell
migrate create -ext sql -dir db/migration -seq add_users
```

## Manage DB locks

Add log/data inside code to identify the queries order, then you can replay this sequence in another client.
Then, you can use specific [psql query](https://wiki.postgresql.org/wiki/Lock_Monitoring) to find the deadlock and some data about it.
```sql
  SELECT blocked_locks.pid     AS blocked_pid,
         blocked_activity.usename  AS blocked_user,
         blocking_locks.pid     AS blocking_pid,
         blocking_activity.usename AS blocking_user,
         blocked_activity.query    AS blocked_statement,
         blocking_activity.query   AS current_statement_in_blocking_process
   FROM  pg_catalog.pg_locks         blocked_locks
    JOIN pg_catalog.pg_stat_activity blocked_activity  ON blocked_activity.pid = blocked_locks.pid
    JOIN pg_catalog.pg_locks         blocking_locks 
        ON blocking_locks.locktype = blocked_locks.locktype
        AND blocking_locks.database IS NOT DISTINCT FROM blocked_locks.database
        AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
        AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
        AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
        AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
        AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
        AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
        AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
        AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
        AND blocking_locks.pid != blocked_locks.pid

    JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
   WHERE NOT blocked_locks.granted;
```
Query adapted for our use case. We are searching for the first account balance deadlock.
We only have one base with 2 concurrents queries.
```sql
SELECT a.datname,
        a.application_name,
         l.relation::regclass,
         l.transactionid,
         l.mode,
         l.locktype,
         l.GRANTED,
         a.usename,
         a.query,
         a.pid
FROM pg_stat_activity a
JOIN pg_locks l ON l.pid = a.pid
ORDER BY a.pid;
```

## Isolation Level

>In database systems, isolation determines how transaction integrity is visible to other users and systems.
>
>A lower isolation level increases the ability of many users to access the same data at the same time,
but increases the number of concurrency effects (such as dirty reads or lost updates) users might encounter.
Conversely, a higher isolation level reduces the types of concurrency effects that users may encounter,
but requires more system resources and increases the chances that one transaction will block another.
>
>Isolation is typically defined at database level as a property that defines how or when the changes made by one operation become visible to others.
On older systems, it may be implemented systemically, for example through the use of temporary tables.
In two-tier systems, a transaction processing (TP) manager is required to maintain isolation.
In n-tier systems (such as multiple websites attempting to book the last seat on a flight),
a combination of stored procedures and transaction management is required to commit the booking and send confirmation to the customer.
Isolation is one of the four ACID properties, along with atomicity, consistency and durability.

https://en.wikipedia.org/wiki/Isolation_(database_systems)


| Read phenomenon </br>____________</br>Isolation level | Dirty read | Non-repeatable read | 	Phantom read |
|-------------------------------------------------------|------------|---------------------|---------------|
| Serializable 	                                        | no         | 	no                 | 	no           |
| Repeatable read                                       | 	no        | 	no                 | 	yes          |
| Read committed                                        | 	no        | 	yes                | 	yes          |
| Read uncommitted                                      | 	yes       | 	yes                | 	yes          |

https://www.postgresql.org/docs/15/transaction-iso.html

## Documentation

Install dbdocs CLI
```shell  
yarn global add dbdocs
```

Login to dbdocs
```shell
dbdocs login
```

Generate online documentation
```shell
dbdocs build doc/db.dbml
```

Add a password to the documentation
```shell
dbdocs password --set <password>  --project main_db
```

Install dbml CLI
```shell
yarn global add @dbml/cli
```


# JWT

Server must check if the algorithm header matches the one it is using to sign tokens.
Check all known vulnerabilities.
To avoid possible vulnerabilities with JWT, the course proposes to use PASETO.

# Platform-Agnostic SEcurity TOkens [PASETO]

https://paseto.io/

Stronger algorithms

https://github.com/golang-jwt/jwt


# Docker

Check the network and find why we can't access to the database.
-> There aren't on the same network, we need to find another way to access the database.
```shell
docker container inspect simplebank
```

Check the networks
```shell
$docker network ls
NETWORK ID     NAME      DRIVER    SCOPE
29c75cdf92f3   bridge    bridge    local
70e8d2d984b4   host      host      local
d71f8961e332   none      null      local
```
Check the containers that user the bridge network
```shell
$docker network inspect bridge | jq '[ .[].Containers ]'
[
  {
    "2afbe995aee9d62d5e0c0cf4b6e62037ea10c62ee39a52653eb26f0a9e7cc620": {
      "Name": "postgres15",
      "EndpointID": "a294538e900fd5fa367d5bc26879cf76af3be2361881ed916bbddcbcc9ec23df",
      "MacAddress": "02:42:ac:11:00:03",
      "IPv4Address": "172.17.0.3/16",
      "IPv6Address": ""
    }
  }
]
```
So we have to crete a common network, let's call it "bank-network".
```shell
docker network create bank-network
```
Then connect the postgres container to this new network
```shell
docker network connect bank-network postgres15
```
Checks that the postgres container is in the bank-network network
```shell
docker network inspect bank-network | jq "[ .[].Containers ]"                                                               ✔ 
[
  {
    "2afbe995aee9d62d5e0c0cf4b6e62037ea10c62ee39a52653eb26f0a9e7cc620": {
      "Name": "postgres15",
      "EndpointID": "e2c8e184a89851edd91963250c2f2c274d307d77b083e5ef2915f30273d5d95c",
      "MacAddress": "02:42:ac:12:00:02",
      "IPv4Address": "172.18.0.2/16",
      "IPv6Address": ""
    }
  }
]
```

Now check the networks of postgres15 container
```shell
docker container inspect postgres15 | jq -r '[ .[].NetworkSettings.Networks]'
```
We can see both `bridge` and `bank-network` networks. 

## Docker Compose

https://docs.docker.com/compose/compose-file/compose-file-v3/
> The Compose Specification lets you define a platform-agnostic container based application.
> Such an application is designed as a set of containers
> which have to both run together with adequate shared resources and communication channels.

To apply the migration, we have to wait the the dadabase to be started.
`depends_on` is not enough because it wait for container to be started, not the app inside.
To do that, we need to control startup and shutdown
https://docs.docker.com/compose/startup-order/

We can use a specific condition on a `depends_on` configuration.
Here we can wait for a `service_healthy` of the postgres container 
```yaml
  postgres:
    # ...
    healthcheck:
      test: pg_isready -U root -d main_db
      interval: 5s
      timeout: 5s
      retries: 5
  api:
    # ...
    depends_on:
      postgres:
        condition: service_healthy
```

# AWS

Provide a free tier: https://aws.amazon.com/free

Create a repository in AWS ECR.
Let the default option and name the repository `simplebank` in this case.
[use private registry](https://docs.aws.amazon.com/AmazonECR/latest/userguide/Registries.html#registry_auth)
[private registry authentication](https://docs.aws.amazon.com/AmazonECR/latest/userguide/registry_auth.html)

Search how to [configure aws-cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-quickstart.html)

Let's try the [SSO Token](https://docs.aws.amazon.com/cli/latest/userguide/sso-configure-profile-token.html) way.  
Following [these steps](https://docs.aws.amazon.com/cli/latest/userguide/sso-configure-profile-token.html#sso-configure-profile-token-auto-sso)  
The fist step is another redirection, create some resources following [this doc](https://docs.aws.amazon.com/singlesignon/latest/userguide/getting-started.html)

The last version of this GH action use an arn to associate a specific role and so specific rights.
I follow https://aws.amazon.com/blogs/security/use-iam-roles-to-connect-github-actions-to-actions-in-aws/


```shell
aws iam create-open-id-connect-provider ‐‐url "https://token.actions.githubusercontent.com" ‐‐thumbprint-list "6938fd4d98bab03faadb97b34396831e3780aea1" ‐‐client-id-list 'sts.amazonaws.com'
```

I had several configuration issues with this type of configuration.
That's why I start with the previous `configure-aws-credentials@v1` configuration.

Connect to the registry:
```shell
# get the token and use it to login with the registry URL.
aws ecr get-login-password | docker login --username AWS --password-stdin xxx.dkr.ecr.eu-west-3.amazonaws.com
```

# Github

https://github.com/marketplace to find GH actions.  
[aws ecr gh actions](https://github.com/marketplace?type=actions&query=aws+ecr+)
Choose [Amazon ECT "Login" Action for Github Actions](https://github.com/marketplace/actions/amazon-ecr-login-action-for-github-actions).  

# Kubernetes

* https://kubernetes.io/docs/reference/kubectl/

use aws eks cluster locally:

```shell
aws eks update-kubeconfig --name simple-bank --region eu-west-3
```

select the context to use:
```shell
kubectl config get-contexts
kubectl config use-context arn:aws:eks:eu-west-3:xxxxxxxxxxxx:cluster/simple-bank
``` 

```shell
kubectl cluster-info                                                                                                  ✔  simple-bank ⎈ 

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
error: You must be logged in to the server (the server has asked for the client to provide credentials)
```

The user used for the local cli is not the user that created the eks cluster.
cf https://repost.aws/knowledge-center/amazon-eks-cluster-access

First get the user entity

```shell
aws sts get-caller-identity | jq                                                                                      ✔  13s  
{
  "UserId": "XXXXXX",
  "Account": "XXXXXX",
  "Arn": "arn:aws:iam::XXXXXX:user/jbd-cli"
}
```
Update the  ~/.aws/credentials with credentials of the user that creates the cluster.

Tool to manage kubernetes cluster: https://k9scli.io/

Install an ingress controller:
```shell
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/aws/deploy.yaml
```

Install cert-manager
```shell
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.1/cert-manager.yaml
```

One way to check the last stable version of kubernetes:  
http://storage.googleapis.com/kubernetes-release/release/stable.txt


# References

* https://aws.amazon.com/free
* https://cert-manager.io/
* https://dbdiagram.io/
* https://dbdocs.io
* https://dbeaver.io/
* https://docs.aws.amazon.com/AmazonECR/latest/userguide/Registries.html#registry_auth
* https://docs.docker.com/compose/compose-file/compose-file-v3/
* https://docs.docker.com/compose/startup-order/
* https://en.wikipedia.org/wiki/ACID
* https://en.wikipedia.org/wiki/American_National_Standards_Institute
* https://github.com/golang-jwt/jwt
* https://github.com/golang-migrate/migrate
* https://github.com/holistics/dbml/
* https://github.com/jackc/pgx
* https://github.com/lib/pq
* https://github.com/marketplace
* https://github.com/marketplace/actions/kubectl-tool-installer
* https://github.com/techschool/simplebank
* https://github.com/uber-go/mock
* https://go.dev/tour/
* https://hub.docker.com/_/postgres
* https://www.postgresql.org/docs/15/transaction-iso.html
* https://sqlc.dev/
* http://storage.googleapis.com/kubernetes-release/release/stable.txt
* https://tableplus.com (not supported on Linux anymore)
* https://wiki.postgresql.org/wiki/Lock_Monitoring

# Notes

## DataBase Client installation

I chose dbeaver instead of Tableplus because it is no longer supported on Linux.
I had an issue with my arch Linux with the JDK version.
To fix it, check the available JDK then set the right one by using the following commands:
```shell
$archlinux-java status                                                                                      ✔ 
Available Java environments:
  java-20-OpenJDK
  java-8-openjdk/jre (default)
$sudo archlinux-java set java-20-openjdk
$archlinux-java status
Available Java environments:
  java-20-openjdk (default)
  java-8-OpenJDK/jre
```

To generate a stronger TOKEN_SYMMETRIC_KEY:

```shell
openssl rand -hex 64 | head -c 32
```