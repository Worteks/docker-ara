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

|    Variable name      |    Description                  | Default       |
| :-------------------- | ------------------------------- | ------------- |
|  `ARA_FQDN`           | ARA Fully Qualified Domain Name | `localhost`   |
|  `ARA_HOSTNAME`       | ARA Hostname                    | `$(hostname)` |
|  `ARA_SECRET_KEY`     | ARA Django Secret Key           | static        |
|  `LISTEN_PORT`        | ARA Bind Port                   | `8080`        |
|  `DB_TYPE`            | Database Type                   | `postgres`    |
|  `MYSQL_DB`           | MySQL Database Name             | `ara`         |
|  `MYSQL_HOST`         | MySQL Database Host             | `127.0.0.1`   |
|  `MYSQL_PASSWORD`     | MySQL Database Password         | `secret`      |
|  `MYSQL_PORT`         | MySQL Databases Port            | `3306`        |
|  `MYSQL_USER`         | MySQL Database Username         | `ara`         |
|  `POSTGRES_DB`        | PostgreSQL Database Name        | `ara`         |
|  `POSTGRES_HOST`      | PostgreSQL Database Host        | `127.0.0.1`   |
|  `POSTGRES_PASSWORD`  | PostgreSQL Database Password    | `secret`      |
|  `POSTGRES_PORT`      | PostgreSQL Database Port        | `5432`        |
|  `POSTGRES_USER`      | PostgreSQL Database Username    | `ara`         |

Pruning older records
----------------------

Currently, ARA just archives all runs, with no internal purge process.
The following should assist in getting rid of older runs:

```
$ PRUNE_PENDING_STARTED_BEFORE=2019-11-15
$ PRUNE_COMPLETED_STARTED_BEFORE=2019-10-30
$ ( echo "SELECT playbook_id FROM plays"
    echo "  WHERE (status = 'running' AND ended IS NULL"
    echo "         AND created < '$PRUNE_PENDING_STARTED_BEFORE'::date)"
    echo "     OR (status = 'completed'"
    echo "         AND ended < '$PRUNE_COMPLETED_STARTED_BEFORE'::date);"
  ) | psql -t ara 2>/dev/null | sed 's| ||g' | while read playbook_id
    do
	test "$playbook_id" -ge 0 2>/dev/null || continue
	echo "DELETE FROM results WHERE playbook_id = $playbook_id;"
	echo "DELETE FROM hosts WHERE playbook_id = $playbook_id;"
	echo "DELETE FROM tasks WHERE playbook_id = $playbook_id;"
	echo "DELETE FROM plays WHERE playbook_id = $playbook_id;"
	echo "DELETE FROM files WHERE playbook_id = $playbook_id;"
	echo "DELETE FROM playbooks_labels WHERE playbook_id = $playbook_id;"
	echo "DELETE FROM playbooks WHERE id = $playbook_id;"
    done | psql -t ara
```
