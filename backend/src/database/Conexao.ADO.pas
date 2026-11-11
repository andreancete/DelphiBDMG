unit Conexao.ADO;

{ Fábrica concreta: SQL Server via dbGo (ADO) + provider OLE DB MSOLEDBSQL.

  Por que ADO como padrão: o driver MSSQL do FireDAC não faz parte das edições
  Community/Professional do Delphi; o dbGo está disponível em todas elas.

  Desempenho - pool de conexões próprio (TPoolConexoesADO):
  - Abrir uma conexão física custa caro (resolução da instância nomeada,
    negociação TLS e login), cerca de 1 s. Por isso as conexões abertas são
    devolvidas a um pool e reaproveitadas pelas requisições seguintes.
  - Conexão que falhou durante uma consulta é descartada, nunca volta ao pool.
  - Conexão parada há mais de BANCO_POOL_TEMPO_OCIOSO_SEG é renovada antes de
    ser reutilizada (o servidor pode tê-la encerrado).

  COM (ADO é COM):
  - A fábrica inicializa o apartamento MTA na thread principal e o mantém
    ativo durante toda a vida da API. Assim as conexões do pool continuam
    válidas e podem ser usadas por qualquer thread do Horse (todas no MTA).
  - Cada conexão em uso também chama CoInitializeEx/CoUninitialize na thread
    da requisição, como exige o COM.

  Use o provider MSOLEDBSQL (Microsoft OLE DB Driver for SQL Server). O antigo
  SQLOLEDB devolve colunas DATETIME2 como texto. }

interface

uses
  System.SyncObjs,
  System.Generics.Collections,
  Data.Win.ADODB,
  Conexao.Interfaces;

type
  // Conexão parada no pool + instante em que foi devolvida
  TConexaoOciosa = record
    Conexao: TADOConnection;
    DevolvidaEm: TDateTime;
  end;

  TPoolConexoesADO = class
  private
    FConnectionString: string;
    FMaximoLivres: Integer;
    FLivres: TStack<TConexaoOciosa>;
    FLock: TCriticalSection;
    function CriarConexaoFisica: TADOConnection;
  public
    constructor Create(const AConnectionString: string; const AMaximoLivres: Integer);
    destructor Destroy; override;
    // Entrega uma conexão aberta (reaproveitada do pool ou nova)
    function Obter: TADOConnection;
    // AReutilizavel = False descarta a conexão (ex.: falhou em uma consulta)
    procedure Devolver(const AConexao: TADOConnection; const AReutilizavel: Boolean);
  end;

  TConexaoFactoryADO = class(TInterfacedObject, IConexaoFactory)
  private
    FPool: TPoolConexoesADO;
    FCOMMantido: Boolean;
    function MontarConnectionString: string;
  public
    // Deve ser criada na thread principal (bootstrap da API)
    constructor Create;
    destructor Destroy; override;
    function CriarConexao: IConexao;
    function Descricao: string;
  end;

implementation

uses
  System.SysUtils,
  System.Variants,
  System.DateUtils,
  System.Diagnostics,
  Winapi.ActiveX,
  Data.DB,
  Conexao.Base,
  ConfiguracaoBanco,
  LogApi;

type
  TConexaoADO = class(TInterfacedObject, IConexao)
  private
    FPool: TPoolConexoesADO;
    FConexao: TADOConnection;
    FInvalida: Boolean;
    FCOMInicializado: Boolean;
  public
    constructor Create(const APool: TPoolConexoesADO);
    destructor Destroy; override;
    function CriarQuery: IQuery;
    // Marca a conexão para ser descartada em vez de voltar ao pool
    procedure Invalidar;
  end;

  TQueryADO = class(TQueryBase)
  private
    FConexaoADO: TConexaoADO;
    FQuery: TADOQuery;
    function Parametro(const ANome: string): TParameter;
  protected
    procedure AbrirDataSet; override;
    function ExecutarComando: Integer; override;
    procedure AoFalhar; override;
    procedure AplicarSQL(const ASQL: string); override;
  public
    constructor Create(const AConexao: TConexaoADO; const AConexaoFisica: TADOConnection);
    destructor Destroy; override;
    procedure ParamTexto(const ANome, AValor: string); override;
    procedure ParamInteiro(const ANome: string; const AValor: Integer); override;
    procedure ParamInt64(const ANome: string; const AValor: Int64); override;
    procedure ParamNulo(const ANome: string; const ATipo: TFieldType); override;
    function DataSet: TDataSet; override;
  end;

function BoolParaTexto(const AValor: Boolean): string;
begin
  if AValor then
    Result := 'true'
  else
    Result := 'false';
end;

{ TConexaoFactoryADO }

constructor TConexaoFactoryADO.Create;
begin
  inherited Create;
  // Mantém o MTA vivo durante toda a execução (ver comentário da unit)
  FCOMMantido := Succeeded(CoInitializeEx(nil, COINIT_MULTITHREADED));
  FPool := TPoolConexoesADO.Create(MontarConnectionString, BANCO_POOL_MAXIMO_CONEXOES);
end;

destructor TConexaoFactoryADO.Destroy;
begin
  FPool.Free;
  if FCOMMantido then
    CoUninitialize;
  inherited Destroy;
end;

function TConexaoFactoryADO.MontarConnectionString: string;
var
  LAutenticacao: string;
begin
  if BANCO_AUTENTICACAO_WINDOWS then
    LAutenticacao := 'Integrated Security=SSPI;'
  else
    LAutenticacao := Format('User ID=%s;Password=%s;', [BANCO_USUARIO, BANCO_SENHA]);

  Result := Format(
    'Provider=%s;Data Source=%s;Initial Catalog=%s;%s' +
    'Use Encryption for Data=%s;Trust Server Certificate=%s;' +
    'Application Name=BDMG.Tarefas.Api;',
    [BANCO_OLEDB_PROVIDER,
     BANCO_SERVIDOR,
     BANCO_NOME,
     LAutenticacao,
     BoolParaTexto(BANCO_CRIPTOGRAFAR_CONEXAO),
     BoolParaTexto(BANCO_CONFIAR_CERTIFICADO_SERVIDOR)]);
end;

function TConexaoFactoryADO.CriarConexao: IConexao;
begin
  Result := TConexaoADO.Create(FPool);
end;

function TConexaoFactoryADO.Descricao: string;
begin
  Result := Format('SQL Server via dbGo/ADO (%s) - %s\%s, pool de até %d conexões',
    [BANCO_OLEDB_PROVIDER, BANCO_SERVIDOR, BANCO_NOME, BANCO_POOL_MAXIMO_CONEXOES]);
end;

{ TPoolConexoesADO }

constructor TPoolConexoesADO.Create(const AConnectionString: string; const AMaximoLivres: Integer);
begin
  inherited Create;
  FConnectionString := AConnectionString;
  FMaximoLivres := AMaximoLivres;
  FLivres := TStack<TConexaoOciosa>.Create;
  FLock := TCriticalSection.Create;
end;

destructor TPoolConexoesADO.Destroy;
begin
  while FLivres.Count > 0 do
    FLivres.Pop.Conexao.Free;
  FLivres.Free;
  FLock.Free;
  inherited Destroy;
end;

function TPoolConexoesADO.CriarConexaoFisica: TADOConnection;
var
  LCronometro: TStopwatch;
begin
  LCronometro := TStopwatch.StartNew;
  Result := TADOConnection.Create(nil);
  try
    Result.LoginPrompt := False;
    Result.ConnectionString := FConnectionString;
    Result.ConnectionTimeout := BANCO_TIMEOUT_CONEXAO;
    Result.CommandTimeout := BANCO_TIMEOUT_COMANDO;
    Result.Connected := True;
  except
    on E: Exception do
    begin
      FreeAndNil(Result);
      raise EConexaoException.CreateFmt('Falha ao conectar ao SQL Server: %s', [E.Message]);
    end;
  end;
  // Esperado só no início ou em picos de carga; se aparecer sempre, o pool não está reaproveitando
  TLog.Info(Format('Nova conexão física com o banco aberta em %d ms', [LCronometro.ElapsedMilliseconds]));
end;

function TPoolConexoesADO.Obter: TADOConnection;
var
  LOciosa: TConexaoOciosa;
  LEncontrou: Boolean;
begin
  repeat
    FLock.Enter;
    try
      LEncontrou := FLivres.Count > 0;
      if LEncontrou then
        LOciosa := FLivres.Pop;
    finally
      FLock.Leave;
    end;

    if not LEncontrou then
      Exit(CriarConexaoFisica);

    // Parada há muito tempo: o servidor pode ter encerrado a sessão; renova
    if SecondsBetween(Now, LOciosa.DevolvidaEm) > BANCO_POOL_TEMPO_OCIOSO_SEG then
      LOciosa.Conexao.Free
    else
      Exit(LOciosa.Conexao);
  until False;
end;

procedure TPoolConexoesADO.Devolver(const AConexao: TADOConnection; const AReutilizavel: Boolean);
var
  LOciosa: TConexaoOciosa;
  LGuardou: Boolean;
begin
  LGuardou := False;

  if AReutilizavel and AConexao.Connected and not AConexao.InTransaction then
  begin
    LOciosa.Conexao := AConexao;
    LOciosa.DevolvidaEm := Now;
    FLock.Enter;
    try
      LGuardou := FLivres.Count < FMaximoLivres;
      if LGuardou then
        FLivres.Push(LOciosa);
    finally
      FLock.Leave;
    end;
  end;

  if not LGuardou then
    AConexao.Free;
end;

{ TConexaoADO }

constructor TConexaoADO.Create(const APool: TPoolConexoesADO);
begin
  inherited Create;
  FPool := APool;
  // S_OK ou S_FALSE (já inicializado) exigem CoUninitialize correspondente
  FCOMInicializado := Succeeded(CoInitializeEx(nil, COINIT_MULTITHREADED));
  FConexao := FPool.Obter;
end;

destructor TConexaoADO.Destroy;
begin
  if Assigned(FConexao) then
    FPool.Devolver(FConexao, not FInvalida);
  if FCOMInicializado then
    CoUninitialize;
  inherited Destroy;
end;

procedure TConexaoADO.Invalidar;
begin
  FInvalida := True;
end;

function TConexaoADO.CriarQuery: IQuery;
begin
  Result := TQueryADO.Create(Self, FConexao);
end;

{ TQueryADO }

constructor TQueryADO.Create(const AConexao: TConexaoADO; const AConexaoFisica: TADOConnection);
begin
  // A referência IConexao (na base) mantém AConexao viva enquanto a query existir
  inherited Create(AConexao);
  FConexaoADO := AConexao;
  FQuery := TADOQuery.Create(nil);
  FQuery.Connection := AConexaoFisica;
  FQuery.ParamCheck := True;
  // Somente leitura e só para frente ("firehose"): é como os repositórios leem.
  // O padrão do dbGo (cursor no cliente, atualizável) obriga o ADO a buscar
  // metadados das colunas a cada abertura, o que é caro em colunas calculadas.
  FQuery.CursorLocation := clUseServer;
  FQuery.CursorType := ctOpenForwardOnly;
  FQuery.LockType := ltReadOnly;
end;

destructor TQueryADO.Destroy;
begin
  FQuery.Free;
  inherited Destroy;
end;

function TQueryADO.Parametro(const ANome: string): TParameter;
begin
  Result := FQuery.Parameters.ParamByName(ANome);
end;

procedure TQueryADO.AplicarSQL(const ASQL: string);
begin
  FQuery.Close;
  FQuery.SQL.Text := ASQL;
end;

procedure TQueryADO.ParamTexto(const ANome, AValor: string);
begin
  Parametro(ANome).DataType := ftWideString;
  Parametro(ANome).Value := AValor;
end;

procedure TQueryADO.ParamInteiro(const ANome: string; const AValor: Integer);
begin
  Parametro(ANome).DataType := ftInteger;
  Parametro(ANome).Value := AValor;
end;

procedure TQueryADO.ParamInt64(const ANome: string; const AValor: Int64);
begin
  Parametro(ANome).DataType := ftLargeint;
  Parametro(ANome).Value := AValor;
end;

procedure TQueryADO.ParamNulo(const ANome: string; const ATipo: TFieldType);
begin
  Parametro(ANome).DataType := ATipo;
  Parametro(ANome).Value := Null;
end;

procedure TQueryADO.AbrirDataSet;
begin
  FQuery.Open;
end;

function TQueryADO.ExecutarComando: Integer;
begin
  Result := FQuery.ExecSQL;
end;

procedure TQueryADO.AoFalhar;
begin
  // Conexão possivelmente quebrada: não deve voltar ao pool
  FConexaoADO.Invalidar;
end;

function TQueryADO.DataSet: TDataSet;
begin
  Result := FQuery;
end;

end.
