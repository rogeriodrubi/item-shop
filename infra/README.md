# Deploy

## Preliminares

Append to /etc/hosts file:

```
# BEGIN projetosd
127.0.0.1   projetosd.local
127.0.0.1   www.projetosd.local
127.0.0.1   api.projetosd.local
127.0.0.1   adm.projetosd.local
127.0.0.1   status.projetosd.local
# END projetosd
```

---

##  Connect to production machine

At the first execution, the script will ask you for creating
a symlink to the SSH key (PEM format).

```
infra/sh prod                # starts interactive shell
infra/sh prod -- echo Hello  # prints Hello and exit
infra/sh prod -- uptime      # runs uptime and exit
```

---

## Update secrets (passwords, keys)

First, update secrets files contents!

1. Update local containers:

```
infra/pg password
```

2. Update remote containers:

```
infra/deploy secrets prod /path/to/secrets
```

---

## Dump and restore

### Whole database

```
infra/pg dump all
infra/pg restore all @last
```

### Measurement data only (optional)

```
infra/pg scale-deps down
infra/pg restore measures /path/to/backup.csv[.gz|.xz]
infra/pg scale-deps up
```

### Download most recent backup from prod

The first command reports the local path of the downloaded file.

```
infra/pg download
infra/pg restore all /path/to/backup.sql[.gz|.xz]
```

---

## Deploy

### Cloning at the first time:

```
mkdir -p /path/to/src
cd /path/to/src
GIT_URL=https://git-codecommit.us-east-1.amazonaws.com/v1/repos/projetosd-web
git clone "$GIT_URL"
```

### Deploy (optionally recreating) database:

```
cd /path/to/src
#infra/deploy drop   # if you want to drop database
infra/deploy up {dev} {branch}  # dev or prod
```

---

## Internal / Deprecated

### deploy

```
@prod $ infra/deploy up prod master
```

### dump/restore

```
@prod $ infra/pg dump all
      $ scp prod:/path/to/dump*prod*.sql.xz to ./data/backups/dump*dev*.sql.xz
@dev  $ infra/pg restore all @last
```

### update password

Update secrets files, then:

```
@dev  $ scp ./infra/secrets/prod/* prod:/root/secrets/
@prod $ infra/pg password
```
