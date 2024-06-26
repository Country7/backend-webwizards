# __I. Работа с базой данных__

## 1. Cхема БД и SQL-код

[diagram.io](https://dbdiagram.io/home)

    ->  Go to App
        Export PostgreSQL

doc/db.dbml
doc/schema.sql

<br>
<br>

## 2. Docker  Postgres

    $ docker ps    // список всех запущенных контейнеров
    $ docker images   // список всех имеющихся образов

__Удалить установленный Postgres__

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

__Скачать образ__

[hub.docker.com](https://hub.docker.com/)   
поиск postgres   
<https://hub.docker.com/_/postgres>

    docker pull <image>:<tag>
    $ docker pull postgres:16-alpine
<br>

__Запуск контейнера из образа__

    docker run --name <container_name> -e <environment_variable> -d <image>:<tag>

___Environment Variables:___

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

    $ docker run --name some-postgres -e POSTGRES_PASSWORD_FILE=/run/secrets/postgres-passwd -d postgres

Port mapping    

    docker run --name ‹container_name> -e ‹environment_variable> -p ‹host_ports:container_ports> -d ‹image>:<tag>

    $ docker run --name postgres16 -p 5432:5432 -e POSTGRES_USER=root -e POSTGRES_PASSWORD=secret -d postgres:16-alpine
    $ docker ps

    $ docker stop postgres16
    $ docker ps -a   // все контейнеры вне зависимости запущены или нет
    $ docker start postgres16   // снова запустить имеющийся контейнер
    $ docker rm postgres16   // удалить полностью имеющийся контейнер
<br>

__Запуск команды в контейнере__

    docker exec -it ‹container _name_or_id> ‹command> [args]

    $ docker exec -it postgres16 psql -U root
        select now();
        \q    - выход

    $ docker exec -it postgres16 /bin/sh     // запускаем оболочку в контейнере
<br>

__Просмотр логов контейнера__

    docker logs <container_name_or_id>
    $ docker logs postgres16
<br>
<br>

---------

__TablePlus__

Для kubuntu лучше либо pgAdmin4 либо DBeaver

Для mac - [tableplus.com](https://tableplus.com/)  

    basename: root
    user: root
    password: secret
    url: localhost:5432

<br>
<br>

---------   
## 3. Миграции

[github.com/golang-migrate/migrate](https://github.com/golang-migrate/migrate)

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

__Миграция в проекте__

    $ set -e
    $ source ./app.env
    // если нет базы  $ docker exec postgres16 createdb --username=root --owner=root main_db
    $ migrate -path ./db/migration -database "$DB_SOURCE" -verbose up

<br>

__Cоздаем Makefile__

    run-postgres: ## Start postgresql database docker image.
        docker run --name postgres16 -p 5432:5432 -e POSTGRES_USER=root -e POSTGRES_PASSWORD=secret -d postgres:16-alpine

    start-postgres16: ## Start available postgresql database docker container.
        docker start postgres16

    stop-postgres: ## Stop postgresql database docker image.
        docker stop postgres16
<br>


---------
## 4. CRUD

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

[sqlc.dev](https://sqlc.dev/)   
[github.com/sqlc-dev/sqlc](https://github.com/sqlc-dev/sqlc)

    $ brew install sqlc
    $ sqlc version
    $ sqlc help
    $ sqlc init

sqlc.yaml   
[docs.sqlc.dev/en/latest/tutorials/getting-started-postgresql.html#setting-up](https://docs.sqlc.dev/en/latest/tutorials/getting-started-postgresql.html#setting-up)


    $ sqlc generate

db/query/account.sql   
[docs.sqlc.dev/en/latest/tutorials/getting-started-postgresql.html#schema-and-queries](https://docs.sqlc.dev/en/latest/tutorials/getting-started-postgresql.html#schema-and-queries)
<br>
<br>


## 5. Тесты

    _ "github.com/lib/pq"  // без драйвера работать не будет

    $ go test -v   // все тесты

    $ go test -timeout 30s ./db/sqlc -run ^TestMain$             
        ok  	github.com/Country7/backend-webwizards/db/sqlc	0.433s [no tests to run]

    $ make test   // команда test из файла Makefile
<br>
<br>


## 6. Транзакции

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

## 7. Блокировка транзакции

    BEGIN;
    
    SELECT * FROM accounts WHERE id = 1;

    SELECT * FROM WHERE id = 1 FOR UPDATE;     // блокировка запросов
    UPDATE accounts SET balance = 500 WHERE id = 1;
    COMMIT;
<br>

    $ sqlc generate

__Deadlock detected__

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


## 8. Взаимоблокировки

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


## 9. Уровень изоляции транзакций


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


## 10. Действие на Github Go + Postgres

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

## ---------------------------------------------

## ---------------------------------------------

# __II. Создание RESTful HTTP JSON API__

## 11. Реализация RESTful HTTP API в Go с помощью Gin (2.1)

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

Самый популярный - __Gin__ - [github.com/gin-gonic/gin](https://github.com/gin-gonic/gin)

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


## 12. Конфигурация из файла и переменных окружения - Viper (2.2)

```shell
    $ go get github.com/spf13/viper
```

app.env   
util/config.go   
main.go   

```go
    config, err := util.LoadConfig(".")
```

```shell
    $ SERVER_ADDRESS=0.0.0.0:8081 make server
```

db/sqlc/main_test.go
<br>
<br>


## 13. Mock DB (макет) - тестирование HTTP API и 100% охвата (2.3)

__Подготовка:__

```shell
    $ go get go.uber.org/mock
    $ go install go.uber.org/mock/mockgen@latest
    $ ls -l ~/go/bin
        // проверить ~/go/bin/mockgen
    $ which mockgen
        ~/go/bin/mockgen
    Если нет, то:
    $ vi ~/.zshrc           // для mac
    $ vi ~/.bash_profile    // или для другого терминала
        i
        export PATH=$PATH:~/go/bin
        esc
        :wq
    $ source ~/.zshrc
    $ which mockgen
        ~/go/bin/mockgen
    $ mockgen -help
```

```go
    // БЫЛО:

    // api/server.go
    func NewServer(config util.Config, store *db.Store) (*Server, error)
        // для подключения к реальной базе данных используется store *db.Store
        // для тестов mock (с макетом) его надо заменить интерфейсом
    
    // db/sqlc/store.go
    type Store struct {
        db *sql.DB
        *Queries
    }
    func NewStore(db *sqL.DB) *Store {
        return &Store {
            db: db,
            Queries: New(db),
        }
    }
    func (s *Store) execTx(ctx context.Context, fn func(queries *Queries) error) error
    func (s *Store) TransferTx(ctx context.Context, arg TransferTxParams) (TransferTxResult, error)

    // sqlc.yaml
    emit_interface: false

    // ПЕРЕПИСЫВАЕМ:

    // sqlc.yaml
    emit_interface: true    // было false
    $ make sqlc             // обновить в терминале
        // создался новый файл с интерфейсом db/sqlc/querier.go  

    // db/sqlc/store.go
    type Store interface {
        Querier             // интерфейс из нового файла  db/sqlc/querier.go
        TransferTx(ctx context.Context, arg TransferTxParams) (TransferTxResult, error)
    }
    type SQLStore struct {
        *Queries
        db *sql.DB
    }
    func NewStore(db *sql.DB) Store {
        return &SQLStore{db: db, Queries: New(db)}
    }
    func (s *SQLStore) execTx(ctx context.Context, fn func(queries *Queries) error) error
    func (s *SQLStore) TransferTx(ctx context.Context, arg TransferTxParams) (TransferTxResult, error)

    // api/server.go
    type Server struct {
        config     util.Config
        store      db.Store     // убрали * у db.Store, это теперь не указатель, а интерфейс
        tokenMaker token.Maker
        router     *gin.Engine
    }
    func NewServer(config util.Config, store db.Store) (*Server, error)  // убрали * у db.Store, это теперь не указатель, а интерфейс
```

__Создаем пакет db/moc:__

создаем папку db/moc

```shell
    $ mockgen -package mockdb -destination db/mock/store.go github.com/Country7/backend-webwizards/db/sqlc Store
        // создался файл db/mock/store.go

    // добавляем команду в файл Makefile
    mock: ## Generate a store mock.
	    mockgen -package mockdb -destination db/mock/store.go github.com/Country7/backend-webwizards/db/sqlc Store
```

__Приступаем к написанию тестов:__

api/account_test.go   
<br>
<br>


## 14. Пользовательский валидатор параметров - __transfer__ (2.4)

api/transfer.go   

api/server.go   
```go
    authRoute.POST("/transfers", server.createTransfer)
```

__Postman:__

    POST http://localhost:8080/transfers
    Body raw JSON
    {
        "from_account_id": 1,
        "to_account_id": 2,
        "amount": 10,
        "currency": "USD"
    }

api/validator.go   
```go
    import ( "github.com/go-playground/validator/v10" )
    var validCurrency validator.Func = func(fieldLevel validator.FieldLevel) bool {
        if currency, ok := fieldLevel.Field().Interface().(string); ok {
            return util.IsSupportedCurrency(currency)
        }
        return false
    }
```

util/currency.go   
```go
    const (
        USD = "USD"
        EUR = "EUR"
        CAD = "CAD" )
    // IsSupportedCurrency returns true if the currency is supported.
    func IsSupportedCurrency(currency string) bool {
        switch currency {
        case CAD, EUR, USD:
            return true
        default:
            return false
        }
    }
```

__Регистрация вадидатора на сервере__   
api/server.go
```go
    import ("github.com/gin-gonic/gin/binding")
	if v, ok := binding.Validator.Engine().(*validator.Validate); ok {
		v.RegisterValidation("currency", validCurrency)
	}
```

api/account.go
```go
    type createAccountRequest struct {
        ...
        Currency string `json:"currency" binding:"required,currency"`
    }
```

api/transfer.go
```go
    type transferRequest struct {
        ...
        Currency string `json:"currency" binding:"required,currency"`
    }
```

__Postman:__
```json
    POST http://localhost:8080/transfers
    Body raw JSON
    {
        "from_account_id": 1,
        "to_account_id": 2,
        "amount": 10,
        "currency": "EUR"
    }
```

util/random.go
```go
    // RandomCurrency generates a random currency code.
    func RandomCurrency() string {
        currencies := []string{EUR, USD, CAD}
        n := len(currencies)
        return currencies[rand.Intn(n)]
    }
```
<br>
<br>


## 15. Добавление таблицы users с ограничениями уникальности и внешнего ключа (2.5)

[diagram.io](https://dbdiagram.io/home)

->  Go to App   

    Table users as U {
        username varchar [pk]
        role varchar [not null, default: 'depositor']
        hashed_password varchar [not null]
        full_name varchar [not null]
        email varchar [unique, not null]
        is_email_verified bool [not null, default: false]
        password_changed_at timestamptz [not null, default: '0001-01-01']
        created_at timestamptz [not null, default: `now()`]
    }

    Table accounts as A {
        ...
        owner varchar [ref: > U.username, not null]
        ...
        Indexes {
            owner
            (owner, currency) [unique]  // в одной валюте только один счет у пользователя
                                        // в разной валюте может быть несколько счетов
        }
    }

Export PostgreSQL

```shell
    $ migrate -help
    $ migrate create -ext sql -dir db/migration -seq add_users
```

В созданный файл db/migration/000002_add_users.up.sql копируем изменения из doc/schema.sql (таблицу users и ключи)

```shell
    $ make migrateup
        // ошибка, так как данные accounts есть, а их в новой таблице users - нет
    $ make migratedown
        // ошибка, надо вручную менять значение в БД / таблице schema_migrations с TRUE на FALSE
    $ make migratedown
        // удалились все таблицы
    $ make migrateup
```

В файле db/migration/000002_add_users.down.sql грохаем ключи, грохаем таблицу users

<br>
<br>


## 16. Обработка ошибок базы данных (2.6)

db/query/user.sql
```shell
    $ make sqlc
```

Появился db/sqlc/user.sql.go   

Изменились  
db/sqlc/models.go   
db/sqlc/querier.go   

Пишем db/sqlc/user_test.go

Правим db/sqlc/account_test.go
```go
    func createRandomAccount(t *testing.T) Account {
        user := createRandomUser(t)
        arg := CreateAccountParams{
            Owner:    user.Username,
            ...
        }
```

```shell
    $ make mock
    $ make test
```

Допиливаем api/account.go
```go
	account, err := server.store.CreateAccount(ctx, arg)
	if err != nil {
		var pqErr *pq.Error                         // добавляем от сюда
		if errors.As(err, &pqErr) {
			switch pqErr.Code.Name() {
			case "foreign_key_violation", "unique_violation":
                    // ошибки на сервере при создании аккаунта без юзера,
                    // и создании аккаунта с одинаковой валютой счета
				ctx.JSON(http.StatusForbidden, errorResponse(err))
				return
			}
		}                                           // до сюда
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}
```

__Postman:__
```json
    POST http://localhost:8080/users
    Body raw JSON
    {
        "username": "QuangBang",
        "password": "secret",
        "full_name": "Quang Bang",
        "email": "quang@mail.com"
    }
    POST http://localhost:8080/users/login
    Body raw JSON
    {
        "username": "QuangBang",
        "password": "secret"
    }
    POST http://localhost:8080/accounts
    Authorization  Bearer Token  ...
    Body raw JSON
    {
        "owner": "QuangBang",
        "currency": "USD"
    }
    GET http://localhost:8080/accounts?page_id=1&page_size=5
    key   page_id 1   page_size 5
    Body raw JSON
    {
        "owner":  "QuangBang",
        "limit":  5,
        "offset": 0
    }
```
<br>
<br>

## ---------------------------------------------

## 17. Безопасное хранение паролей Hash password в Go с помощью Bcrypt (2.7)

util/password.go   
api/user.go   
api/validator.go   

github.com/go-playground/validator

    alphanum	Alphanumeric
    email	    E-mail String
<br>
<br>


## 18. Модульные тесты с помощью gomock (2.8)
<br>

## 19. Почему PASETO лучше, чем JWT, для аутентификации на основе токенов (2.9)

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

__Алгоритм симметричной цифровой подписи__
* Для подписи и проверки используется один и тот же секретный ключ, токен
* Для локального использования: внутренние службы, где можно совместно использовать секретный ключ
* HS256, HS384, HS512  
    - HS256 = HMAC + SHA256  
    - HMAC: Hash-based Message Authentication Code - Код аутентификации сообщения на основе хэша  
    - SHA: Secure Hash Algorithm - Алгоритм безопасного хэширования  
    - 256/384/512: количество выходных битов   

__Алгоритм асимметричной цифровой подписи__
* Закрытый ключ используется для подписи токена
* Открытый ключ используется для проверки токена
* Для публичного использования: внутренняя служба подписывает токен, но внешняя служба должна его подтвердить
* RS256, RS384, RS512 || PS256, PS384, PS512 || ES256, ES384, ES512  
    - RS256 = RSA PKCSv1.5 + SHA256 [PKCS: Public-Key Cryptography Standards - Стандарты криптографии с открытым ключом]  
    - PS256 = RSA PSS + SHA256 [PSS: Probabilistic Signature Scheme - Вероятностная схема подписи]  
    - ES256 = ECDSA + SHA256 [ECDSA: Elliptic Curve Digital Signature Algorithm - Алгоритм цифровой подписи с эллиптической кривой]   

### В чем проблема JWT?

__Слабые алгоритмы__
* Дают разработчикам слишком много алгоритмов на выбор
* Известно, что некоторые алгоритмы уязвимы:
* RSA PKCSv1.5: атака на oracle с дополнением
* ECDSA: атака с недопустимой кривой

__Тривиальная подделка__
* Установите для заголовка "alg" значение "none"
* Установите для заголовка "alg" значение "HS256", в то время как сервер обычно проверяет токен с помощью открытого ключа RSA


### Platform-Agnostic SEcurity TOkens [PASETO] Независимые от платформы токены безопасности

__Более надежные алгоритмы__
* Разработчикам не нужно выбирать алгоритм 
* Нужно только выбрать версию PASETO 
* Каждая версия имеет 1 набор надежных шифров 
* Принимаются только 2 самые последние версии PASETO

__Нетривиальная подделка__
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


## 20. Создать и верифицировать токен JWT & PASETO (2.10)

token/maker.go   
token/payload.go   
token/jwt_maker.go   
token/jwt_maker_test.go   

```shell
    $ go get github.com/google/uuid
    $ go get github.com/golang-jwt/jwt/v5
```

token/paseto_maker.go   
token/paseto_maker_test.go   

```shell
    $ go get github.com/o1egl/paseto/v2
```
<br>
<br>


## 21. API для входа в систему через токен PASETO или JWT (2.11)

api/server.go   
app.env   
util/config.go   
api/main_test.go   
api/transfer_test.go   
api/user_test.go   
api/account_test.go   
main.go   

api/user.go   
api/server.go  router   

__утилита Postman:__

```json
    POST http://localhost:8080/users/login
    Body raw JSON
        {
            "username": "qwe",
            "password": "1234567"
        }

    Response 200 OK
        {
            "session_id": "e7a1856e-aaa0-4226-9681-6ff7993dd789",
            "access_token": "v2.local. ...",
            "access_token_expires_at": "2024-03-30T16:05:55.116046+03:00",
            "refresh_token": "v2.local. ...",
            "refresh_token_expires_at": "2024-03-31T15:50:55.116324+03:00",
            "user": {
                "username": "qwe",
                "full_name": "asdfgh",
                "email": "zxc@mail.com",
                "password_changed_at": "0001-01-01T00:00:00Z",
                "created_at": "2024-03-27T17:34:06.837219Z"
            }
        }
```
<br>
<br>



## 22. Middleware авторизации (2.12)

__Что такое промежуточное программное обеспечение?__

```
|        | Send request                            |         |
|        | -------------->        Route            |         |
|        |                  /accounts/create       |         |
|        |                          |              |         |
|        |                          |              |         |
|        |                          V              |         |
|        |  ctx. Abort()       Middlewares         |         |
| CLIENT | <--------------    Logger (ctx),        | SERVER  |
|        | Send response        Auth(ctx)          |         |
|        |                          |              |         |
|        |                          | ctx.Next()   |         |
|        |                          |              |         |
|        |                          V              | Авторизация:
|        | Send response         Handler  <--------- У пользователя
|        | <--------------  createAccount(ctx)     | есть разрешение?
|        |                                         |         |
```
<br>

api/middleware.go   
api/middleware_test.go   

api/server.go   

```go
    router := gin.Default()
    router.POST("/users/login", server.loginUSer)

    authRoute := router.Group("/").Use(authMiddleware(server.tokenMaker))
    authRoute.GET("/accounts", server.listAccount)
```
<br>

__ПРАВИЛА АВТОРИЗАЦИИ__

| | | |
|:-:|:-:|:-:|
| API <br> Create account | -------> | Правило <br> Авторизованный пользователь может создать <br> учетную запись только для себя |
| API <br> Get account    | -------> | Правило <br> Авторизованный пользователь может получить <br> только те учетные записи, которыми он владеет|
| API <br> List accounts  | -------> | Правило <br> Авторизованный пользователь может перечислять <br> только те учетные записи, которые принадлежат ему|
| API <br> Transfer money | -------> | Правило <br> Авторизованный пользователь может отправлять <br> деньги только со своего собственного аккаунта|
<br>

```go
api/account.go func createAccount

    authPayload := ctx.MustGet(authorizationPayloadKey).(*token.Payload)    // добавили
    arg := db.CreateAccountParams{
        Owner:    authPayload.Username,   // было req.Owner
        Balance:  0,
        Currency: req.Currency,
    }

api/account.go func getAccount
    
	authPayload := ctx.MustGet(authorizationPayloadKey).(*token.Payload)    // добавили
	if account.Owner != authPayload.Username {
		err := errors.New("account doesn't belong to the authenticated user")
		ctx.JSON(http.StatusUnauthorized, errorResponse(err))
		return
	}
```

```sql
db/query/account.sql

    -- name: ListAccounts :many
    SELECT * FROM accounts
    WHERE owner = $1            // добавлено условие
    ORDER BY id LIMIT $2
    OFFSET $3;

    make sqlc       // db/sqlc/account.sql.go listAccounts обновился
    make mock
```

```go
db/sqlc/account_test.go  TestListAccounts   

api/account.go  func listAccount

	authPayload := ctx.MustGet(authorizationPayloadKey).(*token.Payload)    // добавили
	arg := db.ListAccountsParams{
		Owner:  authPayload.Username,       // добавили
		Limit:  req.PageSize,
		Offset: (req.PageID - 1) * req.PageSize,
	}

api/transfer.go  

    func (server *Server) validAccount(ctx *gin.Context, accountID int64, currency string) (db.Account, bool)
    // добавили db.Account
    return account, true

    func createTransfer
        fromAccount, valid := server.validAccount(ctx, req.FromAccountID, req.Currency)
        if !valid {
            return
        }
        authPayload := ctx.MustGet(authorizationPayloadKey).(*token.Payload)
        if fromAccount.Owner != authPayload.Username {
            err := errors.New("from account doesn't belong to the authenticated user")
            ctx.JSON(http.StatusUnauthorized, errorResponse(err))
            return
        }
        _, valid = server.validAccount(ctx, req.ToAccountID, req.Currency)
        if !valid {
            return
        }

api/account_test.go
```

<br>
<br>
<br>

## ---------------------------------------------
## ---------------------------------------------

# __III. Развертывание приложения в рабочей среде (Deploying the application to production)__

## 23. Образ Golang Docker с помощью многоступенчатого файла Dockerfile (3.1)

    $ git checkout -b deploying

update go

go.mod   

    go 1.22

.github/workflows/test.yml

    go-version: '1.22'

    $ git status
    $ git add .
    $ git status
    $ git commit -m"update go to 1.22"
    $ git push -u origin deploying

Из терминала переходим по ссылке    
<https://github.com/Country7/backend-webwizards/pull/new/deploying>

    Name -> Add docker
    -> Create pull request

    $ brew upgrade golang-migrate
    $ migrate -version
        v4.17.0
    $ make migrate-up

.github/workflows/test.yml

    curl -L https://github.com/golang-migrate/migrate/releases/download/v4.17.0/migrate.linux-amd64.tar.gz | tar xvz

    $ git add .
    $ git status
    $ git commit -m"upgrade golang-migrate to v4.17.0"
    $ git push

__Если тесты на github пройдены, то приложение готово к 1 запуску__

Создаем __Dockerfile__:

<https://hub.docker.com/_/golang>

    FROM golang:1.22.2-alpine3.19
    WORKDIR /app
    COPY . .
    RUN go build -o main main.go
    EXPOSE 8080
    CMD [ "/app/main" ]

    $ docker build --help
    $ docker build -t webwizards:latest .
    $ docker images
        webwizards latest 601MB

Размер образа получился 601Мб, чтобы уменьшить размер образа нужно применить многоступенчатую сборку. Нам в образе нужен только исполняемый файл.   
__Dockerfile__:

    # Build stage
        FROM golang:1.22.2-alpine3.19 AS builder
        WORKDIR /app
        COPY . .
        RUN go build -o main main.go
    # Run stage
        FROM alpine:3.19
        WORKDIR /app
        COPY --from=builder /app/main .
        EXPOSE 8080
        CMD [ "/app/main" ]

    $ docker build -t webwizards:latest .
    $ docker images
        webwizards latest 21MB

    $ docker rmi 61504815c89a   // удалить старый образ IMAGE ID = 61504815c89a

<br>
<br>

## 24. Подключить контейнеры в одной сети docker (3.2)

    $ docker run --name webwizards -p 8080:8080 webwizards:latest
        cannot load config:Config File "app" Not Found in "[/app]"
    $ docker ps -a
    $ docker rm webwizards
    $ docker images
    $ docker rmi a4809227e909

__Dockerfile__:

    COPY app.env .

    $ docker build -t webwizards:latest .
    $ docker images
    $ docker run --name webwizards -p 8080:8080 webwizards:latest
        Running in "debug" mode. Switch to "release" mode in production.
        - using env:	export GIN_MODE=release
    $ docker rm webwizards
    $ docker run --name webwizards -p 8080:8080 -e GIN_MODE=release webwizards:latest
    $ docker ps

__Postman__: "error": "dial tcp 127.0.0.1:5432: connect: connection refused"   
__Terminal__: [GIN] | 500 | 1.437083ms | 192.168.65.1 | POST "/users/login"    
__app.env__: DB_SOURCE=postgresql://root:secret@localhost:5432/main_db?sslmode=disable

    $ docker container inspect postgres16
        "NetworkSettings": "Networks": "bridge": "IPAddress": "172.17.0.2"
    $ docker container inspect webwizards
        "NetworkSettings": "Networks": "bridge": "IPAddress": "172.17.0.3"

    $ docker stop webwizards
    $ docker rm webwizards
    $ docker run --name webwizards -p 8080:8080 -e GIN_MODE=release -e "DB_SOURCE=postgresql://root:secret@172.17.0.2:5432/main_db?sslmode=disable" webwizards:latest

__Postman__: Status 200 OK

### Способ получше (подключиться к контейнеру postgres16 по имени, а не по ip адресу)

    $ docker rm webwizards
    $ docker network ls
        9a00594f4037 bridge bridge local
    $ docker network inspect bridge
        "Containers": "Name": "postgres16"
    // контейнеры в мостовой сети bridge не могут видеть друг друга по имени, как в других сетях
    // поэтому нужно создать свою сеть и подключить к ней контейнер
    $ docker network --help
    $ docker network create ww-network
    $ docker network connect --help 
    $ docker network connect ww-network postgres16
    $ docker container inspect postgres16
        "Networks":
            "bridge": "IPAddress": "172.17.0.2"
            "ww-network": "IPAddress": "172.18.0.2"
    $ docker run --name webwizards --network ww-network -p 8080:8080 -e GIN_MODE=release -e "DB_SOURCE=postgresql://root:secret@postgres16:5432/main_db?sslmode=disable" webwizards:latest

__Postman__: Status 200 OK
__Terminal__: [GIN] | 200 | 101.980875ms | 192.168.65.1 | POST "/users/login"

    $ docker network inspect ww-network
        "Containers":
            "Name": "postgres16"
            "Name": "webwizards",

Makefile

    run-postgres: ## Run postgresql database docker image.
	    docker run --name postgres16 --network ww-network -p 5432:5432 -e POSTGRES_USER=root -e POSTGRES_PASSWORD=secret -d postgres:16-alpine








<br>
<br>
<br>

# PS

### Собрать все зависимости из go.mod

    $ go mod tidy

