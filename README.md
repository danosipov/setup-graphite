setup-graphite
==============

```
SYNOPSIS :
    ubuntu.bash --help --login <LOGIN> --password <PASSWORD> --email <EMAIL>

DESCRIPTION :
    --help        Help page
    --login       Graphite Browser admin-user's login (require)
    --password    Graphite Browser admin-user's password (require)
    --email       Graphite Browser admin-user's email (require)

EXAMPLES :
    ./ubuntu.bash --help
    ./ubuntu.bash --login 'root' --password 'root' --email 'root@localhost.com'

USEFUL COMMANDS :
    To stop/start/restart apache2      : service apache2 <stop|start|restart>
    To stop/start/restart memcached    : service memcached <stop|start|restart>
    To stop/start/restart carbon-cache : <stop|start|restart> carbon-cache
    To stop/start/restart all services : /github.com/gdbtek/setup-graphite/bin/<stop|start|restart>
```
