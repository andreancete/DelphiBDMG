unit Conexao.Interfaces;

{ Contratos do padrão ABSTRACT FACTORY para acesso a dados.

  Família de produtos:
    IConexaoFactory  -> fábrica abstrata (uma implementação por tecnologia)
    IConexao         -> conexão aberta com o banco
    IQuery           -> comando SQL parametrizado

  Fábricas concretas disponíveis:
    - TConexaoFactoryADO     (dbGo/ADO + MSOLEDBSQL) - funciona em TODAS as
      edições do Delphi, inclusive Community.
    - TConexaoFactoryFireDAC (FireDAC driver MSSQL) - exige Delphi
      Enterprise/Architect; compilada apenas com a diretiva FIREDAC_MSSQL.

  Os Repositories dependem SOMENTE destas interfaces. Trocar de tecnologia
  (ou injetar um fake em testes) não exige alterar Repository/Service/Controller. }

interface

uses
  System.SysUtils,
  Data.DB;

type
  // Falha ao abrir a conexão (servidor fora do ar, credencial inválida...) -> HTTP 503
  EConexaoException = class(Exception);
  // Erro devolvido pelo banco ao executar um comando -> HTTP 503 (detalhe só no log)
  EBancoDadosException = class(Exception);

  TTipoConexao = (tcADO, tcFireDAC);

  IQuery = interface
    ['{3C2B7F10-5E4A-4D8B-A1C9-6F0E2D3B4C51}']
    procedure DefinirSQL(const ASQL: string);
    procedure ParamTexto(const ANome, AValor: string);
    procedure ParamInteiro(const ANome: string; const AValor: Integer);
    procedure ParamInt64(const ANome: string; const AValor: Int64);
    procedure ParamNulo(const ANome: string; const ATipo: TFieldType);
    // Executa um SELECT (ou INSERT ... OUTPUT) e posiciona no primeiro registro
    procedure Abrir;
    // Executa INSERT/UPDATE/DELETE e devolve a quantidade de linhas afetadas
    function Executar: Integer;
    function DataSet: TDataSet;
  end;

  IConexao = interface
    ['{8D4E1A27-6B3C-4F90-B2D5-1E7A9C0F3B62}']
    function CriarQuery: IQuery;
  end;

  IConexaoFactory = interface
    ['{6B1C9E3A-2F7D-4C55-9A1E-3D0F8B7C2A41}']
    // Cada chamada devolve uma conexão aberta, liberada automaticamente
    // (contagem de referência) quando sai de escopo.
    function CriarConexao: IConexao;
    function Descricao: string;
  end;

implementation

end.
