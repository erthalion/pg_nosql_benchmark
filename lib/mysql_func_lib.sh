#!/bin/bash

################################################################################
# Copyright EnterpriseDB Cooperation
# All rights reserved.
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#    * Redistributions of source code must retain the above copyright
#      notice, this list of conditions and the following disclaimer.
#    * Redistributions in binary form must reproduce the above copyright
#      notice, this list of conditions and the following disclaimer in
#      the documentation and/or other materials provided with the
#      distribution.
#    * Neither the name of PostgreSQL nor the names of its contributors
#      may be used to endorse or promote products derived from this
#      software without specific prior written permission.
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
# COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
# ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
#  Author: Vibhor Kumar
#  E-mail ID: vibhor.aim@gmail.com

################################################################################
# source common lib
################################################################################
source $DIRECTORY/lib/common_func_lib.sh

################################################################################
# function: mysql_json_insert_maker
################################################################################
function mysql_json_insert_maker ()
{
   typeset -r COLLECTION_NAME="$1"
   typeset -r NO_OF_ROWS="$2"
   typeset -r JSON_FILENAME="$3"

   process_log "preparing mysql INSERTs."
   rm -rf ${JSON_FILENAME}
   NO_OF_LOOPS=$((${NO_OF_ROWS}/11 + 1 ))
   for ((i=0;i<${NO_OF_LOOPS};i++))
   do
       json_seed_data $i | \
        sed "s/^/INSERT INTO ${COLLECTION_NAME}(data) VALUES('/"| \
        sed "s/$/');/" >>${JSON_FILENAME}
   done
}

################################################################################
# run_sql_file: send SQL from a file to database
################################################################################
function run_sql_file ()
{
   typeset -r F_MYSQLHOST="$1"
   typeset -r F_MYSQLPORT="$2"
   typeset -r F_DBNAME="$3"
   typeset -r F_MYSQLUSER="$4"
   typeset -r F_MYSQLPASSWORD="$5"
   typeset -r F_SQLFILE="$6"
   typeset -r F_OPTIONS="$6"

   export MYSQL_PWD="${F_MYSQLPASSWORD}"
   ${MYSQLHOME}/bin/mysql -qAt --host=${F_MYSQLHOST} --port ${F_MYSQLPORT} --user ${F_MYSQLUSER} \
                  ${F_DBNAME} < "${F_SQLFILE}"
}

################################################################################
# run_sql: send SQL to database
################################################################################
function run_sql ()
{
   typeset -r F_MYSQLHOST="$1"
   typeset -r F_MYSQLPORT="$2"
   typeset -r F_DBNAME="$3"
   typeset -r F_MYSQLUSER="$4"
   typeset -r F_MYSQLPASSWORD="$5"
   typeset -r F_SQL="$6"
   typeset -r F_OPTIONS="${7:-}"

   export MYSQL_PWD="${F_MYSQLPASSWORD}"
   #process_log "${MYSQLHOME}/bin/mysql ${F_OPTIONS} --host=${F_MYSQLHOST} --user=${F_MYSQLUSER} ${F_DBNAME} -e \"${F_SQL}\""

   ${MYSQLHOME}/bin/mysql ${F_OPTIONS} --host=${F_MYSQLHOST} --user=${F_MYSQLUSER} \
                     ${F_DBNAME} -e "${F_SQL}"
}

################################################################################
# function: remove_mysqldb (remove mysql database)
################################################################################
function remove_mysql_db ()
{
   typeset -r F_MYSQLHOST="$1"
   typeset -r F_MYSQLPORT="$2"
   typeset -r F_DBNAME="$3"
   typeset -r F_MYSQLUSER="$4"
   typeset -r F_MYSQLPASSWORD="$5"
   typeset -r F_SQL="DROP DATABASE IF EXISTS ${F_DBNAME};"

   process_log "droping database ${F_DBNAME} if exists."
   run_sql "${F_MYSQLHOST}" "${F_MYSQLPORT}" "" "${F_MYSQLUSER}" \
           "${F_MYSQLPASSWORD}" "${F_SQL}" 2>/dev/null >/dev/null
}

################################################################################
# function: create_mysqldb (create mysql database)
################################################################################
function create_mysql_db ()
{
   typeset -r F_MYSQLHOST="$1"
   typeset -r F_MYSQLPORT="$2"
   typeset -r F_DBNAME="$3"
   typeset -r F_MYSQLUSER="$4"
   typeset -r F_MYSQLPASSWORD="$5"
   typeset -r F_SQL="CREATE DATABASE ${F_DBNAME};"

   process_log "creating database ${F_DBNAME}."
   run_sql "${F_MYSQLHOST}" "${F_MYSQLPORT}" "" "${F_MYSQLUSER}" \
           "${F_MYSQLPASSWORD}" "${F_SQL}"
}

################################################################################
# function: relation_size (calculate mysql relation size)
################################################################################
function mysql_relation_size ()
{
   typeset -r F_MYSQLHOST="$1"
   typeset -r F_MYSQLPORT="$2"
   typeset -r F_DBNAME="$3"
   typeset -r F_MYSQLUSER="$4"
   typeset -r F_MYSQLPASSWORD="$5"
   typeset -r F_RELATION="$6"
   typeset -r F_OPTIONS="-sN"
   typeset -r F_SQL="SELECT data_length FROM information_schema.TABLES
       WHERE table_schema = '"${F_DBNAME}"'
       AND table_name = '${F_RELATION}';"

   process_log "calculating mysql collection size."
   run_sql "${F_MYSQLHOST}" "${F_MYSQLPORT}" "${F_DBNAME}" "${F_MYSQLUSER}" \
           "${F_MYSQLPASSWORD}" "${F_SQL}" ${F_OPTIONS}
}

################################################################################
# function: index_size (calculate mysql index size)
################################################################################
function mysql_index_size ()
{
   typeset -r F_MYSQLHOST="$1"
   typeset -r F_MYSQLPORT="$2"
   typeset -r F_DBNAME="$3"
   typeset -r F_MYSQLUSER="$4"
   typeset -r F_MYSQLPASSWORD="$5"
   typeset -r F_RELATION="$6"
   typeset -r F_OPTIONS="-sN"
   typeset -r F_SQL="SELECT index_length FROM information_schema.TABLES
       WHERE table_schema = '"${F_DBNAME}"'
       AND table_name = '${F_RELATION}';"

   process_log "calculating mysql index size."
   run_sql "${F_MYSQLHOST}" "${F_MYSQLPORT}" "${F_DBNAME}" "${F_MYSQLUSER}" \
           "${F_MYSQLPASSWORD}" "${F_SQL}" ${F_OPTIONS}
}

################################################################################
# function: check if database exists
################################################################################
function if_dbexists ()
{
   typeset -r F_MYSQLHOST="$1"
   typeset -r F_MYSQLPORT="$2"
   typeset -r F_DBNAME="$3"
   typeset -r F_MYSQLUSER="$4"
   typeset -r F_MYSQLPASSWORD="$5"
   typeset -r F_SQL="SELECT COUNT(1)
                     FROM pg_catalog.pg_database
                        WHERE datname='${F_DBNAME}';"

   output=$(run_sql "${F_MYSQLHOST}" "${F_MYSQLPORT}" "postgres" "${F_MYSQLUSER}" \
                    "${F_MYSQLPASSWORD}" \
                    "${F_SQL}")
   echo ${output}
}

################################################################################
# function: mk_mysqljson_collection create json table in mysql
################################################################################
function mk_mysql_json_collection ()
{
   typeset -r F_MYSQLHOST="$1"
   typeset -r F_MYSQLPORT="$2"
   typeset -r F_DBNAME="$3"
   typeset -r F_MYSQLUSER="$4"
   typeset -r F_MYSQLPASSWORD="$5"
   typeset -r F_TABLE="$6"
   typeset -r F_SQL1="DROP TABLE IF EXISTS ${F_TABLE} CASCADE;"
   typeset -r F_SQL2="CREATE TABLE  ${F_TABLE} (data JSON);"

  process_log "creating ${F_TABLE} collection in mysql."
  run_sql "${F_MYSQLHOST}" "${F_MYSQLPORT}" "${F_DBNAME}" "${F_MYSQLUSER}" \
          "${F_MYSQLPASSWORD}" "${F_SQL1}" \
          #>/dev/null 2>/dev/null
  run_sql "${F_MYSQLHOST}" "${F_MYSQLPORT}" "${F_DBNAME}" "${F_MYSQLUSER}" \
          "${F_MYSQLPASSWORD}" "${F_SQL2}" \
          #>/dev/null 2>/dev/null
}

################################################################################
# function: mysql_create_index create index for each virtual field
################################################################################
function mysql_create_index_collection ()
{
   typeset -r F_MYSQLHOST="$1"
   typeset -r F_MYSQLPORT="$2"
   typeset -r F_DBNAME="$3"
   typeset -r F_MYSQLUSER="$4"
   typeset -r F_MYSQLPASSWORD="$5"
   typeset -r F_TABLE="$6"
   typeset -r F_SQL_BRAND="ALTER TABLE ${F_TABLE} ADD brand varchar(100) GENERATED ALWAYS AS (json_extract(data, '$.brand')) VIRTUAL;"
   typeset -r F_SQL_BRAND_INDEX="CREATE INDEX ${F_TABLE}_brand_idx ON ${F_TABLE}(brand);"
   typeset -r F_SQL_NAME="ALTER TABLE ${F_TABLE} ADD name varchar(100) GENERATED ALWAYS AS (json_extract(data, '$.name')) VIRTUAL;"
   typeset -r F_SQL_NAME_INDEX="CREATE INDEX ${F_TABLE}_name_idx ON ${F_TABLE}(name);"
   typeset -r F_SQL_TYPE="ALTER TABLE ${F_TABLE} ADD type varchar(100) GENERATED ALWAYS AS (json_extract(data, '$.type')) VIRTUAL;"
   typeset -r F_SQL_TYPE_INDEX="CREATE INDEX ${F_TABLE}_type_idx ON ${F_TABLE}(type);"


   process_log "creating index on mysql collections."
   run_sql "${F_MYSQLHOST}" "${F_MYSQLPORT}" "${F_DBNAME}" "${F_MYSQLUSER}" \
           "${F_MYSQLPASSWORD}" "${F_SQL_BRAND}" \
            >/dev/null

   run_sql "${F_MYSQLHOST}" "${F_MYSQLPORT}" "${F_DBNAME}" "${F_MYSQLUSER}" \
           "${F_MYSQLPASSWORD}" "${F_SQL_BRAND_INDEX}" \
            >/dev/null

   run_sql "${F_MYSQLHOST}" "${F_MYSQLPORT}" "${F_DBNAME}" "${F_MYSQLUSER}" \
           "${F_MYSQLPASSWORD}" "${F_SQL_NAME}" \
            >/dev/null

   run_sql "${F_MYSQLHOST}" "${F_MYSQLPORT}" "${F_DBNAME}" "${F_MYSQLUSER}" \
           "${F_MYSQLPASSWORD}" "${F_SQL_NAME_INDEX}" \
            >/dev/null

   run_sql "${F_MYSQLHOST}" "${F_MYSQLPORT}" "${F_DBNAME}" "${F_MYSQLUSER}" \
           "${F_MYSQLPASSWORD}" "${F_SQL_TYPE}" \
            >/dev/null

   run_sql "${F_MYSQLHOST}" "${F_MYSQLPORT}" "${F_DBNAME}" "${F_MYSQLUSER}" \
           "${F_MYSQLPASSWORD}" "${F_SQL_TYPE_INDEX}" \
            >/dev/null
}


################################################################################
# function: pg_create_gin_index create simle gin index for jsonb table in MYSQL
################################################################################
function pg_create_gin_index_collection ()
{
   typeset -r F_MYSQLHOST="$1"
   typeset -r F_MYSQLPORT="$2"
   typeset -r F_DBNAME="$3"
   typeset -r F_MYSQLUSER="$4"
   typeset -r F_MYSQLPASSWORD="$5"
   typeset -r F_TABLE="$6"

   pg_create_index_collection "${F_MYSQLHOST}" \
                              "${F_MYSQLPORT}" \
                              "${F_DBNAME}" \
                              "${F_MYSQLUSER}" \
                              "${F_MYSQLPASSWORD}" \
                              "${F_TABLE}" \
                              "" # no special index options
}

################################################################################
# function: pg_create_jpo_index create jsonb_path_ops index for jsonb table in MYSQL
################################################################################
function pg_create_jpo_index_collection ()
{
   typeset -r F_MYSQLHOST="$1"
   typeset -r F_MYSQLPORT="$2"
   typeset -r F_DBNAME="$3"
   typeset -r F_MYSQLUSER="$4"
   typeset -r F_MYSQLPASSWORD="$5"
   typeset -r F_TABLE="$6"

   pg_create_index_collection "${F_MYSQLHOST}" \
                              "${F_MYSQLPORT}" \
                              "${F_DBNAME}" \
                              "${F_MYSQLUSER}" \
                              "${F_MYSQLPASSWORD}" \
                              "${F_TABLE}" \
                              "jsonb_path_ops" # no special index options
}

################################################################################
# function: delete_json_data delete json data in MYSQL
################################################################################
function delete_json_data ()
{

   typeset -r F_MYSQLHOST="$1"
   typeset -r F_MYSQLPORT="$2"
   typeset -r F_DBNAME="$3"
   typeset -r F_MYSQLUSER="$4"
   typeset -r F_MYSQLPASSWORD="$5"
   typeset -r F_COLLECTION="$6"

   process_log "droping json object in mysql."
   run_sql "${F_MYSQLHOST}" "${F_MYSQLPORT}" "${F_DBNAME}" "${F_MYSQLUSER}" \
           "${F_MYSQLPASSWORD}" \
           "TRUNCATE TABLE ${F_COLLECTION};" >/dev/null
}

################################################################################
# function: pg_copy_benchmark
################################################################################
function pg_copy_benchmark ()
{
   typeset -r F_MYSQLHOST="$1"
   typeset -r F_MYSQLPORT="$2"
   typeset -r F_DBNAME="$3"
   typeset -r F_MYSQLUSER="$4"
   typeset -r F_MYSQLPASSWORD="$5"
   typeset -r F_COLLECTION="$6"
   typeset -r F_JSONFILE="$7"
   typeset -r F_COPY="COPY ${F_COLLECTION} FROM STDIN;"

   DBEXISTS=$(if_dbexists "${F_MYSQLHOST}" "${F_MYSQLPORT}" "${F_DBNAME}" \
                          "${F_MYSQLUSER}" "${F_MYSQLPASSWORD}")
   process_log "loading data in mysql using ${F_JSONFILE}."
   start_time=$(get_timestamp_nano)
   cat ${F_JSONFILE}|run_sql "${F_MYSQLHOST}" "${F_MYSQLPORT}" "${F_DBNAME}" \
                             "${F_MYSQLUSER}" "${F_MYSQLPASSWORD}" "${F_COPY}"
   end_time=$(get_timestamp_nano)
   total_time="$(get_timestamp_diff_nano "${end_time}" "${start_time}")"

   echo "${total_time}"

}


################################################################################
# function: benchmark mysql inserts
################################################################################
function mysql_inserts_benchmark ()
{

   typeset -r F_MYSQLHOST="$1"
   typeset -r F_MYSQLPORT="$2"
   typeset -r F_DBNAME="$3"
   typeset -r F_MYSQLUSER="$4"
   typeset -r F_MYSQLPASSWORD="$5"
   typeset -r F_COLLECTION="$6"
   typeset -r F_INSERTS="$7"

   process_log "inserting data in mysql using ${F_INSERTS}."
   start_time=$(get_timestamp_nano)
   #mysql -qAt --host=52.33.91.86 --password='123456' --user=test benchmark < "sample_pg_inserts.json"
   run_sql_file "${F_MYSQLHOST}" "${F_MYSQLPORT}" "${F_DBNAME}" "${F_MYSQLUSER}" \
                "${F_MYSQLPASSWORD}" "${F_INSERTS}"
   end_time=$(get_timestamp_nano)
   total_time="$(get_timestamp_diff_nano "${end_time}" "${start_time}")"

   echo "${total_time}"
}

################################################################################
# function: benchmark mysql select
################################################################################
function mysql_select_benchmark ()
{
   typeset -r F_MYSQLHOST="$1"
   typeset -r F_MYSQLPORT="$2"
   typeset -r F_DBNAME="$3"
   typeset -r F_MYSQLUSER="$4"
   typeset -r F_MYSQLPASSWORD="$5"
   typeset -r F_COLLECTION="$6"

   typeset -r F_BRAND='\"ACME\"'
   typeset -r F_NAME1='\"Phone Service Basic Plan\"'
   typeset -r F_NAME2='\"AC3 Case Red\"'
   typeset -r F_TYPE='\"service\"'
   typeset -r F_SELECT1="SELECT data
                         FROM ${F_COLLECTION}
                           WHERE  brand = '${F_BRAND}';"
   typeset -r F_SELECT2="SELECT data
                         FROM ${F_COLLECTION}
                           WHERE  name = '${F_NAME1}';"
   typeset -r F_SELECT3="SELECT data
                         FROM ${F_COLLECTION}
                          WHERE  name = '${F_NAME2}';"
   typeset -r F_SELECT4="SELECT data
                          FROM ${F_COLLECTION}
                            WHERE  type = '${F_TYPE}';"
   local START end_time

   process_log "testing FIRST SELECT in mysql."
   start_time=$(get_timestamp_nano)
   run_sql "${F_MYSQLHOST}" "${F_MYSQLPORT}" "${F_DBNAME}" "${F_MYSQLUSER}" \
           "${F_MYSQLPASSWORD}" \
           "$F_SELECT1" >/dev/null || exit_on_error "failed to execute SELECT 1."
   end_time=$(get_timestamp_nano)
   total_time1="$(get_timestamp_diff_nano "${end_time}" "${start_time}")"

   process_log "testing SECOND SELECT in mysql."
   start_time=$(get_timestamp_nano)
   run_sql "${F_MYSQLHOST}" "${F_MYSQLPORT}" "${F_DBNAME}" "${F_MYSQLUSER}" \
           "${F_MYSQLPASSWORD}" \
           "${F_SELECT2}" >/dev/null || exit_on_error "failed to execute SELECT 2."
   end_time=$(get_timestamp_nano)
   total_time2="$(get_timestamp_diff_nano "${end_time}" "${start_time}")"

   process_log "testing THIRD SELECT in mysql."
   start_time=$(get_timestamp_nano)
   run_sql "${F_MYSQLHOST}" "${F_MYSQLPORT}" "${F_DBNAME}" "${F_MYSQLUSER}" \
           "${F_MYSQLPASSWORD}" \
           "${F_SELECT3}" >/dev/null || exit_on_error "failed to execute SELECT 2."
   end_time=$(get_timestamp_nano)
   total_time3="$(get_timestamp_diff_nano "${end_time}" "${start_time}")"

   process_log "testing FOURTH SELECT in mysql."
   start_time=$(get_timestamp_nano)
   run_sql "${F_MYSQLHOST}" "${F_MYSQLPORT}" "${F_DBNAME}" "${F_MYSQLUSER}" \
           "${F_MYSQLPASSWORD}" \
           "${F_SELECT4}" >/dev/null || exit_on_error "failed to execute SELECT 4."
   end_time=$(get_timestamp_nano)
   total_time4="$(get_timestamp_diff_nano "${end_time}" "${start_time}")"

   AVG=$(( ($total_time1 + $total_time2 + $total_time3 + $total_time4 )/4 ))

   echo "${AVG}"
}


################################################################################
# function: mk_pgjson_collection create json table in MYSQL
################################################################################
function analyze_collections ()
{
   typeset -r F_MYSQLHOST="$1"
   typeset -r F_MYSQLPORT="$2"
   typeset -r F_DBNAME="$3"
   typeset -r F_MYSQLUSER="$4"
   typeset -r F_MYSQLPASSWORD="$5"
   typeset -r F_TABLE="$6"
   typeset -r F_SQL="VACUUM FREEZE ANALYZE ${F_TABLE};"

   process_log "performing analyze in mysql."
   run_sql "${F_MYSQLHOST}" "${F_MYSQLPORT}" "${F_DBNAME}" "${F_MYSQLUSER}" \
           "${F_MYSQLPASSWORD}" "${F_SQL}" \
            >/dev/null 2>/dev/null
}

################################################################################
# function: mk_mysqljson_collection create json table in mysql
################################################################################
function mysql_version ()
{
   typeset -r F_MYSQLHOST="$1"
   typeset -r F_MYSQLPORT="$2"
   typeset -r F_DBNAME="$3"
   typeset -r F_MYSQLUSER="$4"
   typeset -r F_MYSQLPASSWORD="$5"
   typeset -r F_SQL="select version();"
   typeset -r F_OPTIONS="-sN"

   echo "Start version"
   version=$(run_sql "${F_MYSQLHOST}" "${F_MYSQLPORT}" "${F_DBNAME}" "${F_MYSQLUSER}" \
           "${F_MYSQLPASSWORD}" "${F_SQL}" "${F_OPTIONS}")
   echo "${version}"
}
