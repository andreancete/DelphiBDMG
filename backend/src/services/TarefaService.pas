unit TarefaService;

{ Regras de negócio de Tarefas.
  Recebe o repositório por injeção no construtor (constructor injection);
  não conhece HTTP nem SQL. }

interface

uses
  System.SysUtils,
  Paginacao,
  Tarefa,
  EstatisticasTarefas,
  StatusTarefaEnum,
  PrioridadeTarefaEnum,
  TarefaRepository.Interfaces,
  TarefaService.Interfaces,
  ServiceExceptions;

type
  TTarefaService = class(TInterfacedObject, ITarefaService)
  private
    FRepository: ITarefaRepository;
    procedure ValidarId(const AId: Int64);
    function ConverterStatus(const AStatus: string): TEnumStatusTarefa;
    procedure ValidarTransicaoStatus(const AAtual, ANovo: TEnumStatusTarefa);
    function ConverterPrioridadeFiltro(const APrioridade: string): TEnumPrioridadeTarefa;
    function MontarFiltro(const AStatus, APrioridade, ABusca: string): TFiltroTarefas;
  public
    constructor Create(const ARepository: ITarefaRepository);

    function Listar(const AStatus, APrioridade, ABusca: string;
      const APaginacao: TParametrosPaginacao): TPaginaTarefas;
    function ObterPorId(const AId: Int64): TTarefa;
    function Criar(const ATarefa: TTarefa): TTarefa;
    function AtualizarStatus(const AId: Int64; const ANovoStatus: string): TTarefa;
    procedure Excluir(const AId: Int64);
    function ObterEstatisticas: TEstatisticasTarefas;
  end;

implementation

{ TTarefaService }

constructor TTarefaService.Create(const ARepository: ITarefaRepository);
begin
  inherited Create;
  if ARepository = nil then
    raise EArgumentNilException.Create('O repositório de tarefas não foi informado.');
  FRepository := ARepository;
end;

procedure TTarefaService.ValidarId(const AId: Int64);
begin
  if AId <= 0 then
    raise EValidacaoException.Create('O id da tarefa deve ser um número inteiro maior que zero.');
end;

function TTarefaService.ConverterStatus(const AStatus: string): TEnumStatusTarefa;
begin
  if AStatus.Trim = '' then
    raise EValidacaoException.Create('O campo "status" é obrigatório.');

  if not TryStringToStatusTarefa(AStatus, Result) then
    raise EValidacaoException.CreateFmt(
      'Status "%s" inválido. Valores aceitos: PENDENTE, EM_ANDAMENTO, CONCLUIDA, CANCELADA.', [AStatus]);
end;

procedure TTarefaService.ValidarTransicaoStatus(const AAtual, ANovo: TEnumStatusTarefa);
begin
  // Regra de negócio: uma tarefa cancelada precisa ser reaberta (PENDENTE ou
  // EM_ANDAMENTO) antes de ser concluída, evitando conclusões acidentais.
  if (AAtual = stCancelada) and (ANovo = stConcluida) then
    raise ERegraNegocioException.Create(
      'Uma tarefa cancelada não pode ser concluída diretamente. Reabra a tarefa antes de concluí-la.');
end;

function TTarefaService.ConverterPrioridadeFiltro(const APrioridade: string): TEnumPrioridadeTarefa;
var
  LValor: Integer;
begin
  if not TryStrToInt(APrioridade.Trim, LValor) or not PrioridadeValida(LValor) then
    raise EValidacaoException.CreateFmt(
      'Prioridade "%s" inválida. Informe um valor entre %d (Baixa) e %d (Urgente).',
      [APrioridade, PRIORIDADE_MINIMA, PRIORIDADE_MAXIMA]);
  Result := IntegerToPrioridadeTarefa(LValor);
end;

function TTarefaService.MontarFiltro(const AStatus, APrioridade, ABusca: string): TFiltroTarefas;
begin
  Result := TFiltroTarefas.Nenhum;

  Result.FiltrarPorStatus := AStatus.Trim <> '';
  if Result.FiltrarPorStatus then
    Result.Status := ConverterStatus(AStatus);

  Result.FiltrarPorPrioridade := APrioridade.Trim <> '';
  if Result.FiltrarPorPrioridade then
    Result.Prioridade := ConverterPrioridadeFiltro(APrioridade);

  Result.Busca := ABusca.Trim;
  if Length(Result.Busca) > TAREFA_BUSCA_TAMANHO_MAXIMO then
    raise EValidacaoException.CreateFmt('O parâmetro "busca" deve ter no máximo %d caracteres.',
      [TAREFA_BUSCA_TAMANHO_MAXIMO]);
end;

function TTarefaService.Listar(const AStatus, APrioridade, ABusca: string;
  const APaginacao: TParametrosPaginacao): TPaginaTarefas;
begin
  Result := FRepository.Listar(MontarFiltro(AStatus, APrioridade, ABusca), APaginacao);
end;

function TTarefaService.ObterPorId(const AId: Int64): TTarefa;
begin
  ValidarId(AId);

  Result := FRepository.ObterPorId(AId);
  if Result = nil then
    raise ENaoEncontradoException.CreateFmt('Tarefa com id %d não encontrada.', [AId]);
end;

function TTarefaService.Criar(const ATarefa: TTarefa): TTarefa;
var
  LNovoId: Int64;
begin
  if ATarefa = nil then
    raise EValidacaoException.Create('Os dados da tarefa não foram informados.');

  try
    ATarefa.Validar;
  except
    on E: EArgumentException do
      raise EValidacaoException.Create(E.Message);
  end;

  LNovoId := FRepository.Inserir(ATarefa);
  if LNovoId <= 0 then
    raise Exception.Create('Não foi possível cadastrar a tarefa.');

  // Relê do banco para devolver os valores gerados pelo servidor (id, datas)
  Result := ObterPorId(LNovoId);
end;

function TTarefaService.AtualizarStatus(const AId: Int64; const ANovoStatus: string): TTarefa;
var
  LNovoStatus: TEnumStatusTarefa;
  LAtual: TTarefa;
begin
  ValidarId(AId);
  LNovoStatus := ConverterStatus(ANovoStatus);

  LAtual := ObterPorId(AId);
  try
    // Idempotente: mesmo status não gera escrita no banco
    if LAtual.Status = LNovoStatus then
      Exit(LAtual.Clone);

    ValidarTransicaoStatus(LAtual.Status, LNovoStatus);
  finally
    LAtual.Free;
  end;

  if not FRepository.AtualizarStatus(AId, LNovoStatus) then
    raise ENaoEncontradoException.CreateFmt('Tarefa com id %d não encontrada.', [AId]);

  Result := ObterPorId(AId);
end;

procedure TTarefaService.Excluir(const AId: Int64);
begin
  ValidarId(AId);

  if not FRepository.Excluir(AId) then
    raise ENaoEncontradoException.CreateFmt('Tarefa com id %d não encontrada.', [AId]);
end;

function TTarefaService.ObterEstatisticas: TEstatisticasTarefas;
begin
  Result := FRepository.ObterEstatisticas;
end;

end.
