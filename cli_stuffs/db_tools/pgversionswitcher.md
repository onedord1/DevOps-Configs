Here’s a polished `README.md` that captures your setup, including installing multiple PostgreSQL CLI versions and using the `SET psql=<ver>` function in Zsh:

---

### PostgreSQL CLI Version Manager (Zsh)

Easily switch your PostgreSQL command-line tools (`psql`, `pg_dump`, `pg_restore`) between versions **14**, **15**, **16**, and **17** using a `SET psql=<version>` command.

---

### ✅ 1. Install Multiple Client Versions

On Ubuntu/Debian, use the official PostgreSQL repository to install multiple client versions side by side:

```bash
# Add PostgreSQL apt repository
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt \
  $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget -qO - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt update

# Install specific client versions
sudo apt install postgresql-client-14 postgresql-client-15 \
                 postgresql-client-16 postgresql-client-17
```

These packages provide binaries under:

```
/usr/lib/postgresql/<ver>/bin/
```

---

### 🔧 2. Register Versions with `update-alternatives`

Run the following to register each version, linking `psql`, `pg_dump`, and `pg_restore`:

```bash
for ver in 14 15 16 17; do
  priority=$((ver * 10))
  sudo update-alternatives \
    --install /usr/bin/psql     psql     /usr/lib/postgresql/$ver/bin/psql     $priority \
    --slave   /usr/bin/pg_dump     pg_dump     /usr/lib/postgresql/$ver/bin/pg_dump \
    --slave   /usr/bin/pg_restore  pg_restore  /usr/lib/postgresql/$ver/bin/pg_restore
done
```

* Higher priority means that version becomes the default.
* Version 17 will be selected by default due to highest priority.

---

### ⚙️ 3. Add `SET psql=<ver>` to `~/.zshrc`

Use this function to switch all tools with one command:

```zsh
function SET() {
  [[ $# -ne 1 || "$1" != psql=* ]] && {
    echo "Usage: SET psql=<14|15|16|17>"
    return 1
  }

  local ver=${1#psql=}
  local bin="/usr/lib/postgresql/${ver}/bin/psql"

  if [[ ! -x $bin ]]; then
    echo "❌ PostgreSQL CLI version $ver not found at $bin"
    return 1
  fi

  sudo update-alternatives --set psql "$bin" \
    && echo "✅ Switched PostgreSQL CLI tools to version $ver"
}
```

Reload your shell:

```zsh
source ~/.zshrc
```

---

### 🚀 4. Use It!

Switch versions easily:

```bash
SET psql=15
psql --version       # 15.x
pg_dump --version    # 15.x
pg_restore --version # 15.x

SET psql=17          # back to 17
```

*The slave tools (`pg_dump`, `pg_restore`) automatically follow the `psql` version.*
([shkodenko.com][1], [serverfault.com][2], [askubuntu.com][3], [github.com][4])

---

### ⚠️ Why This Matters

Using the matching **newer-version `pg_dump` is recommended** when upgrading or restoring databases, to avoid compatibility issues.
([percona.com][5])

---

### 🧩 Summary

| Task                    | Command                                                        |    |    |       |
| ----------------------- | -------------------------------------------------------------- | -- | -- | ----- |
| Install client versions | `sudo apt install postgresql-client-14 postgresql-client-15 …` |    |    |       |
| Register binaries       | `update-alternatives --install…`                               |    |    |       |
| Switch on-the-fly       | \`SET psql=<14                                                 | 15 | 16 | 17>\` |

---

### ✅ Notes

* Ensure each `psql` is synchronized with its `pg_dump` and `pg_restore` via the `--slave` setup.
* Optionally, you can add other tools like `createdb`, `pg_basebackup` using similar methods.

[1]: https://www.shkodenko.com/managing-multiple-postgresql-versions-on-ubuntu-linux-a-guide-to-using-pg_dump-with-different-server-versions/?utm_source=chatgpt.com "Managing Multiple PostgreSQL Versions on Ubuntu Linux"
[2]: https://serverfault.com/questions/610777/wrong-version-of-pg-dump-on-ubuntu?utm_source=chatgpt.com "Wrong version of pg_dump on Ubuntu - Server Fault"
[3]: https://askubuntu.com/questions/33182/how-do-i-set-which-postgresql-version-is-to-be-used-by-default?utm_source=chatgpt.com "How do I set which PostgreSQL version is to be used by default?"
[4]: https://github.com/orgs/dbeaver/discussions/18879?utm_source=chatgpt.com "How to add different versions of postgresql native clients? #18879"
[5]: https://www.percona.com/blog/postgresql-upgrade-using-pg_dump-pg_restore/?utm_source=chatgpt.com "PostgreSQL Upgrade Using pg_dump/pg_restore: A Step ... - Percona"
