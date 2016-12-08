#!/bin/bash
# 判断是否以root用户运行
ROOT_UID=0

if [ "$UID" -eq "$ROOT_UID" ];
then
  :
else
  echo "请以root用户运行!"
  exit 1
fi

# 配置变量
GROUP="mysql"
USER="mysql"
TAR_NAME="mysql-5.6.21.tar.gz"

INSTALL_DIR="/opt/mysql"
DATA_DIR="/opt/mysql_data"
PORT=3306
CONFIG_DIR="/etc"
RUN_PID="/var/run/mysqld.pid"

# 安装必要的包
yum -y install gcc gcc-c++ gcc-g77 autoconf automake zlib* fiex* libxml* ncurses-devel libmcrypt* libtool-ltdl-devel* make cmake
if [ "$?" != 0 ];
then
	echo "安装必要软件包失败！"
else
	echo "安装必要软件包成功！"
fi

# 添加用户和组
groupadd $GROUP
if [ "$?" != 0 ];
then
	echo "添加组失败！"
else
	echo "添加组成功！"
fi

useradd -r -g $GROUP -s /sbin/nologin $USER
if [ "$?" != 0 ];
then
	echo "添加用户失败！"
else
	echo "添加组成功！"
fi

# 解压tar包并跳到解压目录
tar -xzf $TAR_NAME
cd $(ls -F | grep "/$")

# cmake
cmake \
-DCMAKE_INSTALL_PREFIX=$INSTALL_DIR \
-DMYSQL_DATADIR=$DATA_DIR \
-DSYSCONFDIR=$CONFIG_DIR \
-DWITH_MYISAM_STORAGE_ENGINE=1 \
-DWITH_INNOBASE_STORAGE_ENGINE=1 \
-DWITH_MEMORY_STORAGE_ENGINE=1 \
-DWITH_READLINE=1 \
-DMYSQL_UNIX_ADDR=$RUN_PID \
-DMYSQL_TCP_PORT=$PORT \
-DENABLED_LOCAL_INFILE=1 \
-DWITH_PARTITION_STORAGE_ENGINE=1 \
-DEXTRA_CHARSETS=all \
-DDEFAULT_CHARSET=utf8 \
-DDEFAULT_COLLATION=utf8_general_ci

# make
make clean
make && make install

# 初始化配置脚本，创建系统自带的数据库和表
echo "初始化配置脚本，创建系统自带的数据库和表"
cd $INSTALL_DIR
scripts/mysql_install_db --basedir=$INSTALL_DIR --datadir=$DATA_DIR --user=$USER

# 拷贝启动脚本
echo "复制启动脚本到/etc/init.d/，并设置开机启动"
cp support-files/mysql.server /etc/init.d/mysqld
chkconfig --add mysqld

# 设置环境变量
echo "设置环境变量"
touch /etc/profile.d/mysqld.sh
echo -e "PATH=${INSTALL_DIR}/bin:\$PATH\nexport PATH" > /etc/profile.d/mysqld.sh

# 更改目录权限
chown -R $USER:$GROUP $INSTALL_DIR
chown -R $USER:$GROUP $DATA_DIR