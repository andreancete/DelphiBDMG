/* =============================================================================
   01 - Criação do banco e do usuário de aplicação (SQL Server 2017+)
   Execute conectado como administrador (ex.: sa ou Windows Authentication).
   ============================================================================= */

IF DB_ID(N'BDMG_TAREFAS') IS NULL
    CREATE DATABASE BDMG_TAREFAS;
GO

/* Login com permissão mínima para a API (princípio do menor privilégio).
   TROQUE a senha antes de executar e replique-a em BANCO_SENHA (backend\src\config\ConfiguracaoBanco.pas).
   Necessário apenas se BANCO_AUTENTICACAO_WINDOWS = False. */
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'bdmg_api')
    CREATE LOGIN bdmg_api WITH PASSWORD = N'Troque-Esta-Senha#2026', CHECK_POLICY = ON;
GO

USE BDMG_TAREFAS;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'bdmg_api')
    CREATE USER bdmg_api FOR LOGIN bdmg_api;
GO

/* A API só precisa ler e gravar dados; não pode alterar a estrutura (DDL). */
ALTER ROLE db_datareader ADD MEMBER bdmg_api;
ALTER ROLE db_datawriter ADD MEMBER bdmg_api;
GO
