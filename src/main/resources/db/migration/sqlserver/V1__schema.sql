--------------------------------------------------------------------------------
-- V1 - SCHEMA COMPLETO DO KURAVET (Azure SQL Database / perfil azure)
--
-- Esta pasta (db/migration/sqlserver) e usada apenas pelo perfil "azure",
-- que roda contra o Azure SQL Database (PaaS). O perfil "oracle" continua
-- usando db/migration/oracle sem nenhuma alteracao, preservando a entrega
-- de Java Advanced.
--
-- Diferenca proposital em relacao a versao Oracle: aqui a V1 ja nasce com
-- as colunas que la foram adicionadas pela V4 (DATA_SOLICITACAO e
-- MOTIVO_RECUSA). Sao bancos distintos, cada um com seu proprio historico
-- do Flyway, entao replicar um ALTER TABLE que nunca existiu neste banco
-- so adicionaria ruido.
--
-- Os comentarios de tabela e coluna usam sp_addextendedproperty, que e o
-- equivalente do COMMENT ON no SQL Server. Sao lidos pela view
-- sys.extended_properties (consulta no final deste arquivo).
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- TUTOR
--------------------------------------------------------------------------------
CREATE TABLE TUTOR (
    ID_TUTOR        BIGINT          NOT NULL,
    NOME            VARCHAR(100)    NOT NULL,
    CPF             VARCHAR(14)     NOT NULL,
    TELEFONE        VARCHAR(20),
    EMAIL           VARCHAR(100),
    ENDERECO        VARCHAR(200),
    DATA_CADASTRO   DATE            NOT NULL CONSTRAINT KV_DF_TUTOR_DTCAD DEFAULT CAST(GETDATE() AS DATE),
    CONSTRAINT KV_PK_TUTOR PRIMARY KEY (ID_TUTOR),
    CONSTRAINT KV_UQ_TUTOR_CPF UNIQUE (CPF)
);
GO

--------------------------------------------------------------------------------
-- VETERINARIO
--------------------------------------------------------------------------------
CREATE TABLE VETERINARIO (
    ID_VETERINARIO  BIGINT          NOT NULL,
    NOME            VARCHAR(100)    NOT NULL,
    CRMV            VARCHAR(20)     NOT NULL,
    ESPECIALIDADE   VARCHAR(60),
    TELEFONE        VARCHAR(20),
    EMAIL           VARCHAR(100),
    CONSTRAINT KV_PK_VET PRIMARY KEY (ID_VETERINARIO),
    CONSTRAINT KV_UQ_VET_CRMV UNIQUE (CRMV)
);
GO

--------------------------------------------------------------------------------
-- PET - primeira tabela do CORE usada no CRUD da entrega de DevOps
--------------------------------------------------------------------------------
CREATE TABLE PET (
    ID_PET          BIGINT          NOT NULL,
    NOME            VARCHAR(60)     NOT NULL,
    ESPECIE         VARCHAR(30)     NOT NULL,
    RACA            VARCHAR(60),
    DATA_NASCIMENTO DATE            NOT NULL,
    SEXO            CHAR(1)         NOT NULL,
    ID_TUTOR        BIGINT          NOT NULL,
    CONSTRAINT KV_PK_PET PRIMARY KEY (ID_PET),
    CONSTRAINT KV_CK_PET_SEXO CHECK (SEXO IN ('M','F')),
    CONSTRAINT KV_FK_PET_TUTOR FOREIGN KEY (ID_TUTOR) REFERENCES TUTOR(ID_TUTOR)
);
GO

--------------------------------------------------------------------------------
-- CONSULTA - segunda tabela do CORE, relacionada a PET
--------------------------------------------------------------------------------
CREATE TABLE CONSULTA (
    ID_CONSULTA       BIGINT        NOT NULL,
    ID_PET            BIGINT        NOT NULL,
    ID_VETERINARIO    BIGINT        NOT NULL,
    DATA_CONSULTA     DATE          NOT NULL,
    TIPO_CONSULTA     VARCHAR(40)   NOT NULL,
    DIAGNOSTICO       VARCHAR(400),
    STATUS            VARCHAR(20)   NOT NULL CONSTRAINT KV_DF_CONS_STATUS DEFAULT 'SOLICITADA',
    DATA_SOLICITACAO  DATE          NOT NULL CONSTRAINT KV_DF_CONS_DTSOL DEFAULT CAST(GETDATE() AS DATE),
    MOTIVO_RECUSA     VARCHAR(300),
    CONSTRAINT KV_PK_CONSULTA PRIMARY KEY (ID_CONSULTA),
    CONSTRAINT KV_CK_CONS_STATUS
        CHECK (STATUS IN ('SOLICITADA','AGENDADA','REALIZADA','CANCELADA','RECUSADA')),
    -- O motivo existe se, e somente se, a solicitacao foi recusada.
    CONSTRAINT KV_CK_CONS_MOTIVO
        CHECK ( (STATUS =  'RECUSADA' AND MOTIVO_RECUSA IS NOT NULL)
             OR (STATUS <> 'RECUSADA' AND MOTIVO_RECUSA IS NULL) ),
    -- O diagnostico existe se, e somente se, a consulta foi realizada.
    CONSTRAINT KV_CK_CONS_DIAGNOSTICO
        CHECK ( (STATUS =  'REALIZADA' AND DIAGNOSTICO IS NOT NULL)
             OR (STATUS <> 'REALIZADA' AND DIAGNOSTICO IS NULL) ),
    CONSTRAINT KV_FK_CONS_PET FOREIGN KEY (ID_PET) REFERENCES PET(ID_PET),
    CONSTRAINT KV_FK_CONS_VET FOREIGN KEY (ID_VETERINARIO) REFERENCES VETERINARIO(ID_VETERINARIO)
);
GO

--------------------------------------------------------------------------------
-- USUARIO - credenciais de acesso (API mobile e portal web)
--------------------------------------------------------------------------------
CREATE TABLE USUARIO (
    ID_USUARIO      BIGINT          NOT NULL,
    USERNAME        VARCHAR(60)     NOT NULL,
    SENHA           VARCHAR(100)    NOT NULL,
    PERFIL          VARCHAR(20)     NOT NULL,
    ID_TUTOR        BIGINT,
    CONSTRAINT KV_PK_USUARIO PRIMARY KEY (ID_USUARIO),
    CONSTRAINT KV_UQ_USUARIO_USERNAME UNIQUE (USERNAME),
    CONSTRAINT KV_CK_USU_PERFIL CHECK (PERFIL IN ('TUTOR','VETERINARIO')),
    CONSTRAINT KV_CK_USU_TUTOR CHECK (
        (PERFIL = 'TUTOR' AND ID_TUTOR IS NOT NULL) OR
        (PERFIL = 'VETERINARIO' AND ID_TUTOR IS NULL)
    ),
    CONSTRAINT KV_FK_USU_TUTOR FOREIGN KEY (ID_TUTOR) REFERENCES TUTOR(ID_TUTOR)
);
GO

--------------------------------------------------------------------------------
-- INDICE DE APOIO
-- Consulta mais frequente da API: historico de um pet em ordem cronologica.
--------------------------------------------------------------------------------
CREATE INDEX KV_IX_CONSULTA_PET_DATA ON CONSULTA (ID_PET, DATA_CONSULTA DESC);
GO

--------------------------------------------------------------------------------
-- SEQUENCES PARA GERACAO DE PK
-- Os seeds usam IDs baixos manualmente; as sequences comecam em 11
-- (100 para USUARIO) para nao colidir com eles.
--------------------------------------------------------------------------------
CREATE SEQUENCE SEQ_TUTOR       AS BIGINT START WITH 11  INCREMENT BY 1 NO CYCLE;
GO
CREATE SEQUENCE SEQ_VETERINARIO AS BIGINT START WITH 11  INCREMENT BY 1 NO CYCLE;
GO
CREATE SEQUENCE SEQ_PET         AS BIGINT START WITH 11  INCREMENT BY 1 NO CYCLE;
GO
CREATE SEQUENCE SEQ_CONSULTA    AS BIGINT START WITH 11  INCREMENT BY 1 NO CYCLE;
GO
CREATE SEQUENCE SEQ_USUARIO     AS BIGINT START WITH 100 INCREMENT BY 1 NO CYCLE;
GO

--------------------------------------------------------------------------------
-- COMENTARIOS DE TABELAS E COLUNAS (equivalente ao COMMENT ON)
--------------------------------------------------------------------------------
-- Comentarios da tabela TUTOR
EXEC sys.sp_addextendedproperty @name=N'MS_Description',
     @value=N'Responsavel legal pelo animal. Ponto de contato da clinica na jornada de cuidado continuo.',
     @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'TUTOR';
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description',
     @value=N'Identificador unico do tutor. Chave primaria.',
     @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'TUTOR',
     @level2type=N'COLUMN', @level2name=N'ID_TUTOR';
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description',
     @value=N'Nome completo do tutor.',
     @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'TUTOR',
     @level2type=N'COLUMN', @level2name=N'NOME';
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description',
     @value=N'CPF do tutor. Unico, evita cadastro duplicado.',
     @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'TUTOR',
     @level2type=N'COLUMN', @level2name=N'CPF';
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description',
     @value=N'Telefone de contato para lembretes e retornos.',
     @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'TUTOR',
     @level2type=N'COLUMN', @level2name=N'TELEFONE';
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description',
     @value=N'E-mail de contato do tutor.',
     @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'TUTOR',
     @level2type=N'COLUMN', @level2name=N'EMAIL';
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description',
     @value=N'Endereco do tutor, usado para atendimento domiciliar.',
     @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'TUTOR',
     @level2type=N'COLUMN', @level2name=N'ENDERECO';
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description',
     @value=N'Data de entrada do tutor na plataforma. Base do calculo de retencao.',
     @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'TUTOR',
     @level2type=N'COLUMN', @level2name=N'DATA_CADASTRO';
GO

-- Comentarios da tabela VETERINARIO
EXEC sys.sp_addextendedproperty @name=N'MS_Description',
     @value=N'Profissional habilitado que atende as teleconsultas e emite diagnosticos.',
     @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'VETERINARIO';
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description',
     @value=N'Identificador unico do veterinario. Chave primaria.',
     @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'VETERINARIO',
     @level2type=N'COLUMN', @level2name=N'ID_VETERINARIO';
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description',
     @value=N'Nome do profissional.',
     @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'VETERINARIO',
     @level2type=N'COLUMN', @level2name=N'NOME';
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description',
     @value=N'Registro no Conselho Regional de Medicina Veterinaria. Unico.',
     @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'VETERINARIO',
     @level2type=N'COLUMN', @level2name=N'CRMV';
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description',
     @value=N'Area de atuacao. Direciona a triagem ao profissional certo.',
     @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'VETERINARIO',
     @level2type=N'COLUMN', @level2name=N'ESPECIALIDADE';
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description',
     @value=N'Telefone de contato do profissional.',
     @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'VETERINARIO',
     @level2type=N'COLUMN', @level2name=N'TELEFONE';
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description',
     @value=N'E-mail de contato do profissional.',
     @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'VETERINARIO',
     @level2type=N'COLUMN', @level2name=N'EMAIL';
GO

-- Comentarios da tabela PET
EXEC sys.sp_addextendedproperty @name=N'MS_Description',
     @value=N'Animal acompanhado pela plataforma. Base do historico longitudinal de saude.',
     @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'PET';
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description',
     @value=N'Identificador unico do pet. Chave primaria.',
     @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'PET',
     @level2type=N'COLUMN', @level2name=N'ID_PET';
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description',
     @value=N'Nome do animal informado pelo tutor.',
     @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'PET',
     @level2type=N'COLUMN', @level2name=N'NOME';
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description',
     @value=N'Especie do animal. Define qual protocolo preventivo e aplicavel.',
     @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'PET',
     @level2type=N'COLUMN', @level2name=N'ESPECIE';
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description',
     @value=N'Raca do animal. Usada para prever predisposicoes clinicas por linhagem.',
     @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'PET',
     @level2type=N'COLUMN', @level2name=N'RACA';
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description',
     @value=N'Data de nascimento. Determina a fase de vida e a periodicidade dos check-ups.',
     @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'PET',
     @level2type=N'COLUMN', @level2name=N'DATA_NASCIMENTO';
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description',
     @value=N'Sexo do animal: M (macho) ou F (femea).',
     @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'PET',
     @level2type=N'COLUMN', @level2name=N'SEXO';
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description',
     @value=N'Chave estrangeira para TUTOR. Define quem responde pelo animal.',
     @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'PET',
     @level2type=N'COLUMN', @level2name=N'ID_TUTOR';
GO

-- Comentarios da tabela CONSULTA
EXEC sys.sp_addextendedproperty @name=N'MS_Description',
     @value=N'Evento clinico de um pet. Cobre solicitacao, aprovacao, atendimento e diagnostico.',
     @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'CONSULTA';
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description',
     @value=N'Identificador unico do atendimento. Chave primaria.',
     @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'CONSULTA',
     @level2type=N'COLUMN', @level2name=N'ID_CONSULTA';
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description',
     @value=N'Chave estrangeira para PET. Define a qual animal o atendimento pertence.',
     @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'CONSULTA',
     @level2type=N'COLUMN', @level2name=N'ID_PET';
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description',
     @value=N'Chave estrangeira para VETERINARIO. Profissional responsavel.',
     @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'CONSULTA',
     @level2type=N'COLUMN', @level2name=N'ID_VETERINARIO';
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description',
     @value=N'Data marcada ou realizada do atendimento.',
     @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'CONSULTA',
     @level2type=N'COLUMN', @level2name=N'DATA_CONSULTA';
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description',
     @value=N'Natureza do atendimento. Distingue cuidado preventivo de demanda reativa.',
     @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'CONSULTA',
     @level2type=N'COLUMN', @level2name=N'TIPO_CONSULTA';
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description',
     @value=N'Avaliacao clinica. Preenchido apenas quando o status e REALIZADA.',
     @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'CONSULTA',
     @level2type=N'COLUMN', @level2name=N'DIAGNOSTICO';
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description',
     @value=N'Estado na maquina de estados do atendimento.',
     @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'CONSULTA',
     @level2type=N'COLUMN', @level2name=N'STATUS';
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description',
     @value=N'Data em que o tutor pediu o atendimento pelo aplicativo.',
     @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'CONSULTA',
     @level2type=N'COLUMN', @level2name=N'DATA_SOLICITACAO';
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description',
     @value=N'Justificativa do veterinario. Preenchido apenas quando o status e RECUSADA.',
     @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'CONSULTA',
     @level2type=N'COLUMN', @level2name=N'MOTIVO_RECUSA';
GO

-- Comentarios da tabela USUARIO
EXEC sys.sp_addextendedproperty @name=N'MS_Description',
     @value=N'Credencial de acesso. Um usuario e tutor (app) ou veterinario (portal).',
     @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'USUARIO';
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description',
     @value=N'Identificador unico do usuario. Chave primaria.',
     @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'USUARIO',
     @level2type=N'COLUMN', @level2name=N'ID_USUARIO';
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description',
     @value=N'Login do usuario. Unico.',
     @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'USUARIO',
     @level2type=N'COLUMN', @level2name=N'USERNAME';
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description',
     @value=N'Hash BCrypt da senha. A senha em texto plano nunca e persistida.',
     @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'USUARIO',
     @level2type=N'COLUMN', @level2name=N'SENHA';
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description',
     @value=N'Papel do usuario: TUTOR ou VETERINARIO. Base do controle de acesso.',
     @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'USUARIO',
     @level2type=N'COLUMN', @level2name=N'PERFIL';
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description',
     @value=N'Chave estrangeira para TUTOR, preenchida somente quando PERFIL = TUTOR.',
     @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'USUARIO',
     @level2type=N'COLUMN', @level2name=N'ID_TUTOR';
GO

--------------------------------------------------------------------------------
-- Consulta para conferir os comentarios gravados:
--
-- SELECT t.name AS TABELA, c.name AS COLUNA, ep.value AS COMENTARIO
-- FROM sys.extended_properties ep
-- JOIN sys.tables t ON t.object_id = ep.major_id
-- LEFT JOIN sys.columns c ON c.object_id = ep.major_id AND c.column_id = ep.minor_id
-- WHERE ep.name = 'MS_Description'
-- ORDER BY t.name, c.column_id;
--------------------------------------------------------------------------------
