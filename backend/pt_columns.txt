payment_transactions columns (37):
  id                                       bigint               nullable=NO    default=None
  amount                                   numeric              nullable=NO    default=None
  currency                                 character varying    nullable=NO    default=None
  transaction_type                         character varying    nullable=NO    default=None
  provider                                 character varying    nullable=NO    default=None
  provider_reference                       character varying    nullable=NO    default=None
  provider_method                          character varying    nullable=NO    default=None
  description                              text                 nullable=NO    default=None
  status                                   character varying    nullable=NO    default=None
  metadata                                 jsonb                nullable=NO    default=None
  webhook_received                         boolean              nullable=NO    default=None
  webhook_processed_at                     timestamp with time zone nullable=YES   default=None
  reconciled                               boolean              nullable=NO    default=None
  reconciliation_date                      date                 nullable=YES   default=None
  ip_address                               inet                 nullable=YES   default=None
  user_agent                               text                 nullable=NO    default=None
  callback_url                             character varying    nullable=YES   default=None
  redirect_url                             character varying    nullable=YES   default=None
  country                                  character varying    nullable=NO    default=None
  phone_number                             character varying    nullable=NO    default=None
  created_at                               timestamp with time zone nullable=NO    default=None
  updated_at                               timestamp with time zone nullable=NO    default=None
  completed_at                             timestamp with time zone nullable=YES   default=None
  initiated_by_id                          bigint               nullable=YES   default=None
  order_id                                 bigint               nullable=YES   default=None
  user_id                                  bigint               nullable=NO    default=None
  provider_config_id                       bigint               nullable=YES   default=None
  company_address                          text                 nullable=NO    default=None
  company_email                            character varying    nullable=NO    default=None
  company_name                             character varying    nullable=NO    default=None
  company_phone                            character varying    nullable=NO    default=None
  enrollment_type                          character varying    nullable=NO    default=None
  individual_email                         character varying    nullable=NO    default=None
  individual_name                          character varying    nullable=NO    default=None
  individual_phone                         character varying    nullable=NO    default=None
  is_corporate                             boolean              nullable=NO    default=None
  vat_number                               character varying    nullable=NO    default=None
