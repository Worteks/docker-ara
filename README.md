# SweetARA

Sweet Ansible Runtime Analysis image.

Build with:
```
$ make build
```

Start Demo or Cluster in OpenShift:

```
$ make ocdemo
$ make ocprod
```

Cleanup OpenShift assets:

```
$ make ocpurge
```

Environment variables and volumes
----------------------------------

The image recognizes the following environment variables that you can set during
initialization by passing `-e VAR=VALUE` to the Docker `run` command.

|    Variable name      |    Description                | Default       |
| :-------------------- | ----------------------------- | ------------- |
|  `ARA_SECRET_KEY`     | ARA Django Secret Key         | static        |
|  `LISTEN_PORT`        | ARA Bind Port                 | `8080`        |
|  `DB_TYPE`            | Database Type                 | `postgres`    |
|  `MYSQL_DB`           | MySQL Database Name           | `ara`         |
|  `MYSQL_HOST`         | MySQL Database Host           | `127.0.0.1`   |
|  `MYSQL_PASSWORD`     | MySQL Database Password       | `secret`      |
|  `MYSQL_PORT`         | MySQL Databases Port          | `3306`        |
|  `MYSQL_USER`         | MySQL Database Username       | `ara`         |
|  `POSTGRES_DB`        | PostgreSQL Database Name      | `ara`         |
|  `POSTGRES_HOST`      | PostgreSQL Database Host      | `127.0.0.1`   |
|  `POSTGRES_PASSWORD`  | PostgreSQL Database Password  | `secret`      |
|  `POSTGRES_PORT`      | PostgreSQL Database Port      | `5432`        |
|  `POSTGRES_USER`      | PostgreSQL Database Username  | `ara`         |
