#!/usr/bin/bash

docker compose up -d --scale pgadmin=0 --scale web=0 --scale projetosd_db=1

docker exec -it postgres psql -U postgres -c  "DROP DATABASE projetosd"
docker exec -it postgres psql -U postgres -c  "DROP USER projetosd"
docker exec -it postgres psql -U postgres -c  "CREATE DATABASE projetosd"
docker exec -it postgres psql -U postgres -c  "CREATE USER projetosd WITH PASSWORD 'qJfxv(PV7uy]'" # verificar passord em /infra/secrets/pgapp_pass
docker exec -it postgres psql -U postgres -c  "GRANT ALL PRIVILEGES ON DATABASE projetosd to projetosd"