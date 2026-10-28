-- Índices SQLite sincrónicos, aplicados por migración de D1.

CREATE INDEX expenses_active_period_idx ON expenses
	(owner_id, occurred_on, id) WHERE deleted_at IS NULL;

CREATE INDEX expenses_active_category_period_idx ON expenses
	(owner_id, category_id, occurred_on, id) WHERE deleted_at IS NULL;

CREATE INDEX expenses_category_reference_idx ON expenses
	(owner_id, category_id);

CREATE INDEX refunds_expense_idx ON refunds
	(owner_id, expense_id, received_on, id);

CREATE INDEX refunds_active_period_idx ON refunds
	(owner_id, received_on, id) WHERE deleted_at IS NULL;

CREATE INDEX audit_entity_idx ON audit_entries
	(owner_id, entity_type, entity_id, recorded_at, id);

CREATE INDEX audit_operation_idx ON audit_entries
	(owner_id, operation_id, id);

CREATE INDEX credentials_principal_idx ON agent_credentials
	(owner_id, principal_id);

CREATE INDEX classification_batches_run_idx ON classification_batches
	(owner_id, run_id, created_at, id);
