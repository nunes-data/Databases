create database coal_tracking;

use coal_tracking;

create table tipo_lenha(
	codigo int primary key not null,
	designacao varchar(30) not null
)

create table estado_lenha(
	codigo int primary key not null,
	designacao varchar(30) not null
)

create table carvao(
	codigo_tipo int primary key not null,
	designacao varchar(30) not null
)

create table empresa(
	codigo int primary key not null,
	nome varchar(20) unique not null,
	telefone int unique not null,
	localizacao varchar(20)
)

create table forno(
	num_serie int primary key not null,
	capacidade_max float not null,
	fk1_codigo_empresa int not null,
	constraint fk1_codigo_empresa foreign key (fk1_codigo_empresa) references empresa(codigo)
)


create table pessoa(
	nif int primary key not null,
	nome varchar(20) not null,
	telefone int,
	email varchar(30),
	fk2_codigo_empresa int not null,
	constraint fk2_codigo_empresa foreign key (fk2_codigo_empresa) references empresa(codigo) 
)

create table contabilista(
	nif_contabilista int primary key not null,
	num_ordem int unique not null,
	custo float,
	constraint nif_contabilista foreign key (nif_contabilista) references pessoa(nif)
)

create table empregado(
	nif_empregado int primary key not null,
	remuneracao float,
	horas_trabalho float,
	constraint nif_empregado foreign key (nif_empregado) references pessoa(nif)
)

create table empresario(
	nif_empresario int primary key not null,
	domicilio_fiscal varchar(30) not null,
	cae varchar(20) not null,
	nif_contab int not null,
	constraint nif_contab foreign key (nif_contab) references contabilista(nif_contabilista)
)

create table contrato(
	id_contrato int primary key not null,
	designacao varchar(30) not null,
	data_inicial date not null,
	data_resc date,
	nif_empreg int not null,
	constraint nif_empreg foreign key (nif_empreg) references empregado(nif_empregado)
)

create table seguranca_social(
	niss int primary key not null,
	valor float not null,
	nif_emp int not null,
	data_pagamento_seg_social date not null,
	constraint nif_emp foreign key (nif_emp) references empresario(nif_empresario)
)

create table seguro(
	apolice int primary key not null,
	data_sub date not null,
	data_vencimento date not null,
	valor float,
	nif_emp2 int not null,
	constraint nif_emp2 foreign key (nif_emp2) references empresario(nif_empresario)
)

create table armazem(
	codigo int primary key not null,
	capacidade_max float not null,
	localizacao varchar(20) not null,
	designacao varchar(30),
	codigo_empresa int not null,
	constraint codigo_empresa foreign key (codigo_empresa) references empresa(codigo)
)

create table fornecedor(
	nif_fornecedor int primary key not null,
	atividade varchar(20) not null,
	codigo_armz int not null,
	constraint nif_fornecedor foreign key (nif_fornecedor) references pessoa(nif),
	constraint codigo_armz foreign key (codigo_armz) references armazem(codigo)
)

create table armazem_carvao(
	codigo_armz_carvao int primary key not null,
	quantidade_carvao float,
	constraint codigo_armz_carvao foreign key (codigo_armz_carvao) references armazem(codigo)
)

create table armazem_recursos(
	codigo_armz_recursos int primary key not null,
	quantidade_lenha float,
	quantidade_embalagens float,
	renda float,
	constraint codigo_armz_recursos foreign key (codigo_armz_recursos) references armazem(codigo)
)

create table recurso(
	codigo int primary key not null,
	designacao varchar(10) not null,
	codigo_armz_rec int not null,
	constraint codigo_armz_rec foreign key (codigo_armz_rec) references armazem_recursos(codigo_armz_recursos)
)

create table lenha(
	codigo_lenha int primary key not null,
	preco float not null,
	codigo_tipo int not null,
	codigo_estado int not null
	constraint codigo_lenha foreign key (codigo_lenha) references recurso(codigo),
	constraint codigo_tipo foreign key (codigo_tipo) references tipo_lenha(codigo),
	constraint codigo_estado foreign key (codigo_estado) references estado_lenha(codigo)
)

create table material_emb(
	codigo int primary key not null,
	designacao varchar(30) not null
)

create table capacidade_emb(
	codigo int primary key not null,
	designacao varchar(30) not null
)

create table embalagem(
	codigo_emb int primary key not null,
	codigo_capacidade int not null,
	codigo_material int not null,
	preco float,
	constraint codigo_emb foreign key (codigo_emb) references recurso(codigo),
	constraint codigo_capacidade foreign key (codigo_capacidade) references capacidade_emb(codigo),
	constraint codigo_material foreign key (codigo_material) references material_emb(codigo)
)

create table cliente(
	nif_cliente int primary key not null,
	codigo_empresa_cliente int not null,
	constraint nif_cliente foreign key (nif_cliente) references pessoa(nif),
	constraint codigo_empresa_cliente foreign key (codigo_empresa_cliente) references empresa(codigo)
)

create table encomenda(
	referencia int primary key not null,
	nif_cliente_enc int unique not null,
	quantidade int not null,
	data_encomenda date not null,
	constraint nif_cliente_enc foreign key (nif_cliente_enc) references pessoa(nif)
)

create table estado_encomenda(
	referencia_enc int primary key not null,
	codigo_estado int not null,
	designacao varchar(30) not null,
	constraint referencia_enc foreign key (referencia_enc) references encomenda(referencia)
)

create table fornada(
	codigo int primary key not null,
	data_inicio date not null,
	data_fim date,
	quantidade_lenha float not null,
	quantidade_carvao float,
	codigo_lenha_forn int not null,
	num_serie_forno int not null,
	codigo_arm int not null
	constraint codigo_lenha_forn foreign key (codigo_lenha_forn) references lenha(codigo_lenha),
	constraint num_serie_forno foreign key (num_serie_forno) references forno(num_serie),
	constraint codigo_arm foreign key (codigo_arm) references armazem_carvao(codigo_armz_carvao)
)

create table produto_final(
	codigo_tipo_carv int not null,
	codigo_emb_produto int not null,
	preco float not null,
	referencia_encom int unique not null,
	primary key (codigo_tipo_carv, codigo_emb_produto),
	constraint codigo_emb_produto foreign key (codigo_emb_produto) references embalagem(codigo_emb),
	constraint codigo_tipo_carv foreign key (codigo_tipo_carv) references carvao(codigo_tipo),
	constraint referencia_encom foreign key (referencia_encom) references encomenda(referencia)
)

create table fatura(
	num_fatura int primary key not null,
	nif_cliente_fatura int unique not null,
	data_faturacao date not null,
	nome_empresa varchar(20) unique not null,
	telefone_empresa int unique not null,
	iva float not null,
	incidencia float not null,
	local_carga varchar(20) not null,
	local_descarga varchar(20) not null,
	preco float not null,
	valor_total float not null,
	referencia_encomenda_fatura int not null,
	constraint nif_cliente_fatura foreign key (nif_cliente_fatura) references cliente(nif_cliente),
	constraint nome_empresa foreign key (nome_empresa) references empresa(nome),
	constraint telefone_empresa foreign key (telefone_empresa) references empresa(telefone),
	constraint referencia_encomenda_fatura foreign key (referencia_encomenda_fatura) references encomenda(referencia)
)

create table recibo(
	num_recibo int primary key not null,
	numero_fatura int unique not null,
	data_emissao date not null,
	constraint numero_fatura foreign key (numero_fatura) references fatura(num_fatura)
)

create table pagamento(
	referencia int primary key not null,
	num_recibo int unique not null,
	montante float not null,
	metodo varchar(20) not null,
	data_pagamento date not null,
	nif_cliente_pagamento int unique not null,
	constraint num_recibo foreign key (num_recibo) references recibo(num_recibo),
	constraint nif_cliente_pagamento foreign key (nif_cliente_pagamento) references cliente(nif_cliente)
)