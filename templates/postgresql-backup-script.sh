#!/usr/bin/env bash
# {{ ansible_managed }}

set -o pipefail


BACKUP_DIR_BASE="{{ postgresql_backup.backup_dir | default( '/var/backup/postgresql/' ) }}"
DATE_FORMAT="{{ postgresql_backup.date_format | default( '%Y-%m-%d_%H-%M' ) }}"

create_backup_dir() {
	local backup_dir="${BACKUP_DIR_BASE%/}/$(date "+$DATE_FORMAT")"
	mkdir -p "$backup_dir"
	echo "$backup_dir"
}

backup_databases() {
  {% for db in postgresql_backup.databases %}
  if (umask 077 && pg_dump -F c -h "{{ db.host | defaul( 'localhost' ) }}" -U "{{ db.user | default( 'postgres' ) }}" -p "{{ db.port | default( '5432' ) }}" "{{ db.name }}" -f "{{ db.name }}.in_progress.psql"); then
	  mv "{{ db.name }}.in_progress.psql" "{{ db.name }}.psql"
  else
	  return 1
  fi;
  {% endfor %}
	return 0
}




main() {
	backup_dir="$(create_backup_dir)"
	echo "Created backup directory \"${backup_dir}\"."

	pushd . >/dev/null
	cd "$backup_dir"

	echo "Starting databases backup."
	if backup_databases; then
		echo "Databases backup is done."
	else
		echo "Databases backup failed. Exiting."
		exit 1;
	fi;

	popd >/dev/null
}


main