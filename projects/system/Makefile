install: executable sqlite3 check_prereq

sqlite3: lib/bin/sqlite3

lib/bin/sqlite3:
	unzip -j lib/sqlite3_command_line/sqlite3.zip 'sqlite-tools-linux-x86-3130000/sqlite3' -d lib/bin

check_prereq:
	./checks/prereq_check.sh

executable:
	chmod -R +w ./
	find ./ \( -name '*.sh' -o -name '*.pl' -o -name '*.py' \) -exec chmod +x {} \;
	chmod +x lib/bin/spkdiarization
