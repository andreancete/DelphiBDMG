unit TarefaRepository.SQLServer;

{ Implementação de ITarefaRepository para SQL Server.

  - Usa apenas as abstrações IConexaoFactory/IConexao/IQuery: não sabe se por
    baixo está ADO ou FireDAC (Abstract Factory).
  - Todas as consultas usam parâmetros (proteção contra SQL Injection).
  - Exclusão lógica (soft delete via excluido_em) preserva o histórico para
    auditoria; todas as leituras filtram excluido_em IS NULL. }

interface

uses
  System.SysUtils,
  Data.DB,
  Paginacao,
  Conexao.Interfaces,
  TarefaRepository.Interfaces,
  Tarefa,
  EstatisticasTarefas,
  StatusTarefaEnum;

type
  TTarefaRepositorySQLServer = class(TInterfacedObject, ITarefaRepository)
  private
    FConexao: IConexao;
    function DatasetParaTarefa(const ADataSet: TDataSet): TTarefa;
  public
    constructor Create(const AConexaoFactory: IConexaoFactory);

    function Listar(const AFiltro: TFiltroTarefas; const APaginacao: TParametrosPaginacao): TPaginaTarefas;
    function ObterPorId(const AId: Int64): TTarefa;
    function Inserir(const ATarefa: TTarefa): Int64;
    function AtualizarStatus(const AId: Int64; const AStatus: TEnumStatusTarefa): Boolean;
    function Excluir(const AId: Int64): Boolean;
    function ObterEstatisticas: TEstatisticasTarefas;
  end;

implementation

uses
  PrioridadeTarefaEnum,
  ConsultaPaginada;

const
  SQL_CAMPOS =
    'SELECT t.id, t.titulo, t.descricao, t.prioridade, t.status, ' +
    '       t.data_conclusao, t.criado_em, t.atualizado_em ' +
    '  FROM dbo.tarefas t ';

  // Pendentes e em andamento primeiro, depois maior prioridade, depois mais
  // antigas. O id no final garante ordem estável entre as páginas.
  ORDENACAO_LISTAGEM =
    'CASE t.status WHEN ''PENDENTE'' THEN 0 WHEN ''EM_ANDAMENTO'' THEN 1 ELSE 2 END, ' +
    't.prioridade DESC, t.criado_em ASC, t.id ASC';

  // Filtros opcionais acrescentados ao WHERE apenas quando informados
  // (cada parâmetro aparece uma única vez no SQL, como o ADO exige)
  SQL_LISTAR_BASE = SQL_CAMPOS + ' WHERE t.excluido_em IS NULL';
  SQL_FILTRO_STATUS = ' AND t.status = :status';
  SQL_FILTRO_PRIORIDADE = ' AND t.prioridade = :prioridade';
  SQL_FILTRO_BUSCA = ' AND (t.titulo LIKE :busca_titulo OR t.descricao LIKE :busca_descricao)';

  SQL_OBTER_POR_ID =
    SQL_CAMPOS + ' WHERE t.id = :id AND t.excluido_em IS NULL';

  // OUTPUT INSERTED.id devolve o identity gerado na própria instrução
  // (mais seguro que SCOPE_IDENTITY() quando existem triggers)
  SQL_INSERIR =
    'INSERT INTO dbo.tarefas (titulo, descricao, prioridade, status, data_conclusao) ' +
    'OUTPUT INSERTED.id ' +
    'VALUES (:titulo, :descricao, :prioridade, :status, ' +
    '        CASE WHEN :concluida = 1 THEN SYSDATETIME() ELSE NULL END)';

  // data_conclusao é controlada pelo servidor: preenchida ao concluir e limpa
  // se a tarefa voltar a outro status (mantém a CHECK constraint da tabela)
  SQL_ATUALIZAR_STATUS =
    'UPDATE dbo.tarefas ' +
    '   SET status = :status, ' +
    '       data_conclusao = CASE WHEN :concluida = 1 ' +
    '                             THEN COALESCE(data_conclusao, SYSDATETIME()) ' +
    '                             ELSE NULL END, ' +
    '       atualizado_em = SYSDATETIME() ' +
    ' WHERE id = :id AND excluido_em IS NULL';

  SQL_EXCLUIR =
    'UPDATE dbo.tarefas ' +
    '   SET excluido_em = SYSDATETIME(), atualizado_em = SYSDATETIME() ' +
    ' WHERE id = :id AND excluido_em IS NULL';

  { ===== DESAFIO SQL =====
    Os três indicadores saem de UMA única leitura da tabela, com agregação
    condicional, em vez de três SELECTs separados:

    1) total_tarefas              -> COUNT(*) das tarefas não excluídas.
    2) media_prioridade_pendentes -> AVG apenas das linhas PENDENTE (o CASE sem
                                     ELSE gera NULL, que o AVG ignora). O CAST
                                     para DECIMAL evita a divisão inteira do
                                     SQL Server (AVG de TINYINT truncaria 2,5 para 2).
    3) concluidas_ultimos_7_dias  -> SUM condicional das CONCLUIDA cuja
                                     data_conclusao está nos últimos 7 dias.

    ISNULL garante 0 em tabela vazia. O índice filtrado
    idx_tarefas_status_conclusao (DB/02_criar_tabela_tarefas.sql) cobre a consulta. }
  SQL_ESTATISTICAS =
    'SELECT COUNT(*) AS total_tarefas, ' +
    '       ISNULL(CAST(AVG(CASE WHEN status = ''PENDENTE'' ' +
    '                            THEN CAST(prioridade AS DECIMAL(5, 2)) END) AS DECIMAL(5, 2)), 0) ' +
    '         AS media_prioridade_pendentes, ' +
    '       ISNULL(SUM(CASE WHEN status = ''CONCLUIDA'' ' +
    '                        AND data_conclusao >= DATEADD(DAY, -7, SYSDATETIME()) ' +
    '                       THEN 1 ELSE 0 END), 0) AS concluidas_ultimos_7_dias, ' +
    '       SYSDATETIME() AS gerado_em ' +
    '  FROM dbo.tarefas ' +
    ' WHERE excluido_em IS NULL';

{ TTarefaRepositorySQLServer }

constructor TTarefaRepositorySQLServer.Create(const AConexaoFactory: IConexaoFactory);
begin
  inherited Create;
  if AConexaoFactory = nil then
    raise EArgumentNilException.Create('A fábrica de conexão não foi informada.');

  // Uma conexão por instância (= por requisição HTTP); liberada por contagem de referência
  FConexao := AConexaoFactory.CriarConexao;
end;

function TTarefaRepositorySQLServer.DatasetParaTarefa(const ADataSet: TDataSet): TTarefa;
begin
  Result := TTarefa.Create;
  try
    Result.Id := ADataSet.FieldByName('id').AsLargeInt;
    Result.Titulo := ADataSet.FieldByName('titulo').AsString;
    Result.Descricao := ADataSet.FieldByName('descricao').AsString;
    Result.Prioridade := IntegerToPrioridadeTarefa(ADataSet.FieldByName('prioridade').AsInteger);
    Result.Status := StringToStatusTarefa(ADataSet.FieldByName('status').AsString);

    if ADataSet.FieldByName('data_conclusao').IsNull then
      Result.DataConclusao := 0
    else
      Result.DataConclusao := ADataSet.FieldByName('data_conclusao').AsDateTime;

    Result.CriadoEm := ADataSet.FieldByName('criado_em').AsDateTime;
    Result.AtualizadoEm := ADataSet.FieldByName('atualizado_em').AsDateTime;
  except
    Result.Free;
    raise;
  end;
end;

// Escapa os curingas do LIKE (%, _ e [) digitados pelo usuário, para que sejam
// procurados como texto e não interpretados pelo SQL Server
function PadraoLikeContendo(const ATexto: string): string;
begin
  Result := '%' + ATexto
    .Replace('[', '[[]')
    .Replace('%', '[%]')
    .Replace('_', '[_]') + '%';
end;

function TTarefaRepositorySQLServer.Listar(const AFiltro: TFiltroTarefas;
  const APaginacao: TParametrosPaginacao): TPaginaTarefas;
var
  LFiltro: TFiltroTarefas;
  LSQL, LPadraoBusca: string;
begin
  // Cópia local: é ela que os métodos anônimos abaixo capturam
  LFiltro := AFiltro;
  LSQL := SQL_LISTAR_BASE;
  if AFiltro.FiltrarPorStatus then
    LSQL := LSQL + SQL_FILTRO_STATUS;
  if AFiltro.FiltrarPorPrioridade then
    LSQL := LSQL + SQL_FILTRO_PRIORIDADE;
  if AFiltro.Busca <> '' then
    LSQL := LSQL + SQL_FILTRO_BUSCA;
  LPadraoBusca := PadraoLikeContendo(AFiltro.Busca);

  Result := TConsultaPaginada.Executar<TTarefa>(FConexao, LSQL, ORDENACAO_LISTAGEM, APaginacao,
    procedure(AQuery: IQuery)
    begin
      if LFiltro.FiltrarPorStatus then
        AQuery.ParamTexto('status', StatusTarefaToString(LFiltro.Status));
      if LFiltro.FiltrarPorPrioridade then
        AQuery.ParamInteiro('prioridade', PrioridadeTarefaToInteger(LFiltro.Prioridade));
      if LFiltro.Busca <> '' then
      begin
        AQuery.ParamTexto('busca_titulo', LPadraoBusca);
        AQuery.ParamTexto('busca_descricao', LPadraoBusca);
      end;
    end,
    function(ADataSet: TDataSet): TTarefa
    begin
      Result := DatasetParaTarefa(ADataSet);
    end);
end;

function TTarefaRepositorySQLServer.ObterPorId(const AId: Int64): TTarefa;
var
  LQuery: IQuery;
begin
  Result := nil;
  LQuery := FConexao.CriarQuery;
  LQuery.DefinirSQL(SQL_OBTER_POR_ID);
  LQuery.ParamInt64('id', AId);
  LQuery.Abrir;

  if not LQuery.DataSet.IsEmpty then
    Result := DatasetParaTarefa(LQuery.DataSet);
end;

function TTarefaRepositorySQLServer.Inserir(const ATarefa: TTarefa): Int64;
var
  LQuery: IQuery;
begin
  LQuery := FConexao.CriarQuery;
  LQuery.DefinirSQL(SQL_INSERIR);
  LQuery.ParamTexto('titulo', ATarefa.Titulo);

  if ATarefa.Descricao.Trim = '' then
    LQuery.ParamNulo('descricao', ftWideString)
  else
    LQuery.ParamTexto('descricao', ATarefa.Descricao);

  LQuery.ParamInteiro('prioridade', PrioridadeTarefaToInteger(ATarefa.Prioridade));
  LQuery.ParamTexto('status', StatusTarefaToString(ATarefa.Status));
  LQuery.ParamInteiro('concluida', Ord(ATarefa.Status = stConcluida));
  LQuery.Abrir;

  Result := LQuery.DataSet.Fields[0].AsLargeInt;
end;

function TTarefaRepositorySQLServer.AtualizarStatus(const AId: Int64; const AStatus: TEnumStatusTarefa): Boolean;
var
  LQuery: IQuery;
begin
  LQuery := FConexao.CriarQuery;
  LQuery.DefinirSQL(SQL_ATUALIZAR_STATUS);
  LQuery.ParamTexto('status', StatusTarefaToString(AStatus));
  LQuery.ParamInteiro('concluida', Ord(AStatus = stConcluida));
  LQuery.ParamInt64('id', AId);
  Result := LQuery.Executar > 0;
end;

function TTarefaRepositorySQLServer.Excluir(const AId: Int64): Boolean;
var
  LQuery: IQuery;
begin
  LQuery := FConexao.CriarQuery;
  LQuery.DefinirSQL(SQL_EXCLUIR);
  LQuery.ParamInt64('id', AId);
  Result := LQuery.Executar > 0;
end;

function TTarefaRepositorySQLServer.ObterEstatisticas: TEstatisticasTarefas;
var
  LQuery: IQuery;
begin
  Result := TEstatisticasTarefas.Create;
  try
    LQuery := FConexao.CriarQuery;
    LQuery.DefinirSQL(SQL_ESTATISTICAS);
    LQuery.Abrir;

    Result.TotalTarefas := LQuery.DataSet.FieldByName('total_tarefas').AsInteger;
    Result.MediaPrioridadePendentes := LQuery.DataSet.FieldByName('media_prioridade_pendentes').AsFloat;
    Result.ConcluidasUltimos7Dias := LQuery.DataSet.FieldByName('concluidas_ultimos_7_dias').AsInteger;
    Result.GeradoEm := LQuery.DataSet.FieldByName('gerado_em').AsDateTime;
  except
    Result.Free;
    raise;
  end;
end;

end.
