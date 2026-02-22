use coal_tracking;

insert into empresa(codigo, nome, telefone, localizacao)
values (1, 'Carla Sofia', 913489320, 'Santana do Mato');

insert into pessoa(nif, nome, telefone, email, fk2_codigo_empresa)
values (264439430, 'José Nunes', 915562981, 'livre@gmail.com', 1),
(12345, 'Cliente1', 999999999, 'chega@gmail.com', 1);

insert into empregado (nif_empregado, remuneracao, horas_trabalho)
values (264439430, 1000, 176);

insert into cliente(nif_cliente, codigo_empresa_cliente)
values (12345, 1);

insert into estado_encomenda (codigo_estado, designacao)
values (0, 'A processar'), (1, 'Entregue');

insert into encomenda (referencia, valor_total_encomenda, estado_enc)
values (1, 1000, 0);

insert into historico_encomenda_cliente(nif_cliente_encomenda, ref_encomenda, data_encomenda)
values (12345, 1, '12/05/2025')

insert into pessoa(nif, nome, telefone, email, fk2_codigo_empresa)
values (123456, 'Contabilista1', 888888888, 'il@gmail.com', 1);

insert into contabilista (nif_contabilista, num_ordem, custo)
values (123456, 111, 90);

insert into pessoa(nif, nome, telefone, email, fk2_codigo_empresa)
values (1234567, 'Empresario1', 111111111, 'cds@gmail.com', 1);

insert into empresario (nif_empresario, domicilio_fiscal, cae, nif_contab)
values (1234567, 'Santana do Mato', 12345, 123456);

insert into seguranca_social (niss, valor, data_pagamento_seg_social, nif_emp)
values (123, 100, '07/14/2003', 1234567);

insert into seguro (apolice, data_sub, data_vencimento, valor, nif_emp2)
values (456, '09/11/2001', '04/26/2025', 30, 1234567);

insert into contrato (id_contrato, designacao, data_inicial, data_resc, nif_empreg)
values (1, 'Full Time', '08/08/2016', '08/08/2030', 264439430);


insert into remuneracao (nif_empregado_remun, data_remuneracao, valor_pago, horas_pagas)
values (264439430, '08/01/2020', 1000, 176), (264439430, '09/01/2020', 1000, 176), (264439430, '10/01/2020', 1000, 176);

insert into forno(num_serie, capacidade_max, fk1_codigo_empresa)
values	(1, 10000, 1),
		(2, 10000, 1),
		(3, 10000, 1),
		(4, 10000, 1),
		(5, 10000, 1),
		(6, 10000, 1),
		(7, 10000, 1),
		(8, 10000, 1),
		(9, 10000, 1),
		(10, 10000, 1);

insert into capacidade_emb(codigo, designacao)
values	(1, '5 kg'), -- meter isto como int ou como varchar pq para editar convem sr um int maybe??
		(2, '13 kg');

insert into material_emb(codigo, designacao)
values	(1, 'rafia'),
		(2, 'papel');

insert into estado_lenha(codigo, designacao)
values	(1, 'humida'),
		(2, 'seca');

insert into tipo_lenha(codigo, designacao)
values	(1, 'azinho'),
		(2, 'eucalipto'),
		(3, 'sobro');

insert into armazem(codigo, capacidade_max, localizacao, designacao, codigo_empresa)
values(1, 15000, 'Santana do Mato', 'Armazém de Carvão', 1),
	  (2, 100000, 'Cortiçadas de Lavre', 'Armazém de Recursos', 1);

insert into armazem_carvao(codigo_armz_carvao, quantidade_carvao)
values(1, 0);

insert into armazem_recursos(codigo_armz_recursos, quantidade_embalagens, quantidade_lenha, renda)
values(2, 0, 0, 150);

insert into recurso(codigo, designacao, codigo_armz_rec)
values	(1, 'embalagem papel 5kg', 2),
		(2, 'embalagem papel 13kg', 2),
		(3, 'embalagem rafia 5kg', 2),
		(4, 'embalagem rafia 13kg', 2),
		(5, 'lenha azinho seca', 2),
		(6, 'lenha azinho humida', 2),
		(7, 'lenha eucalipto seca', 2),
		(8, 'lenha eucalipto humida', 2),
		(9, 'lenha sobro seca', 2),
		(10, 'lenha sobro humida', 2);

insert into embalagem(codigo_emb, codigo_capacidade, codigo_material, preco, stock_embalagem)
values	(1, 1, 1, 0.24, 400),
		(2, 2, 1, 0.38, 500),
		(3, 1, 2, 0.22, 600),
		(4, 2, 2, 0.35, 700);

insert into lenha(codigo_lenha, codigo_estado, codigo_tipo, preco, stock_lenha)
values	(5, 1, 1, 100, 50), -- 100 euros/tonelada
		(6, 2, 1, 100, 100),
		(7, 1, 2, 45, 150), -- 45 euros/tonelada 
		(8, 2, 2, 45, 200),
		(9, 1, 3, 70, 250), -- 70 euros/tonelada
		(10, 2, 3, 70, 300);

insert into fornada(codigo, data_inicio, data_fim, quantidade_lenha, quantidade_carvao, codigo_lenha_forn, num_serie_forno, codigo_arm)
values	(1,'05/06/2025','12/06/2025',10,2,5,1,1);

insert carvao(codigo_tipo, designacao, stock)
values	(1, 'Carvão de Azinho', 2000),
		(2, 'Carvão de Eucalipto', 500),
		(3, 'Carvão de Sobro', 5000);

insert produto_final(codigo_tipo_carv, codigo_emb_produto, referencia_encom, preco_unidade, quantidade, preco)
values	(1, 2, 1, 11, 10, 110);

insert fatura(num_fatura, nif_cliente_fatura, data_faturacao, nome_empresa, telefone_empresa, iva, incidencia, local_carga, local_descarga, preco, valor_total, referencia_encomenda_fatura)
values	(418000, 12345, '05/12/2025', 'Carla Sofia', 913489320, 23, 25.3, 'Santana do Mato', 'Paredes, Porto', 110, 135.3, 1);

insert recibo(num_recibo, numero_fatura, data_emissao)
values	(98111, 418000, '07/12/2025');

insert pagamento(referencia, num_recibo, montante, metodo, data_pagamento, nif_cliente_pagamento)
values	(1, 98111, 135.3, 'multibanco', '07/12/2025', 12345);

insert into encomenda (referencia, valor_total_encomenda, estado_enc)
values (2, 2000, 1);

insert into historico_encomenda_cliente(nif_cliente_encomenda, ref_encomenda, data_encomenda)
values (12345, 2, '12/07/2025');

insert into encomenda (referencia, valor_total_encomenda, estado_enc)
values (3, 2000, 1);

insert into historico_encomenda_cliente(nif_cliente_encomenda, ref_encomenda, data_encomenda)
values (12345, 3, '05/04/2025');

use coal_tracking
insert into admin_login(username, login_password, created_date, last_login, is_active)
values('Jose', 'abc123', '02/06/2025', NULL, 1);