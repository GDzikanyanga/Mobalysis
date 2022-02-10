#this is my file
echo "Creating variables for use throughout the PSQL installation process"
# $packages is an array containing the dependencies for PostgreSQL
packages=('git' 'gcc' 'tar' 'gzip' 'libreadline5' 'make' 'zlib1g' 'zlib1g-dev' 'flex' 'bison' 'perl' 'python3' 'tcl' 'gettext' 'odbc-postgresql' 'libreadline6-dev')
# $rfolder is the install directory for PostgreSQL
rfolder='/postgres'
# $dfolder is the root directory for various types of read-only data files
dfolder='/postgres/data'
# $gitloc is the location of the PosgreSQL git repo
gitloc='git://git.postgresql.org/git/postgresql.git'
# $sysuser is the system user for running PostgreSQL
sysuser='postgres'
# $helloscript is the sql script for creating the PSQL user and creating a database.
helloscript='/home/leewalker/scripts/hello.sql'
# $logfile is the log file for this installation.
logfile='psqlinstall-log'

# Section 2 - Package Installation

# Ensures the server is up to date before proceeding.
echo "Updating server..."
sudo apt-get update -y >> $logfile

# This for-loop will pull all packages from the package array and install them using apt-get
echo "Installing PostgreSQL dependencies"
sudo apt-get install ${packages[@]} -y >> $logfile


# Section 3 - Create required directories

echo "Creating folders $dfolder..."
sudo mkdir -p $dfolder >> $logfile
# Purpose - Script to add a user to Linux system including passsword
# Author - Vivek Gite <www.cyberciti.biz> under GPL v2.0+
# ------------------------------------------------------------------
# Am i Root user?
if [ $(id -u) -eq 0 ]; then
read -p "Enter username : " username
read -s -p "Enter password : " password
egrep "^$username" /etc/passwd >/dev/null
if [ $? -eq 0 ]; then
echo "$username exists!"
exit 1
else
pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
useradd -m -p "$pass" "$username"
[ $? -eq 0 ] && echo "User has been added to system!" || echo "Failed to add a user!"
fi
else
echo "Only root may add a user to the system."
exit 2
fi
# $helloscript is the sql script for creating the PSQL user and creating a database.
helloscript='/home/mob_db_user/scripts/hello.sql'
# $logfile is the log file for this installation.
logfile='psqlinstall-log'# Section 2 - Package Installation# Ensures the server is up to date before proceeding.
echo "Updating server..."
sudo apt-get update -y >> $logfile# This for-loop will pull all packages from the package array and install them using apt-get
echo "Installing PostgreSQL dependencies"
sudo apt-get install ${packages[@]} -y >> $logfile
# Section 3 - Create required directoriesecho "Creating folders $dfolder..."
sudo mkdir -p $dfolder >> $logfile
# Section 4 - Create system userecho "Creating system user '$sysuser'"
sudo adduser --system $sysuser >> $logfile
# Section 5 - Pull down PSQL using gitecho "Pulling down PostgreSQL from $gitloc"
git clone $gitloc >> $logfile
# Section 6 - Install and configure PSQL# Configuring PostgreSQL to be installed at /postgres with a data root directory of /postgres/data
echo "Configuring PostgreSQL"
~/postgresql/configure --prefix=$rfolder --datarootdir=$dfolder >> $logfileecho "Making PostgreSQL"
make >> $logfileecho "installing PostgreSQL"
sudo make install >> $logfileecho "Giving system user '$sysuser' control over the $dfolder folder"
sudo chown postgres $dfolder >> $logfile# InitDB is used to create the location of the database cluster, for the purpose of this exercise it will be placed in the $dfolder under /db.
echo "Running initdb"
sudo -u postgres $rfolder/bin/initdb -D $dfolder/db >> $logfile
# Section 7 - Start PSQL# PostgreSQL is being started, using pg_ctl as the system user postgres.
echo "Starting PostgreSQL"
sudo -u postgres $rfolder/bin/pg_ctl -D $dfolder/db -l $dfolder/logfilePSQL start >> $logfile# Section 8 - Add PostgreSQL to /etc/rc.local and add environment variables to /etc/profile# The command to start PostgreSQL at launch is added to /etc/rc.local, again using the system user postgres.
echo "Set PostgreSQL to launch on startup"
sudo sed -i '$isudo -u postgres /postgres/bin/pg_ctl -D /postgres/data/db -l /postgres/data/logfilePSQL start' /etc/rc.local >> $logfile# This block adds the environment variables for PostgreSQL to /etc/profile in order to set them for all users.
echo "Writing PostgreSQL environment variables to /etc/profile"
cat << EOL | sudo tee -a /etc/profile# PostgreSQL Environment VariablesLD_LIBRARY_PATH=/postgres/lib
export LD_LIBRARY_PATH
PATH=/postgres/bin:$PATH
export PATH
EOL
# Section 8 - hello.sql script is ranecho "Wait for PostgreSQL to finish starting up..."
sleep 5# The hello.sql script is ran to create the user, database, and populate the database.
echo "Running script"
$rfolder/bin/psql -U postgres -f $helloscript
# Section 9 - hello_postgres is queriedecho "Querying the newly created table in the newly created database."
/postgres/bin/psql -c 'select * from hello;' -U psqluser hello_postgres;


