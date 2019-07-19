#!/bin/bash


READLINK=readlink
which greadlink &> /dev/null  &&  READLINK=greadlink

THIS_SCRIPT="$(dirname "$(readlink "${BASH_SOURCE[0]}")")"
INIT_HOME=$(dirname $THIS_SCRIPT)
CONF_HOME=$(dirname $INIT_HOME)
CONF_ETC_TOP=$CONF_HOME/etc
BIN_DIR=$CONF_HOME/bin

# PID & LOCK files
PID_DIR=var/run
LOCK_DIR=var/lock/subsys

CONF_ZK_PROPERTIES=${CONF_ETC_TOP}/kafka/zookeeper.properties
CONF_KAFKA_PROPERTIES=${CONF_ETC_TOP}/kafka/server.properties
CONF_REST_PROPERTIES=${CONF_ETC_TOP}/kafka-rest/kafka-rest.properties
CONF_SCHEMA_PROPERTIES=${CONF_ETC_TOP}/schema-registry/schema-registry.properties
CONF_CONNECT_PROPERTIES=${CONF_ETC_TOP}/schema-registry/connect-avro-distributed.properties
CONF_KSQL_PROPERTIES=${CONF_ETC_TOP}/ksql/ksql-server.properties
CONF_COMMAND_PROPERTIES=${CONF_ETC_TOP}/confluent-control-center/control-center.properties

CONF_USER=`stat -f '%Su' $CONF_ZK_PROPERTIES`

ZK_PIDFILE=$PID_DIR/cp-zk-service.pid
KAFKA_PIDFILE=$PID_DIR/cp-kafka-service.pid
SCHEMA_PIDFILE=$PID_DIR/cp-schema-service.pid
REST_PIDFILE=$PID_DIR/cp-rest-service.pid
CONNECT_PIDFILE=$PID_DIR/cp-connect-service.pid
KSQL_PIDFILE=$PID_DIR/cp-ksql-service.pid
COMMAND_PIDFILE=$PID_DIR/cp-command-service.pid

CONF_KAFKA_CLASS='io.confluent.support.metrics.SupportedKafka'
CONF_SCHEMA_CLASS='io.confluent.kafka.schemaregistry.rest.SchemaRegistryMain'
CONF_REST_CLASS='io.confluent.kafkarest.KafkaRestMain'
CONF_CONNECT_CLASS='org.apache.kafka.connect.cli.ConnectDistributed'
CONF_KSQL_CLASS='io.confluent.ksql.rest.server.KsqlServerMain'
CONF_COMMAND_CLASS='io.confluent.controlcenter.ControlCenter'



# Simple function to shut down the CP Java service based on
#	$1: PID file
#	$2: unique string from Java invocation
#	$3: service name [optional]
#	$4: sleep time in second after shutdown [optional; defaults to 3 seconds]
#
# Logic :
#	If PID_FILE is passed in and valid, use that to identify a PID.
#	Otherwise, use the unique string to track down the PID
#		A "service name" specification will take precedence over a "grep'ed" PID

function status_cp_service() {
    name=$3
    [ -s $1 ] && PID=`cat $1`
    CURRENT_PID=`pgrep -u $CONF_USER -f $2`
    if [[ ! -z "$PID" && ! -z "$CURRENT_PID" && "$PID" = "$CURRENT_PID" ]]  ; then
        echo "($name) is running on PID: $CURRENT_PID"
    else
        echo "($name) is not running. Restart $name"
    fi
}

status_cp_service $REST_PIDFILE $CONF_REST_CLASS "cp-rest-service"
status_cp_service $COMMAND_PIDFILE $CONF_COMMAND_CLASS "cp-command-service"
status_cp_service $CONNECT_PIDFILE $CONF_CONNECT_CLASS "cp-connect-service"
status_cp_service $KSQL_PIDFILE $CONF_KSQL_CLASS "cp-ksql-service"
status_cp_service $SCHEMA_PIDFILE $CONF_SCHEMA_CLASS "cp-schema-service"
status_cp_service $KAFKA_PIDFILE $CONF_KAFKA_CLASS "cp-kafka-service"
status_cp_service $ZK_PIDFILE `basename $CONF_ZK_PROPERTIES` "cp-zk-service"

exit 0
