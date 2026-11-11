/* =============================================================================
   04 - Desafio SQL: consultas usadas pelo serviço (GET /api/estatisticas/tarefas)
   Mantidas aqui para conferência manual no SSMS / Azure Data Studio.
   ============================================================================= */

USE BDMG_TAREFAS;
GO

/* ---------------------------------------------------------------------------
   Versão usada pela API: os três indicadores em UMA única leitura da tabela
   (agregação condicional). Mesmo SQL de TarefaRepository.pas (SQL_ESTATISTICAS).
   --------------------------------------------------------------------------- */
SELECT COUNT(*) AS total_tarefas,
       ISNULL(CAST(AVG(CASE WHEN status = 'PENDENTE'
                            THEN CAST(prioridade AS DECIMAL(5, 2)) END) AS DECIMAL(5, 2)), 0)
         AS media_prioridade_pendentes,
       ISNULL(SUM(CASE WHEN status = 'CONCLUIDA'
                        AND data_conclusao >= DATEADD(DAY, -7, SYSDATETIME())
                       THEN 1 ELSE 0 END), 0) AS concluidas_ultimos_7_dias,
       SYSDATETIME() AS gerado_em
  FROM dbo.tarefas
 WHERE excluido_em IS NULL;
GO

/* ---------------------------------------------------------------------------
   Mesmos indicadores em consultas separadas (equivalentes, para referência)
   --------------------------------------------------------------------------- */

-- 1) Número total de tarefas
SELECT COUNT(*) AS total_tarefas
  FROM dbo.tarefas
 WHERE excluido_em IS NULL;

-- 2) Média de prioridade das tarefas pendentes
--    CAST evita a divisão inteira: AVG sobre TINYINT devolveria inteiro truncado.
SELECT CAST(AVG(CAST(prioridade AS DECIMAL(5, 2))) AS DECIMAL(5, 2)) AS media_prioridade_pendentes
  FROM dbo.tarefas
 WHERE status = 'PENDENTE'
   AND excluido_em IS NULL;

-- 3) Quantidade de tarefas concluídas nos últimos 7 dias
--    Condição "sargable" (coluna sem função aplicada) para aproveitar o índice.
SELECT COUNT(*) AS concluidas_ultimos_7_dias
  FROM dbo.tarefas
 WHERE status = 'CONCLUIDA'
   AND data_conclusao >= DATEADD(DAY, -7, SYSDATETIME())
   AND excluido_em IS NULL;
GO
