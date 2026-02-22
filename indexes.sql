use coal_tracking;

CREATE INDEX idx_empregado_nome ON pessoa(nome);

CREATE INDEX idx_remuneracao_empregado_data ON remuneracao(nif_empregado_remun, data_remuneracao);

CREATE INDEX idx_encomenda_estado ON encomenda(estado_enc);

CREATE INDEX idx_historico_encomenda_data_estado ON historico_encomenda_cliente(data_encomenda); 

CREATE INDEX idx_fornada_data_inicio ON fornada(data_inicio);

CREATE INDEX idx_fornada_forno ON fornada(num_serie_forno);