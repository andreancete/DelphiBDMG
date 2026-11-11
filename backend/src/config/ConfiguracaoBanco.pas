unit ConfiguracaoBanco;

{ Configurações de acesso ao SQL Server, usadas pelas fábricas de conexão
  (Conexao.ADO e Conexao.FireDAC). Edite as constantes e recompile a API. }

interface

const
  // Tecnologia de acesso (ver Conexao.Factory):
  //   'ADO'     = dbGo + MSOLEDBSQL (todas as edições do Delphi, inclusive Community)
  //   'FIREDAC' = driver FireDAC MSSQL (Enterprise/Architect + diretiva FIREDAC_MSSQL)
  BANCO_TIPO_CONEXAO = 'ADO';

  BANCO_SERVIDOR = 'localhost\SQLEXPRESS';
  BANCO_NOME = 'BDMG_TAREFAS';

  // True  = autenticação do Windows (usuário e senha abaixo são ignorados)
  // False = autenticação do SQL Server (exige o modo misto habilitado na instância)
  BANCO_AUTENTICACAO_WINDOWS = True;
  // Usuário e senha em constantes (sem .env) apenas para facilitar a avaliação
  // da prova técnica, como a API_KEY em ConfiguracaoApi.pas. Em produção,
  // credenciais devem vir de variável de ambiente ou cofre de segredos.
  BANCO_USUARIO = 'bdmg_api';
  BANCO_SENHA = 'Troque-Esta-Senha#2026';

  // Timeouts em segundos
  BANCO_TIMEOUT_CONEXAO = 10;
  BANCO_TIMEOUT_COMANDO = 30;

  // Pool de conexões: quantas conexões abertas ficam guardadas para reuso.
  // Reaproveitar evita o custo de abrir uma conexão nova (~1 s) a cada requisição.
  BANCO_POOL_MAXIMO_CONEXOES = 50;
  // Conexão parada no pool por mais tempo que isto é renovada antes do uso (ADO)
  BANCO_POOL_TEMPO_OCIOSO_SEG = 300;

  // Consultas que demorarem mais que isto (ms) são registradas no log como AVISO
  BANCO_LOG_CONSULTA_LENTA_MS = 200;

  // ---------- Somente para BANCO_TIPO_CONEXAO = 'ADO' ----------
  // Microsoft OLE DB Driver for SQL Server
  BANCO_OLEDB_PROVIDER = 'MSOLEDBSQL';
  BANCO_CRIPTOGRAFAR_CONEXAO = False;
  // True aceita o certificado autoassinado da instalação local do SQL Server
  BANCO_CONFIAR_CERTIFICADO_SERVIDOR = True;

  // ---------- Somente para BANCO_TIPO_CONEXAO = 'FIREDAC' ----------
  BANCO_ODBC_DRIVER = 'ODBC Driver 17 for SQL Server';

implementation

end.
