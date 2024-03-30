
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

__Environment Variables:__
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

> __DATABASE/SQL__
> * Очень быстро и просто
> * Ручное сопоставление полей SQL с переменными 
> * Легко допускать ошибки, которые не обнаруживаются до выполнения

> __GORM__
> * Функции CRUD уже реализованы, очень короткий рабочий код
> * Необходимо научиться писать запросы с использованием функции gorm
> * Выполняется медленно при высокой нагрузке   
> * В 3 - 5  раз медленнее работает

> __SQLX__
> * Довольно быстрый и простой в использовании
> * Сопоставление полей с помощью тегов текста запроса и структуры
> * Сбой не произойдет до времени выполнения

> __SQLC__
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

Перевод 10 USD из банка аккаунта 1 в банк аккаунта 2:

1. Создайте запись транзакции о переводе с суммой = 10
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

> __Рабочий процесс:__
> * Является автоматизированной процедурой
> * Состоит из 1+ заданий
> * Запускается по событиям, по расписанию или вручную
> * Добавьте файл .yml в репозиторий

> __Запуск (Runner)__
> * Является ли сервер для запуска заданий
> * Запускайте по 1 заданию за раз
> * Размещено на github или самостоятельно
> * Сообщайте о ходе выполнения, журналах и результатах на github

> __Задания (Job)__
> * Представляет собой набор шагов, выполняемых в одном и том же runner
> * Обычные задания выполняются параллельно
> * Зависимые задания выполняются последовательно

> __Шаг__
> * Является отдельной задачей
> * Выполняется последовательно в рамках задания
> * Содержит более 1 действия

> __Действие__
> * Является автономной командой
> * Выполняется последовательно в пределах шага
> * Может использоваться повторно

<br>
<br>

# ---------------------------------------------

# Реализация RESTful HTTP API в Go с помощью Gin (11 часть: 2.1)

> __Стандартный пакет net/http__
<br>

> __Popular web frameworks__
> * Gin
> * Beego
> * Echo
> * Revel
> * Martini
> * Fiber
> * Buffalo
<br>

> __Popular HTTP routers__
> * FastHttp
> * Gorilla Mux
> * HttpRouter
> * Chi
<br>

Самый популярный - __Gin__ - <github.com/gin-gonic/gin>

api/server.go   
api/account.go   
main.go

в main.go обязательно добавить импорт драйвера

    _ "github.com/lib/pq"

Makefile:

    server: ## Run the application server.
        go run main.go

__В целях тестирования запросов установить Postman__

    GET http://localhost:8080/accounts

<br>
<br>


# Как безопасно хранить пароли Hash password в Go с помощью Bcrypt (17 часть: 2.7)

util/password.go   
api/user.go   
api/validator.go   

github.com/go-playground/validator

    alphanum	Alphanumeric
    email	    E-mail String
<br>
<br>


# Модульные тесты с помощью gomock (18 часть: 2.8)

# Почему PASETO лучше, чем JWT, для аутентификации на основе токенов (19 часть: 2.9)

### Token-based Authentication

|           |                                                                               |  |        |
|:-:        |:-                                                                             |:-|:-:     |
| Client    | 1. POST /users/login <br> -----------------------> <br> {username, password}  |  | Server |

|           |                                                                               |                   |           |
|:-:        |-:                                                                             |:-                 |:-:        |
| Client    | 200 OK <br> <----------------------- <br> {access_token: JWT, PASETO, ...}    | <-- Sign token    | Server    |

|           |                                                                                           |  |        |
|:-:        |:-                                                                                         |:-|:-:     |
| Client    | 2. GET /accounts <br> -----------------------> <br> Authorization: Bearer <access_token>  |  | Server |

|           |                                                                       |                   |           |
|:-:        |-:                                                                     |:-                 |:-:        |
| Client    | 200 OK <br> <----------------------- <br> [account1, account2, ...]   | <-- Verify token  | Server    |


### АЛГОРИТМЫ ПОДПИСИ JWT

```json
    header:
    {
        "typ": "JWT",
        "alg": "HS256"
    }
    payload:
    {
        "id": "1337",
        "username": "bizone",
        "iat": 1594209600,
        "role": "user"
    }
    signature:
    ZvkYYnyM929FM4NW9_hSis7_x3_9rymsDAx9yuOcc1I
```

#### Алгоритм симметричной цифровой подписи
* Для подписи и проверки используется один и тот же секретный ключ, токен
* Для локального использования: внутренние службы, где можно совместно использовать секретный ключ
* HS256, HS384, HS512  
    - HS256 = HMAC + SHA256  
    - HMAC: Hash-based Message Authentication Code - Код аутентификации сообщения на основе хэша  
    - SHA: Secure Hash Algorithm - Алгоритм безопасного хэширования  
    - 256/384/512: количество выходных битов   

#### Алгоритм асимметричной цифровой подписи
* Закрытый ключ используется для подписи токена
* Открытый ключ используется для проверки токена
* Для публичного использования: внутренняя служба подписывает токен, но внешняя служба должна его подтвердить
* RS256, RS384, RS512 || PS256, PS384, PS512 || ES256, ES384, ES512  
    - RS256 = RSA PKCSv1.5 + SHA256 [PKCS: Public-Key Cryptography Standards - Стандарты криптографии с открытым ключом]  
    - PS256 = RSA PSS + SHA256 [PSS: Probabilistic Signature Scheme - Вероятностная схема подписи]  
    - ES256 = ECDSA + SHA256 [ECDSA: Elliptic Curve Digital Signature Algorithm - Алгоритм цифровой подписи с эллиптической кривой]   

### В чем проблема JWT?

#### Слабые алгоритмы
* Дают разработчикам слишком много алгоритмов на выбор
* Известно, что некоторые алгоритмы уязвимы:
* RSA PKCSv1.5: атака на oracle с дополнением
* ECDSA: атака с недопустимой кривой

#### Тривиальная подделка
* Установите для заголовка "alg" значение "none"
* Установите для заголовка "alg" значение "HS256", в то время как сервер обычно проверяет токен с помощью открытого ключа RSA


## Platform-Agnostic SEcurity TOkens [PASETO] Независимые от платформы токены безопасности

#### Более надежные алгоритмы
* Разработчикам не нужно выбирать алгоритм 
* Нужно только выбрать версию PASETO 
* Каждая версия имеет 1 набор надежных шифров 
* Принимаются только 2 самые последние версии PASETO

#### Нетривиальная подделка
* Больше никакого заголовка "alg" или алгоритма "none"
* Все аутентифицировано
* Зашифрованная полезная нагрузка для локального использования <симметричный ключ>   

- v1 [совместима с устаревшей системой]
    + локальный: <симметричный ключ>
        - Аутентифицированное шифрование
        - AES256 CTR + HMAC SHA384
    + открытый: <асимметричный ключ>
        - Цифровая подпись
        - RSA PSS + SHA384

* v2 [рекомендуется]
    + локальный: <симметричный ключ>
        - Аутентифицированное шифрование
        - XChaCha20-Poly1305
    + открытый: <асимметричный ключ>
        - Цифровая подпись
        - Ed25519 [EdDSA + Curve25519]

```javascript
• Version: v2
• Purpose: public [asymmetric-key digital signature]
• Payload:
    • Body:
        • Encoded: [base64]
        eyJeHAiO¡IyMDM5LTAxLTAxVDAwOjAwOjAwKzAwOjAwIiwiZGFOYSI
        6InRoaXMgaXMgYSBzaWduZWQgbWVzc2FnZSJ91g
        • Decoded:
        {
        "data": "this is a signed message" ,
        "exp": "2039-01-01T00:00:00+00:00"
        }
    • Signature: [hex-encoded]
    d600bbfa3096b0dde6bf8b89699c59a746ed2c981cc95c0bfacbc90fb7
    f8207c86b5e29edc74cb8c761318723532d0aa27e1120cb36813ba2d90
    8cda985b2408
```
<br>
<br>


# Создать и верифицировать токен JWT & PASETO (20 часть: 2.10)

token/maker.go   
token/payload.go   
token/jwt_maker.go   
token/jwt_maker_test.go

```shell
    $ go get github.com/google/uuid
    $ go get github.com/golang-jwt/jwt/v5
```







<br>
<br>
<br>

# PS

### Собрать все зависимости из go.mod

    $ go mod tidy

