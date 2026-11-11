unit Conexao.FireDAC;

{ Fábrica concreta: SQL Server via FireDAC (driver MSSQL + pool do FDManager).

  ATENÇÃO: o driver FireDAC MSSQL só existe nas edições Enterprise/Architect.
  Esta unit só é usada quando o projeto é compilado com a diretiva
  FIREDAC_MSSQL (Project > Options > Delphi Compiler > Conditional defines)
  e BANCO_TIPO_CONEXAO = 'FIREDAC' em ConfiguracaoBanco.pas. Na Community/Professional use a fábrica ADO. }

interface

uses
  Conexao.Interfaces;

const
  CONEXAO_FIREDAC_MSSQL = 'BDMG_FIREDAC_MSSQL';

type
  TConexaoFactoryFireDAC = class(TInterfacedObject, IConexaoFactory)
  private
    class var FRegistrado: Boolean;
    class var FLock: TObject;
    class procedure RegistrarDefinicao;
  public
    class constructor Create;
    class destructor Destroy;
    constructor Create;
    function CriarConexao: IConexao;
    function Descricao: string;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  Data.DB,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Def,
  FireDAC.Stan.Pool,
  FireDAC.Stan.Async,
  FireDAC.Stan.Param,
  FireDAC.DApt,
  FireDAC.ConsoleUI.Wait,
  FireDAC.Comp.Client,
  FireDAC.Phys.MSSQL,
  FireDAC.Phys.MSSQLDef,
  Conexao.Base,
  ConfiguracaoBanco;

type
  TConexaoFireDAC = class(TInterfacedObject, IConexao)
  private
    FConexao: TFDConnection;
  public
    constructor Create;
    destructor Destroy; override;
    function CriarQuery: IQuery;
  end;

  TQueryFireDAC = class(TQueryBase)
  private
    FQuery: TFDQuery;
  protected
    procedure AbrirDataSet; override;
    function ExecutarComando: Integer; override;
    procedure AplicarSQL(const ASQL: string); override;
  public
    constructor Create(const AConexaoRef: IConexao; const AConexao: TFDConnection);
    destructor Destroy; override;
    procedure ParamTexto(const ANome, AValor: string); override;
    procedure ParamInteiro(const ANome: string; const AValor: Integer); override;
    procedure ParamInt64(const ANome: string; const AValor: Int64); override;
    procedure ParamNulo(const ANome: string; const ATipo: TFieldType); override;
    function DataSet: TDataSet; override;
  end;

{ TConexaoFactoryFireDAC }

class constructor TConexaoFactoryFireDAC.Create;
begin
  FLock := TObject.Create;
end;

class destructor TConexaoFactoryFireDAC.Destroy;
begin
  FLock.Free;
end;

constructor TConexaoFactoryFireDAC.Create;
begin
  inherited Create;
  RegistrarDefinicao;
end;

class procedure TConexaoFactoryFireDAC.RegistrarDefinicao;
var
  LParams: TStrings;
begin
  if FRegistrado then
    Exit;

  // Double-checked locking: várias threads do Horse podem chegar aqui juntas
  TMonitor.Enter(FLock);
  try
    if FRegistrado then
      Exit;

    LParams := TStringList.Create;
    try
      LParams.Values['Server']   := BANCO_SERVIDOR;
      LParams.Values['Database'] := BANCO_NOME;
      if BANCO_AUTENTICACAO_WINDOWS then
        LParams.Values['OSAuthent'] := 'Yes'
      else
      begin
        LParams.Values['OSAuthent'] := 'No';
        LParams.Values['User_Name'] := BANCO_USUARIO;
        LParams.Values['Password']  := BANCO_SENHA;
      end;
      LParams.Values['LoginTimeout']    := IntToStr(BANCO_TIMEOUT_CONEXAO);
      LParams.Values['ODBCDriver']      := BANCO_ODBC_DRIVER;
      LParams.Values['ODBCAdvanced']    := 'TrustServerCertificate=yes';
      LParams.Values['ApplicationName'] := 'BDMG.Tarefas.Api';
      LParams.Values['MetaDefSchema']   := 'dbo';
      LParams.Values['Pooled']              := 'True';
      LParams.Values['POOL_MaximumItems']   := IntToStr(BANCO_POOL_MAXIMO_CONEXOES);
      LParams.Values['POOL_CleanupTimeout'] := '30000';
      LParams.Values['POOL_ExpireTimeout']  := '60000';

      FDManager.AddConnectionDef(CONEXAO_FIREDAC_MSSQL, 'MSSQL', LParams);
      FDManager.Active := True;
      FRegistrado := True;
    finally
      LParams.Free;
    end;
  finally
    TMonitor.Exit(FLock);
  end;
end;

function TConexaoFactoryFireDAC.CriarConexao: IConexao;
begin
  Result := TConexaoFireDAC.Create;
end;

function TConexaoFactoryFireDAC.Descricao: string;
begin
  Result := 'SQL Server via FireDAC (driver MSSQL, pool habilitado)';
end;

{ TConexaoFireDAC }

constructor TConexaoFireDAC.Create;
begin
  inherited Create;
  FConexao := TFDConnection.Create(nil);
  try
    FConexao.ConnectionDefName := CONEXAO_FIREDAC_MSSQL;
    FConexao.LoginPrompt := False;
    FConexao.Connected := True;
  except
    on E: Exception do
      raise EConexaoException.CreateFmt('Falha ao conectar ao SQL Server: %s', [E.Message]);
  end;
end;

destructor TConexaoFireDAC.Destroy;
begin
  // Com Pooled=True, liberar a conexão devolve-a ao pool
  FConexao.Free;
  inherited Destroy;
end;

function TConexaoFireDAC.CriarQuery: IQuery;
begin
  Result := TQueryFireDAC.Create(Self, FConexao);
end;

{ TQueryFireDAC }

constructor TQueryFireDAC.Create(const AConexaoRef: IConexao; const AConexao: TFDConnection);
begin
  inherited Create(AConexaoRef);
  FQuery := TFDQuery.Create(nil);
  FQuery.Connection := AConexao;
end;

destructor TQueryFireDAC.Destroy;
begin
  FQuery.Free;
  inherited Destroy;
end;

procedure TQueryFireDAC.AplicarSQL(const ASQL: string);
begin
  FQuery.Close;
  FQuery.SQL.Text := ASQL;
end;

procedure TQueryFireDAC.ParamTexto(const ANome, AValor: string);
begin
  FQuery.ParamByName(ANome).AsWideString := AValor;
end;

procedure TQueryFireDAC.ParamInteiro(const ANome: string; const AValor: Integer);
begin
  FQuery.ParamByName(ANome).AsInteger := AValor;
end;

procedure TQueryFireDAC.ParamInt64(const ANome: string; const AValor: Int64);
begin
  FQuery.ParamByName(ANome).AsLargeInt := AValor;
end;

procedure TQueryFireDAC.ParamNulo(const ANome: string; const ATipo: TFieldType);
begin
  FQuery.ParamByName(ANome).DataType := ATipo;
  FQuery.ParamByName(ANome).Clear;
end;

procedure TQueryFireDAC.AbrirDataSet;
begin
  FQuery.Open;
end;

function TQueryFireDAC.ExecutarComando: Integer;
begin
  FQuery.ExecSQL;
  Result := FQuery.RowsAffected;
end;

function TQueryFireDAC.DataSet: TDataSet;
begin
  Result := FQuery;
end;

end.
