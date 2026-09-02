--------------------------------------------------------------------------------
-- Traduzido da versao Oracle (db/migration/oracle) para T-SQL / Azure SQL.
-- Conteudo dos dados identico; muda apenas o dialeto:
--   DATE 'aaaa-mm-dd' -> 'aaaa-mm-dd'   (T-SQL converte implicitamente)
--   COMMIT             -> removido      (transacao gerenciada pelo Flyway)
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- V4 - PETS DA TUTORA INICIAL E CONSULTAS EM TODOS OS ESTADOS DO FLUXO
--------------------------------------------------------------------------------

INSERT INTO PET (ID_PET, NOME, ESPECIE, RACA, DATA_NASCIMENTO, SEXO, ID_TUTOR) VALUES (1,'Thor','Cachorro','Labrador','2022-03-15','M',1);
INSERT INTO PET (ID_PET, NOME, ESPECIE, RACA, DATA_NASCIMENTO, SEXO, ID_TUTOR) VALUES (2,'Luna','Gato','Siames','2021-07-02','F',1);
INSERT INTO PET (ID_PET, NOME, ESPECIE, RACA, DATA_NASCIMENTO, SEXO, ID_TUTOR) VALUES (3,'Mel','Cachorro','Poodle','2023-01-20','F',1);
INSERT INTO PET (ID_PET, NOME, ESPECIE, RACA, DATA_NASCIMENTO, SEXO, ID_TUTOR) VALUES (4,'Simba','Gato','Persa','2020-11-08','M',1);
INSERT INTO PET (ID_PET, NOME, ESPECIE, RACA, DATA_NASCIMENTO, SEXO, ID_TUTOR) VALUES (5,'Nina','Cachorro','Shih Tzu','2023-06-30','F',1);

-- Fila de aprovacao do veterinario
INSERT INTO CONSULTA (ID_CONSULTA, ID_PET, ID_VETERINARIO, DATA_CONSULTA, TIPO_CONSULTA, DIAGNOSTICO, STATUS, DATA_SOLICITACAO, MOTIVO_RECUSA)
VALUES (1, 1, 1, '2026-09-10', 'Teleconsulta - Dermatologia', NULL, 'SOLICITADA', '2026-08-20', NULL);
INSERT INTO CONSULTA (ID_CONSULTA, ID_PET, ID_VETERINARIO, DATA_CONSULTA, TIPO_CONSULTA, DIAGNOSTICO, STATUS, DATA_SOLICITACAO, MOTIVO_RECUSA)
VALUES (2, 2, 2, '2026-09-12', 'Teleconsulta - Retorno', NULL, 'SOLICITADA', '2026-08-21', NULL);
INSERT INTO CONSULTA (ID_CONSULTA, ID_PET, ID_VETERINARIO, DATA_CONSULTA, TIPO_CONSULTA, DIAGNOSTICO, STATUS, DATA_SOLICITACAO, MOTIVO_RECUSA)
VALUES (3, 3, 1, '2026-09-15', 'Teleconsulta - Checkup', NULL, 'SOLICITADA', '2026-08-21', NULL);

-- Ja aprovada, aguardando atendimento
INSERT INTO CONSULTA (ID_CONSULTA, ID_PET, ID_VETERINARIO, DATA_CONSULTA, TIPO_CONSULTA, DIAGNOSTICO, STATUS, DATA_SOLICITACAO, MOTIVO_RECUSA)
VALUES (4, 4, 3, '2026-09-05', 'Teleconsulta - Cardiologia', NULL, 'AGENDADA', '2026-08-15', NULL);

-- Ciclo completo, com diagnostico emitido
INSERT INTO CONSULTA (ID_CONSULTA, ID_PET, ID_VETERINARIO, DATA_CONSULTA, TIPO_CONSULTA, DIAGNOSTICO, STATUS, DATA_SOLICITACAO, MOTIVO_RECUSA)
VALUES (5, 5, 5, '2026-08-01', 'Teleconsulta - Checkup', 'Animal saudavel, vacinacao em dia. Retorno em 6 meses.', 'REALIZADA', '2026-07-25', NULL);

-- Recusada, com justificativa
INSERT INTO CONSULTA (ID_CONSULTA, ID_PET, ID_VETERINARIO, DATA_CONSULTA, TIPO_CONSULTA, DIAGNOSTICO, STATUS, DATA_SOLICITACAO, MOTIVO_RECUSA)
VALUES (6, 1, 4, '2026-08-10', 'Teleconsulta - Ortopedia', NULL, 'RECUSADA', '2026-08-05', 'Caso ortopedico exige exame presencial com raio-x.');

