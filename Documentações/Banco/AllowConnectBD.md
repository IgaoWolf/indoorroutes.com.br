## 1. Acessar o banco de qualquer origem

```bash
sudo vim /etc/postgresql/15/main/postgresql.conf

```
Descomente essa linha e insira o * para acessar de qualquer origem o banco.

listen_addresses = '*'

# 1.1 Acesse também o pg_hba para liberar para 0.0.0.0/0 

```bash
sudo vim /etc/postgresql/15/main/pg_hba.conf
```

host    all             indoor        0.0.0.0/0            md5

```bash
sudo systemctl restart postgresql
```