export AWS_ACCESS_KEY_ID=(your access key id)
export AWS_SECRET_ACCESS_KEY=(your secret access key)
export TF_VAR_db_name="rails_app"
export RDS_DBNAME="rails_app"
export TF_VAR_db_password="vitess_is_awesome"
export RDS_PASSWORD="vitess_is_awesome"
cd rds
terraform init
terraform apply
cd ..

export RDS_PASSWORD="vitess_is_awesome"
export RDS_DBNAME="rails_app"
export RDS_HOST=`terraform output -raw address`
export RDS_PORT=`terraform output -raw port`
export RDS_USER="admin"

mysql -u $RDS_USER -p$RDS_PASSWORD -h$RDS_HOST -P$RDS_PORT
# grant SYSTEM_VARIABLES_ADMIN on *.* to `admin`@`%`
# call mysql.rds_set_configuration('binlog retention hours', 24)

# start rails app
# spring stop

./vtop/start.sh
# start the move tables workflow

# rails page open
# vtgate open
# rds connection
# vitess connection

# rails config change
# ./moveToVitess.sh

cd rds
terraform destroy
