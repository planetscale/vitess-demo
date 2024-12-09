create table if not exists customer(
  customer_id bigint not null auto_increment,
  email varchar(128),
  primary key(customer_id)
) ENGINE=InnoDB;

create table if not exists corder(
  order_id bigint not null auto_increment,
  customer_id bigint,
  product varchar(128),
  primary key(order_id)
) ENGINE=InnoDB;
