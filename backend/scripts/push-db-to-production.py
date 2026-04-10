import os
import posixpath
import sys
from datetime import UTC, datetime

import paramiko


ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
ROOT_ENV_PATH = os.path.join(ROOT, ".env")


def load_simple_env(path):
    values = {}
    with open(path, "r", encoding="utf-8") as handle:
        for raw_line in handle:
            line = raw_line.strip()
            if not line or line.startswith("#"):
                continue
            if "=" in line:
                key, value = line.split("=", 1)
            elif ":" in line:
                key, value = line.split(":", 1)
            else:
                continue
            values[key.strip()] = value.strip()
    return values


def run_command(ssh, command, timeout=120):
    stdin, stdout, stderr = ssh.exec_command(command, timeout=timeout)
    exit_code = stdout.channel.recv_exit_status()
    out = stdout.read().decode("utf-8", errors="replace")
    err = stderr.read().decode("utf-8", errors="replace")
    if exit_code != 0:
        raise RuntimeError(f"Command failed ({exit_code}): {command}\nSTDOUT:\n{out}\nSTDERR:\n{err}")
    return out.strip()


def shell_quote(value):
    return "'" + str(value).replace("'", "'\"'\"'") + "'"


def find_remote_backend_env(ssh):
    candidates = [
        "/opt/hanti-riyo/backend/.env",
        "/opt/niyaah/backend/.env",
        "/root/Rental App/backend/.env",
        "/root/rental-app/backend/.env",
        "/root/backend/.env",
        "/var/www/backend/.env",
        "/opt/backend/.env",
    ]
    for candidate in candidates:
        result = run_command(
            ssh,
            f"test -f {shell_quote(candidate)} && printf found || true",
            timeout=20,
        )
        if result == "found":
            return candidate

    dynamic = run_command(
        ssh,
        r"find /root /var/www /opt -maxdepth 4 -type f -name .env 2>/dev/null | grep '/backend/\.env$' | head -n 1 || true",
        timeout=60,
    )
    if dynamic:
        return dynamic.splitlines()[0].strip()
    raise RuntimeError("Could not find remote backend/.env")


def main():
    args = sys.argv[1:]
    skip_backup = False
    if "--skip-backup" in args:
        skip_backup = True
        args.remove("--skip-backup")

    if len(args) < 1:
        raise SystemExit("Usage: python backend/scripts/push-db-to-production.py <local-sql-dump-path>")

    local_sql_path = os.path.abspath(args[0])
    if not os.path.exists(local_sql_path):
        raise FileNotFoundError(local_sql_path)

    root_env = load_simple_env(ROOT_ENV_PATH)
    host = root_env.get("droplet ip")
    username = root_env.get("droplet username")
    password = root_env.get("droplet password")

    if not host or not username or not password:
        raise RuntimeError("Missing droplet credentials in repo root .env")

    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(hostname=host, username=username, password=password, timeout=20)

    try:
        remote_env_path = find_remote_backend_env(ssh)
        remote_backend_dir = posixpath.dirname(remote_env_path)
        remote_env_raw = run_command(ssh, f"cat {shell_quote(remote_env_path)}", timeout=20)
        remote_env = {}
        for raw_line in remote_env_raw.splitlines():
            line = raw_line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            remote_env[key.strip()] = value.strip()

        db_name = remote_env.get("DB_NAME")
        db_user = remote_env.get("DB_USER")
        db_password = remote_env.get("DB_PASSWORD", "")
        if not db_name or not db_user:
            raise RuntimeError("Remote backend .env is missing DB_NAME or DB_USER")

        timestamp = datetime.now(UTC).strftime("%Y%m%d-%H%M%S")
        remote_tmp_dir = f"/root/db-sync-{timestamp}"
        remote_import_path = f"{remote_tmp_dir}/import.sql"
        remote_backup_path = f"{remote_tmp_dir}/production-backup.sql"

        run_command(ssh, f"mkdir -p {shell_quote(remote_tmp_dir)}", timeout=20)

        sftp = ssh.open_sftp()
        try:
            sftp.put(local_sql_path, remote_import_path)
        finally:
            sftp.close()

        mysql_env_prefix = f"MYSQL_PWD={shell_quote(db_password)} " if db_password else ""
        if not skip_backup:
            backup_command = (
                f"cd {shell_quote(remote_backend_dir)} && "
                f"{mysql_env_prefix}mysqldump -u {shell_quote(db_user)} --single-transaction --routines --triggers "
                f"{shell_quote(db_name)} > {shell_quote(remote_backup_path)}"
            )
            run_command(ssh, backup_command, timeout=300)

        import_command = (
            f"cd {shell_quote(remote_backend_dir)} && "
            f"{mysql_env_prefix}mysql -u {shell_quote(db_user)} {shell_quote(db_name)} < {shell_quote(remote_import_path)}"
        )
        run_command(ssh, import_command, timeout=300)

        listing_count = run_command(
            ssh,
            (
                f"cd {shell_quote(remote_backend_dir)} && "
                f"{mysql_env_prefix}mysql -N -B -u {shell_quote(db_user)} {shell_quote(db_name)} "
                f"-e {shell_quote('SELECT COUNT(*) FROM listings;')}"
            ),
            timeout=60,
        )

        if not skip_backup:
            print(f"backup={remote_backup_path}")
        print(f"remote_env={remote_env_path}")
        print(f"listings={listing_count}")
    finally:
        ssh.close()


if __name__ == "__main__":
    main()
