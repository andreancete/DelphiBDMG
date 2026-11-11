/* =============================================================================
   03 - Massa de dados para testes manuais (opcional)
   ============================================================================= */

USE BDMG_TAREFAS;
GO

INSERT INTO dbo.tarefas (titulo, descricao, prioridade, status, data_conclusao, criado_em, atualizado_em)
VALUES
 (N'Configurar ambiente de desenvolvimento', N'Instalar Delphi, boss e dependências do Horse', 3, 'CONCLUIDA', DATEADD(DAY, -2,  SYSDATETIME()), DATEADD(DAY, -5,  SYSDATETIME()), DATEADD(DAY, -2,  SYSDATETIME())),
 (N'Modelar tabela de tarefas',               N'Definir colunas, constraints e índices',        4, 'CONCLUIDA', DATEADD(DAY, -6,  SYSDATETIME()), DATEADD(DAY, -8,  SYSDATETIME()), DATEADD(DAY, -6,  SYSDATETIME())),
 (N'Revisar documentação antiga',             NULL,                                             1, 'CONCLUIDA', DATEADD(DAY, -15, SYSDATETIME()), DATEADD(DAY, -20, SYSDATETIME()), DATEADD(DAY, -15, SYSDATETIME())),
 (N'Implementar endpoints REST',              N'CRUD de tarefas com Horse',                     4, 'EM_ANDAMENTO', NULL, DATEADD(DAY, -3, SYSDATETIME()), DATEADD(DAY, -1, SYSDATETIME())),
 (N'Criar tela VCL de tarefas',               N'Listagem, cadastro e alteração de status',      3, 'PENDENTE', NULL, DATEADD(DAY, -1, SYSDATETIME()), DATEADD(DAY, -1, SYSDATETIME())),
 (N'Escrever testes unitários',               N'DUnitX para a camada de serviço',               2, 'PENDENTE', NULL, SYSDATETIME(), SYSDATETIME()),
 (N'Publicar repositório no GitHub',          NULL,                                             2, 'PENDENTE', NULL, SYSDATETIME(), SYSDATETIME()),
 (N'Estudar relatórios FastReport',           N'Fora do escopo da prova',                       1, 'CANCELADA', NULL, DATEADD(DAY, -4, SYSDATETIME()), DATEADD(DAY, -4, SYSDATETIME()));
GO

/* Resultado esperado em GET /api/estatisticas/tarefas logo após este script:
   total_tarefas = 8 | media_prioridade_pendentes = 2.33 | concluidas_ultimos_7_dias = 2 */
