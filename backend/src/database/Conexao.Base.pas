unit Conexao.Base;

{ Classe base das queries das fábricas concretas (ADO, FireDAC).

  Template Method: DefinirSQL, Abrir e Executar fazem a parte comum e
  delegam o trabalho específico de cada tecnologia para AplicarSQL,
  AbrirDataSet e ExecutarComando. A parte comum:
  - traduz qualquer erro do driver em EBancoDadosException;
  - avisa a tecnologia da falha (AoFalhar), para descartar a conexão;
  - registra no log as consultas mais lentas que BANCO_LOG_CONSULTA_LENTA_MS. }

interface

uses
  System.SysUtils,
  Data.DB,
  Conexao.Interfaces;

type
  TQueryBase = class abstract(TInterfacedObject, IQuery)
  private
    // Mantém a conexão viva enquanto a query existir
    FConexaoRef: IConexao;
    FSQL: string;
    procedure RegistrarSeLenta(const AOperacao: string; const AMilissegundos: Int64);
  protected
    procedure AplicarSQL(const ASQL: string); virtual; abstract;
    procedure AbrirDataSet; virtual; abstract;
    function ExecutarComando: Integer; virtual; abstract;
    // Gancho chamado quando a operação falha (ex.: descartar a conexão do pool)
    procedure AoFalhar; virtual;
  public
    constructor Create(const AConexaoRef: IConexao);

    procedure DefinirSQL(const ASQL: string);
    procedure ParamTexto(const ANome, AValor: string); virtual; abstract;
    procedure ParamInteiro(const ANome: string; const AValor: Integer); virtual; abstract;
    procedure ParamInt64(const ANome: string; const AValor: Int64); virtual; abstract;
    procedure ParamNulo(const ANome: string; const ATipo: TFieldType); virtual; abstract;
    function DataSet: TDataSet; virtual; abstract;

    procedure Abrir;
    function Executar: Integer;
  end;

implementation

uses
  System.Diagnostics,
  ConfiguracaoBanco,
  LogApi;

const
  TAMANHO_MAXIMO_SQL_NO_LOG = 120;

{ TQueryBase }

constructor TQueryBase.Create(const AConexaoRef: IConexao);
begin
  inherited Create;
  FConexaoRef := AConexaoRef;
end;

procedure TQueryBase.AoFalhar;
begin
  // Implementação padrão vazia: cada tecnologia decide se precisa reagir
end;

procedure TQueryBase.DefinirSQL(const ASQL: string);
begin
  FSQL := ASQL;
  AplicarSQL(ASQL);
end;

procedure TQueryBase.RegistrarSeLenta(const AOperacao: string; const AMilissegundos: Int64);
var
  LResumo: string;
begin
  if AMilissegundos < BANCO_LOG_CONSULTA_LENTA_MS then
    Exit;

  // Uma linha só, com o início do comando, para identificar a consulta
  LResumo := FSQL.Replace(sLineBreak, ' ').Trim;
  while LResumo.Contains('  ') do
    LResumo := LResumo.Replace('  ', ' ');
  if Length(LResumo) > TAMANHO_MAXIMO_SQL_NO_LOG then
    LResumo := Copy(LResumo, 1, TAMANHO_MAXIMO_SQL_NO_LOG) + '...';

  TLog.Aviso(Format('Consulta lenta - %s em %d ms: %s', [AOperacao, AMilissegundos, LResumo]));
end;

procedure TQueryBase.Abrir;
var
  LCronometro: TStopwatch;
begin
  LCronometro := TStopwatch.StartNew;
  try
    AbrirDataSet;
  except
    on E: Exception do
    begin
      AoFalhar;
      raise EBancoDadosException.Create(E.Message);
    end;
  end;
  RegistrarSeLenta('Abrir', LCronometro.ElapsedMilliseconds);
end;

function TQueryBase.Executar: Integer;
var
  LCronometro: TStopwatch;
begin
  LCronometro := TStopwatch.StartNew;
  try
    Result := ExecutarComando;
  except
    on E: Exception do
    begin
      AoFalhar;
      raise EBancoDadosException.Create(E.Message);
    end;
  end;
  RegistrarSeLenta('Executar', LCronometro.ElapsedMilliseconds);
end;

end.
