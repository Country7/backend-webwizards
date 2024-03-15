DB_URL=postgresql://root:secret@localhost:5432/main_db?sslmode=disable

help: ## Show this help.
	@sed -ne '/@sed/!s/## //p' $(MAKEFILE_LIST) | column -tl 2

pull-images: ## Pull the needed docker images.
	docker pull postgres:16-alpine

create-network: ## Create the backend-webwizards-network.
	docker network create backend-webwizards-network

create-db: ## Create the database.
	docker exec -it postgres16 createdb --username=root --owner=root main_db

drop-db: ## Drop the database.
	docker exec -it postgres16  dropdb main_db

migrate-up: ## Apply all up migrations.
	migrate -path db/migration -database "$(DB_URL)" -verbose up

migrate-up-1: ## Apply the last up migration.
	migrate -path db/migration -database "$(DB_URL)" -verbose up 1

migrate-down: ## Apply all down migrations.
	migrate -path db/migration -database "$(DB_URL)" -verbose down

migrate-down-1: ## Apply the last down migration.
	migrate -path db/migration -database "$(DB_URL)" -verbose down 1

# https://hub.docker.com/_/postgres
run-postgres: ## Run postgresql database docker image.
	docker run --name postgres16 -p 5432:5432 -e POSTGRES_USER=root -e POSTGRES_PASSWORD=secret -d postgres:16-alpine

start-postgres16: ## Start available postgresql database docker container.
	docker start postgres16

stop-postgres: ## Stop postgresql database docker image.
	docker stop postgres16

run-postgres-cli:    ## Run psql on the postgres15 docker container.
	docker exec -it -u root postgres16 psql

db-docs: ## Generate the database documentation.
	dbdocs build doc/db.dbml

db-schema: ## Generate the database schema.
	dbml2sql --postgres -o doc/schema.sql doc/db.dbml

sqlc: ## sqlc generate.
	sqlc generate

docker-system-clean: ## Docker system clean.
	docker system prune -f

test: ## Test go files and report coverage.
	go test -v -cover ./...

server: ## Run the application server.
	go run main.go

mock: ## Generate a store mock.
	mockgen -package mockdb -destination db/mock/store.go github.com/Country7/backend-webwizards/db/sqlc Store

build-docker-image: ## Build the Docker image.
	docker build -t backend-webwizards:latest .

.PHONY: run-postgres start-postgres16 stop-postgres create-db drop-db migrate-up migrate-down \
 run-postgres-cli docker-system-clean sqlc test mock migrate-up-1 migrate-down-1 db-docs db-schema
