/* =============================================================================
   02 - Estrutura de dados das tarefas
   ============================================================================= */

USE BDMG_TAREFAS;
GO

IF OBJECT_ID(N'dbo.tarefas', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.tarefas
    (
        id              BIGINT          IDENTITY(1, 1) NOT NULL,
        titulo          NVARCHAR(150)   NOT NULL,
        descricao       NVARCHAR(1000)  NULL,
        prioridade      TINYINT         NOT NULL CONSTRAINT df_tarefas_prioridade DEFAULT (2),
        status          VARCHAR(20)     NOT NULL CONSTRAINT df_tarefas_status DEFAULT ('PENDENTE'),
        data_conclusao  DATETIME2(0)    NULL,
        criado_em       DATETIME2(0)    NOT NULL CONSTRAINT df_tarefas_criado_em DEFAULT (SYSDATETIME()),
        atualizado_em   DATETIME2(0)    NOT NULL CONSTRAINT df_tarefas_atualizado_em DEFAULT (SYSDATETIME()),
        excluido_em     DATETIME2(0)    NULL,

        CONSTRAINT pk_tarefas PRIMARY KEY CLUSTERED (id),

        -- 1 = Baixa, 2 = Média, 3 = Alta, 4 = Urgente
        CONSTRAINT ck_tarefas_prioridade CHECK (prioridade BETWEEN 1 AND 4),

        CONSTRAINT ck_tarefas_status CHECK (status IN ('PENDENTE', 'EM_ANDAMENTO', 'CONCLUIDA', 'CANCELADA')),

        -- Garante consistência: só tarefa concluída tem data de conclusão
        CONSTRAINT ck_tarefas_data_conclusao CHECK (
            (status = 'CONCLUIDA' AND data_conclusao IS NOT NULL) OR
            (status <> 'CONCLUIDA' AND data_conclusao IS NULL)
        ),

        CONSTRAINT ck_tarefas_titulo CHECK (LEN(LTRIM(RTRIM(titulo))) >= 3)
    );
END
GO

/* Índice filtrado que cobre a listagem por status e as estatísticas
   (status + data_conclusao na chave, prioridade incluída), ignorando
   linhas excluídas logicamente. */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'idx_tarefas_status_conclusao')
    CREATE NONCLUSTERED INDEX idx_tarefas_status_conclusao
        ON dbo.tarefas (status, data_conclusao)
        INCLUDE (prioridade)
        WHERE excluido_em IS NULL;
GO
