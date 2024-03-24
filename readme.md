
# Docker  Postgres  (2 часть)

    $ docker ps    // список всех запущенных контейнеров
    $ docker images   // список всех имеющихся образов

## Удалить установленный Postgres

    Uninstall the PostgreSQL application
    $ sudo apt-get --purge remove postgresql
    Remove PostgreSQL packages
    $ dpkg -l | grep postgres
    To uninstall PostgreSQL completely, you need to remove all of these packages using the following command:
    $ sudo apt-get --purge remove <package_name>
    Remove PostgreSQL directories
    $ sudo rm -rf /var/lib/postgresql/
    $ sudo rm -rf /var/log/postgresql/
    $ sudo rm -rf /etc/postgresql/
    Remove the postgres user
    $ sudo deluser postgres
    Verify uninstallation
    $ psql --version

## Скачать образ

<https://hub.docker.com/>   
поиск postgres   
<https://hub.docker.com/_/postgres>

    docker pull <image>:<tag>
    $ docker pull postgres:16-alpine
<br>

## Запуск контейнера из образа

`docker run --name <container_name> -e <environment_variable> -d <image>:<tag>`

Environment Variables:
* POSTGRES_PASSWORD   
* POSTGRES_USER   
* POSTGRES_DB   
* POSTGRES_INITDB_ARGS   
* POSTGRES_INITDB_WALDIR   
* POSTGRES_HOST_AUTH_METHOD   
* PGDATA   

For example:
```
$ docker run -d \
    --name some-postgres \
    -e POSTGRES_PASSWORD=mysecretpassword \
    -e PGDATA=/var/lib/postgresql/data/pgdata \
    -v /custom/mount:/var/lib/postgresql/data \
    postgres
```

пароли можно подгружать из файла:   
    `$ docker run --name some-postgres -e POSTGRES_PASSWORD_FILE=/run/secrets/postgres-passwd -d postgres`

Port mapping    
    `docker run --name ‹container_name> -e ‹environment_variable> -p ‹host_ports:container_ports> -d ‹image>:<tag>`

    $ docker run --name postgres16 -p 5432:5432 -e POSTGRES_USER=root -e POSTGRES_PASSWORD=secret -d postgres:16-alpine
    $ docker ps

    $ docker stop postgres16
    $ docker ps -a   // все контейнеры вне зависимости запущены или нет
    $ docker start postgres16   // снова запустить имеющийся контейнер
    $ docker rm postgres16   // удалить полностью имеющийся контейнер
<br>

## Запуск команды в контейнере

    docker exec -it ‹container _name_or_id> ‹command> [args]

    $ docker exec -it postgres16 psql -U root
        select now();
        \q    - выход

    $ docker exec -it postgres16 /bin/sh     // запускаем оболочку в контейнере
<br>

## Просмотр логов контейнера

    docker logs <container_name_or_id>
    $ docker logs postgres16
<br>
<br>

---------
# TablePlus

Для kubuntu лучше либо pgAdmin4 либо DBeaver

<https://tableplus.com/>   
`basename: root`, `user: root`, `password: secret`, `url: localhost:5432`
<br>
<br>

---------
# Миграции  (3 часть)

<https://github.com/golang-migrate/migrate>

    $ brew install golang-migrate
    $ migrate -version
        v4.17.0
    $ migrate -help

    $ migrate create -ext sql -dir db/migration -seq init schema


    $ docker exec -it postgres16 /bin/sh
        # createdb -username=root -owner=root main_db
        # psql main_db
        # dropdb main_db
        # exit

    $ docker exec postgres16 createdb --username=root --owner=root main_db
    $ docker exec -it postgres12 psql -U root main_db
        \q

### Миграция в проекте

    $ set -e
    $ source ./app.env
    // если нет базы  $ docker exec postgres16 createdb --username=root --owner=root main_db
    $ migrate -path ./db/migration -database "$DB_SOURCE" -verbose up

<br>

## Cоздаем Makefile

    run-postgres: ## Start postgresql database docker image.
        docker run --name postgres16 -p 5432:5432 -e POSTGRES_USER=root -e POSTGRES_PASSWORD=secret -d postgres:16-alpine

    start-postgres16: ## Start available postgresql database docker container.
        docker start postgres16

    stop-postgres: ## Stop postgresql database docker image.
        docker stop postgres16
<br>


---------
# CRUD  (4 часть)

* Create
* Read
* Update
* Delete

> DATABASE/SOL   
> * Очень быстро и просто
> * Ручное сопоставление полей SQL с переменными 
> * Легко допускать ошибки, которые не обнаруживаются до выполнения

> GORM
> * Функции CRUD уже реализованы, очень короткий рабочий код
> * Необходимо научиться писать запросы с использованием функции gorm
> * Выполняется медленно при высокой нагрузке   
> * В 3 - 5  раз медленнее работает

> SQLX
> * Довольно быстрый и простой в использовании
> * Сопоставление полей с помощью тегов текста запроса и структуры
> * Сбой не произойдет до времени выполнения

> SQLC
> * Очень быстрый и простой в использовании
> * Автоматическая генерация кода
> * Отслеживание ошибок запроса SQL перед генерацией кодов
> * Полная поддержка Postgres. MySQL является экспериментальным

<https://sqlc.dev/>   
<https://github.com/sqlc-dev/sqlc>

    $ brew install sqlc
    $ sqlc version
    $ sqlc help
    $ sqlc init

sqlc.yaml
<https://docs.sqlc.dev/en/latest/tutorials/getting-started-postgresql.html#setting-up>

    $ sqlc generate

db/query/account.sql
<https://docs.sqlc.dev/en/latest/tutorials/getting-started-postgresql.html#schema-and-queries>
<br>
<br>


# Тесты (5 часть)

    _ "github.com/lib/pq"  // без драйвера работать не будет

    $ go test -v   // все тесты

    $ go test -timeout 30s ./db/sqlc -run ^TestMain$             
        ok  	github.com/Country7/backend-webwizards/db/sqlc	0.433s [no tests to run]

    $ make test   // команда test из файла Makefile
<br>
<br>


# Транзакции (6 часть)

Перевод 10 USD
из банка аккаунта 1
в банк аккаунта 2

1. Создайте запись о переводе с суммой = 10
2. Создайте учетную запись для учетной записи 1 с суммой = -10
3. Создайте учетную запись для учетной записи 2 с суммой = +10
4. Вычтите 10 из баланса учетной записи 1
5. Добавьте 10 к балансу учетной записи 2

<br>

> *    BEGIN
> *    ...
> *    COMMIT
or
> *    BEGIN
> *    ...
> *    ROLLBACK

<br>

```go
    type Store interface {
        Querier
        TransferTx(ctx context.Context, arg TransferTxParams) (TransferTxResult, error)
    }

    // SQLStore provides all functions to execute SQL queries and transactions.
    type SQLStore struct {
        *Queries
        db *sql.DB
    }

    func NewStore(db *sql.DB) Store {
        return &SQLStore{db: db, Queries: New(db)}
    }

    // execTx executes a function within a database transaction.
    func (s *SQLStore) execTx(ctx context.Context, fn func(queries *Queries) error) error {
        tx, err := s.db.BeginTx(ctx, nil)
        if err != nil {
            return err
        }

        q := New(tx)
        err = fn(q)
        if err != nil {
            if rbErr := tx.Rollback(); rbErr != nil {
                return fmt.Errorf("tx err: %v, rb err: %v", err, rbErr)
            }
            return err
        }

        return tx.Commit()
    }
```
<br>
<br>

# Блокировка транзакции (7 часть)

    BEGIN;
    
    SELECT * FROM accounts WHERE id = 1;

    SELECT * FROM WHERE id = 1 FOR UPDATE;     // блокировка запросов
    UPDATE accounts SET balance = 500 WHERE id = 1;
    COMMIT;
<br>

    $ sqlc generate

### Deadlock detected

    INSERT INTO entries (account_id, amount) VALUES ($1, $2) RETURNING *;
и
    
    SELECT * FROM accounts WHERE id = $1 LIMIT 1 FOR UPDATE;
заблокируют друг друга (Deadlock detected) несмотря на то, что обращение идет к разным таблицам

Эти две таблицы имеют связи FOREIGN KEY:   
ALTER TABLE "entries" ADD FOREIGN KEY ("account_id") REFERENCES "accounts" ("id");   
при обращении к accounts происходит обновление ключа id в таблице accounts по связям с entries   
чтобы этого не происходило необходима команда !!! NO KEY UPDATE

    SELECT * FROM accounts WHERE id = $1 LIMIT 1 FOR NO KEY UPDATE;

<br><br>


# Взаимоблокировки (8 часть)

```sql
    BEGIN:
    UPDATE accounts SET balance = balance - 10 WHERE id = 1 RETURNING *;
    UPDATE accounts SET balance = balance + 10 WHERE id = 2 RETURNING *;
    ROLLBACK;

    BEGIN:
    UPDATE accounts SET balance = balance - 10 WHERE id = 2 RETURNING *;
    UPDATE accounts SET balance = balance + 10 WHERE id = 1 RETURNING *;
    ROLLBACK;
```

Одновременно две эти транзакции приведут в взаимоблокировке (Deadlock detected)

```go
    if arg.FromAccountID < arg.ToAccountID {
        result.FromAccount, result.ToAccount, err = addMoney(ctx, q, arg.FromAccountID, -arg.Amount, arg.ToAccountID, arg.Amount)
    } else {
        result.ToAccount, result.FromAccount, err = addMoney(ctx, q, arg.ToAccountID, arg.Amount, arg.FromAccountID, -arg.Amount)
    }
```
<br>
<br>


# Уровень изоляции транзакций (9 часть)


1. Чтение незафиксированных транзакций (read uncommitted)
2. Чтение зафиксированных данных (read committed)
3. Повторяемый уровень изоляции чтения (repeatable read)
4. Параллельные разрешения (serializable)

```shell
    mysql> select @@transaction_isolation;
    mysql> select @@global.transaction_isolation;

    mysql> set session transaction isolation level read uncommitted;
    mysql> set session transaction isolation level read committed;
    mysql> set session transaction isolation level repeatable read;
    mysql> set session transaction isolation level serializable;
```

```shell
    postgres=# show transaction isolation level;

    postgres=# begin;
    postgres=# set transaction isolation level read uncommitted;
    # в postgres уровень read uncommitted ведет себя как read committed, как будто его нет
    postgres=# set transaction isolation level read committed;
    postgres=# set transaction isolation level repeatable read;
    postgres=# set transaction isolation level serializable;
    postgres=# show transaction isolation level;
    postgres=# commit;
```

|                       |READ UNCOMMITTED   | READ COMMITTED    | REPEATABLE READ   | SERIALIZABLE  |
|:-:                    |:-:                |:-:                |:-:                |:-:            |
| DIRTY READ            | V                 |         -         |         -         |       -       |
| NON-REPEATABLE READ   | V                 | V                 |         -         |       -       |
| PHANTOM READ          | V                 | V                 |         -         |       -       |
| SERIALIZATION ANOMALY | V                 | V                 | V                 |       -       |
<br>
<br>


# Действие на Github Go + Postgres (10 часть)

> Рабочий процесс:
> * Является автоматизированной процедурой
> * Состоит из 1+ заданий
> * Запускается по событиям, по расписанию или вручную
> * Добавьте файл .yml в репозиторий

> Запуск (Runner)
> * Является ли сервер для запуска заданий
> * Запускайте по 1 заданию за раз
> * Размещено на github или самостоятельно
> * Сообщайте о ходе выполнения, журналах и результатах на github

> Задания (Job)
> * Представляет собой набор шагов, выполняемых в одном и том же runner
> * Обычные задания выполняются параллельно
> * Зависимые задания выполняются последовательно

> Шаг
> * Является отдельной задачей
> * Выполняется последовательно в рамках задания
> * Содержит более 1 действия

> Действие
> * Является автономной командой
> * Выполняется последовательно в пределах шага
> * Может использоваться повторно




<br>
<br>
<br>

# PS

#### Собрать все зависимости из go.mod

    $ go mod tidy
