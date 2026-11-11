unit Tarefa;

{ Model da entidade Tarefa.
  Compartilhado entre API e cliente VCL para que ambos usem exatamente o mesmo
  contrato JSON (nomes de campos em snake_case, iguais às colunas do banco). }

interface

uses
  System.SysUtils,
  System.JSON,
  BaseModel,
  Paginacao,
  StatusTarefaEnum,
  PrioridadeTarefaEnum;

const
  TAREFA_TITULO_TAMANHO_MINIMO = 3;
  TAREFA_TITULO_TAMANHO_MAXIMO = 150;
  TAREFA_DESCRICAO_TAMANHO_MAXIMO = 1000;
  TAREFA_BUSCA_TAMANHO_MAXIMO = 100;

  // Parâmetros de URL da listagem de tarefas (além de pagina/tamanho)
  PARAM_FILTRO_STATUS = 'status';
  PARAM_FILTRO_PRIORIDADE = 'prioridade';
  PARAM_FILTRO_BUSCA = 'busca';

type
  TTarefa = class(TBaseModel)
  private
    FTitulo: string;
    FDescricao: string;
    FPrioridade: TEnumPrioridadeTarefa;
    FStatus: TEnumStatusTarefa;
    FDataConclusao: TDateTime;
  public
    constructor Create; override;

    procedure Validar; override;
    procedure CarregarDeJSON(const AJSON: TJSONObject); override;
    // Representação completa (respostas da API)
    function ToJSONObject: TJSONObject; override;
    // Apenas os campos informados pelo usuário no cadastro (corpo do POST);
    // id, datas e status são definidos pelo servidor
    function ToJSONCadastro: TJSONObject;
    function Clone: TTarefa;

    property Titulo: string read FTitulo write FTitulo;
    property Descricao: string read FDescricao write FDescricao;
    property Prioridade: TEnumPrioridadeTarefa read FPrioridade write FPrioridade;
    property Status: TEnumStatusTarefa read FStatus write FStatus;
    property DataConclusao: TDateTime read FDataConclusao write FDataConclusao;
  end;

  // Página de tarefas: a paginação genérica aplicada ao model TTarefa
  TPaginaTarefas = TPagina<TTarefa>;

  // Filtros da listagem (combinados com AND)
  TFiltroTarefas = record
    FiltrarPorStatus: Boolean;
    Status: TEnumStatusTarefa;
    FiltrarPorPrioridade: Boolean;
    Prioridade: TEnumPrioridadeTarefa;
    // Texto procurado no título ou na descrição ('' = sem busca)
    Busca: string;
    class function Nenhum: TFiltroTarefas; static;
  end;

implementation

{ TFiltroTarefas }

class function TFiltroTarefas.Nenhum: TFiltroTarefas;
begin
  Result.FiltrarPorStatus := False;
  Result.Status := stPendente;
  Result.FiltrarPorPrioridade := False;
  Result.Prioridade := ptMedia;
  Result.Busca := '';
end;

{ TTarefa }

constructor TTarefa.Create;
begin
  inherited Create;
  FTitulo := '';
  FDescricao := '';
  FPrioridade := ptMedia;
  FStatus := stPendente;
  FDataConclusao := 0;
end;

procedure TTarefa.Validar;
begin
  if FTitulo.Trim = '' then
    raise EArgumentException.Create('O campo "titulo" é obrigatório.');

  if Length(FTitulo.Trim) < TAREFA_TITULO_TAMANHO_MINIMO then
    raise EArgumentException.CreateFmt('O campo "titulo" deve ter no mínimo %d caracteres.',
      [TAREFA_TITULO_TAMANHO_MINIMO]);

  if Length(FTitulo.Trim) > TAREFA_TITULO_TAMANHO_MAXIMO then
    raise EArgumentException.CreateFmt('O campo "titulo" deve ter no máximo %d caracteres.',
      [TAREFA_TITULO_TAMANHO_MAXIMO]);

  if Length(FDescricao) > TAREFA_DESCRICAO_TAMANHO_MAXIMO then
    raise EArgumentException.CreateFmt('O campo "descricao" deve ter no máximo %d caracteres.',
      [TAREFA_DESCRICAO_TAMANHO_MAXIMO]);
end;

procedure TTarefa.CarregarDeJSON(const AJSON: TJSONObject);
var
  LId: Int64;
  LPrioridade: Integer;
  LStatus: string;
begin
  if AJSON = nil then
    raise EArgumentException.Create('Payload JSON inválido ou vazio.');

  if AJSON.TryGetValue<Int64>('id', LId) then
    Id := LId;

  if not AJSON.TryGetValue<string>('titulo', FTitulo) then
    FTitulo := '';
  FTitulo := FTitulo.Trim;

  if not AJSON.TryGetValue<string>('descricao', FDescricao) then
    FDescricao := '';
  FDescricao := FDescricao.Trim;

  // Prioridade e status inválidos geram EConvertError, tratado como 400 pela API
  if AJSON.TryGetValue<Integer>('prioridade', LPrioridade) then
    FPrioridade := IntegerToPrioridadeTarefa(LPrioridade);

  if AJSON.TryGetValue<string>('status', LStatus) and (LStatus.Trim <> '') then
    FStatus := StringToStatusTarefa(LStatus);

  FDataConclusao := JSONParaData(AJSON, 'data_conclusao');
  CriadoEm := JSONParaData(AJSON, 'criado_em');
  AtualizadoEm := JSONParaData(AJSON, 'atualizado_em');
end;

function TTarefa.ToJSONCadastro: TJSONObject;
begin
  Result := TJSONObject.Create;
  try
    Result.AddPair('titulo', FTitulo);
    Result.AddPair('descricao', FDescricao);
    Result.AddPair('prioridade', TJSONNumber.Create(PrioridadeTarefaToInteger(FPrioridade)));
  except
    Result.Free;
    raise;
  end;
end;

function TTarefa.ToJSONObject: TJSONObject;
begin
  Result := ToJSONCadastro;
  try
    Result.AddPair('id', TJSONNumber.Create(Id));
    Result.AddPair('prioridade_descricao', PrioridadeTarefaToDescricao(FPrioridade));
    Result.AddPair('status', StatusTarefaToString(FStatus));
    Result.AddPair('data_conclusao', DataParaJSON(FDataConclusao));
    Result.AddPair('criado_em', DataParaJSON(CriadoEm));
    Result.AddPair('atualizado_em', DataParaJSON(AtualizadoEm));
  except
    Result.Free;
    raise;
  end;
end;

function TTarefa.Clone: TTarefa;
begin
  Result := TTarefa.Create;
  Result.Id := Id;
  Result.Titulo := FTitulo;
  Result.Descricao := FDescricao;
  Result.Prioridade := FPrioridade;
  Result.Status := FStatus;
  Result.DataConclusao := FDataConclusao;
  Result.CriadoEm := CriadoEm;
  Result.AtualizadoEm := AtualizadoEm;
end;

end.
