# Class: mongodb::service::cluster
#
#
class mongodb::service::cluster (
  $instance_name,
  $replica_set_name,
  $replica_set_hosts,
  $mongodb_options = [],
) {
  include ::mongodb

  # http://docs.mongodb.org/master/reference/configuration-options/
  mongodb::mongod {
    $instance_name:
      mongod_instance    => $instance_name,
      mongod_replSet     => $replica_set_name,
      mongod_port        => 27017,
      mongod_add_options => $mongodb_options,
      mongod_monit       => false,
  }

  mongodb::replication::script { 'init-replica-set':
      replica_set_hosts => $replica_set_hosts,
      replica_set_name  => $replica_set_name,
  }

}