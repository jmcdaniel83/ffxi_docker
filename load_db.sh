
# root user for mysql instance
root_user=root
root_pass=password

# topaz mysql credentials
host=192.168.2.37
port=3306
user=topazadmin
pass=topazisawesome
db_name=tpzdb

# set pur user to the database
echo Setting up new user...
query="""
CREATE USER '${user}' IDENTIFIED BY '${pass}';
CREATE DATABASE ${db_name};

USE ${db_name};
GRANT ALL PRIVILEGES ON ${db_name}.* TO '${user}';
"""
mysql -h ${host} --port ${port} -u ${root_user} -p${root_pass} -e "${query}"

# establish our new database
echo Loading tables to database...
pushd sql
for f in *.sql; do
    echo -n "Importing $f into the database...";
    mysql ${db_name} -u ${user} -p${pass} -h ${host} --port ${port} < $f && echo "Success";
done
popd

# EOF

