unit TarefaServiceTests;

{ Testes unitários da camada de Service.
  Usam um repositório em memória (fake de ITarefaRepository), portanto rodam
  sem SQL Server e testam apenas as regras de negócio. }

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.Generics.Collections,
  Paginacao,
  Tarefa,
  EstatisticasTarefas,
  StatusTarefaEnum,
  PrioridadeTarefaEnum,
  TarefaRepository.Interfaces,
  TarefaService.Interfaces,
  TarefaService,
  ServiceExceptions;

type
  TTarefaRepositoryFake = class(TInterfacedObject, ITarefaRepository)
  private
    FItens: TObjectList<TTarefa>;
    FProximoId: Int64;
    function Localizar(const AId: Int64): TTarefa;
  public
    constructor Create;
    destructor Destroy; override;

    function Listar(const AFiltro: TFiltroTarefas; const APaginacao: TParametrosPaginacao): TPaginaTarefas;
    function ObterPorId(const AId: Int64): TTarefa;
    function Inserir(const ATarefa: TTarefa): Int64;
    function AtualizarStatus(const AId: Int64; const AStatus: TEnumStatusTarefa): Boolean;
    function Excluir(const AId: Int64): Boolean;
    function ObterEstatisticas: TEstatisticasTarefas;
  end;

  [TestFixture]
  TTarefaServiceTests = class
  private
    FService: ITarefaService;
    function NovaTarefa(const ATitulo: string; const APrioridade: TEnumPrioridadeTarefa = ptMedia): TTarefa;
    function CriarTarefa(const ATitulo: string; const APrioridade: TEnumPrioridadeTarefa = ptMedia): Int64;
    function ListarPagina(const APagina, ATamanho: Integer; const AStatus: string = '';
      const ABusca: string = ''; const APrioridade: string = ''): TPaginaTarefas;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure Criar_DeveCadastrar_QuandoDadosValidos;
    [Test]
    procedure Criar_DeveFalhar_QuandoTituloVazio;
    [Test]
    procedure Criar_DeveFalhar_QuandoTituloCurto;
    [Test]
    procedure Listar_DeveFiltrarPorStatus;
    [Test]
    procedure Listar_DeveFiltrarPorBusca;
    [Test]
    procedure Listar_DeveFiltrarPorPrioridade;
    [Test]
    procedure Listar_DeveFalhar_QuandoPrioridadeInvalida;
    [Test]
    procedure Listar_DeveFalhar_QuandoStatusInvalido;
    [Test]
    procedure Listar_DeveFalhar_QuandoBuscaMuitoLonga;
    [Test]
    procedure Listar_DeveRespeitarTamanhoDaPagina;
    [Test]
    procedure Listar_UltimaPagina_DeveVirIncompleta;
    [Test]
    procedure Listar_PaginaAlemDoFim_DeveVirVazia;
    [Test]
    procedure ObterPorId_DeveFalhar_QuandoNaoEncontrada;
    [Test]
    procedure AtualizarStatus_DevePreencherDataConclusao_QuandoConcluida;
    [Test]
    procedure AtualizarStatus_DeveFalhar_QuandoStatusInvalido;
    [Test]
    procedure AtualizarStatus_DeveFalhar_QuandoCanceladaParaConcluida;
    [Test]
    procedure Excluir_DeveRemover_QuandoExistente;
    [Test]
    procedure Excluir_DeveFalhar_QuandoNaoEncontrada;
    [Test]
    procedure Estatisticas_DeveCalcularIndicadores;
  end;

implementation

uses
  System.DateUtils;

{ TTarefaRepositoryFake }

constructor TTarefaRepositoryFake.Create;
begin
  inherited Create;
  FItens := TObjectList<TTarefa>.Create(True);
  FProximoId := 1;
end;

destructor TTarefaRepositoryFake.Destroy;
begin
  FItens.Free;
  inherited Destroy;
end;

function TTarefaRepositoryFake.Localizar(const AId: Int64): TTarefa;
var
  LItem: TTarefa;
begin
  for LItem in FItens do
    if LItem.Id = AId then
      Exit(LItem);
  Result := nil;
end;

function TTarefaRepositoryFake.Listar(const AFiltro: TFiltroTarefas;
  const APaginacao: TParametrosPaginacao): TPaginaTarefas;
var
  LItem: TTarefa;
  LFiltrados: TList<TTarefa>;
  LBusca: string;
  I: Integer;
begin
  // Reproduz em memória o filtro e o OFFSET/FETCH do repositório SQL
  LBusca := AnsiLowerCase(AFiltro.Busca);
  LFiltrados := TList<TTarefa>.Create;
  try
    for LItem in FItens do
    begin
      if AFiltro.FiltrarPorStatus and (LItem.Status <> AFiltro.Status) then
        Continue;
      if AFiltro.FiltrarPorPrioridade and (LItem.Prioridade <> AFiltro.Prioridade) then
        Continue;
      if (LBusca <> '') and not AnsiLowerCase(LItem.Titulo).Contains(LBusca)
         and not AnsiLowerCase(LItem.Descricao).Contains(LBusca) then
        Continue;
      LFiltrados.Add(LItem);
    end;

    Result := TPaginaTarefas.Create;
    Result.DefinirPaginacao(APaginacao, LFiltrados.Count);
    I := APaginacao.Deslocamento;
    while (I < LFiltrados.Count) and (Result.Itens.Count < APaginacao.TamanhoPagina) do
    begin
      Result.Itens.Add(LFiltrados[I].Clone);
      Inc(I);
    end;
  finally
    LFiltrados.Free;
  end;
end;

function TTarefaRepositoryFake.ObterPorId(const AId: Int64): TTarefa;
var
  LItem: TTarefa;
begin
  LItem := Localizar(AId);
  if LItem = nil then
    Exit(nil);
  Result := LItem.Clone;
end;

function TTarefaRepositoryFake.Inserir(const ATarefa: TTarefa): Int64;
var
  LNova: TTarefa;
begin
  LNova := ATarefa.Clone;
  LNova.Id := FProximoId;
  LNova.CriadoEm := Now;
  LNova.AtualizadoEm := Now;
  if LNova.Status = stConcluida then
    LNova.DataConclusao := Now;
  FItens.Add(LNova);
  Result := FProximoId;
  Inc(FProximoId);
end;

function TTarefaRepositoryFake.AtualizarStatus(const AId: Int64; const AStatus: TEnumStatusTarefa): Boolean;
var
  LItem: TTarefa;
begin
  LItem := Localizar(AId);
  Result := LItem <> nil;
  if not Result then
    Exit;

  LItem.Status := AStatus;
  if AStatus = stConcluida then
    LItem.DataConclusao := Now
  else
    LItem.DataConclusao := 0;
end;

function TTarefaRepositoryFake.Excluir(const AId: Int64): Boolean;
var
  LItem: TTarefa;
begin
  LItem := Localizar(AId);
  Result := LItem <> nil;
  if Result then
    FItens.Remove(LItem);
end;

function TTarefaRepositoryFake.ObterEstatisticas: TEstatisticasTarefas;
var
  LItem: TTarefa;
  LSomaPendentes, LQtdPendentes: Integer;
begin
  // Reproduz em memória a mesma regra da consulta SQL_ESTATISTICAS
  Result := TEstatisticasTarefas.Create;
  LSomaPendentes := 0;
  LQtdPendentes := 0;
  Result.TotalTarefas := FItens.Count;
  for LItem in FItens do
  begin
    if LItem.Status = stPendente then
    begin
      Inc(LSomaPendentes, PrioridadeTarefaToInteger(LItem.Prioridade));
      Inc(LQtdPendentes);
    end;
    if (LItem.Status = stConcluida) and (LItem.DataConclusao >= IncDay(Now, -7)) then
      Result.ConcluidasUltimos7Dias := Result.ConcluidasUltimos7Dias + 1;
  end;
  if LQtdPendentes > 0 then
    Result.MediaPrioridadePendentes := LSomaPendentes / LQtdPendentes;
  Result.GeradoEm := Now;
end;

{ TTarefaServiceTests }

procedure TTarefaServiceTests.Setup;
begin
  FService := TTarefaService.Create(TTarefaRepositoryFake.Create);
end;

procedure TTarefaServiceTests.TearDown;
begin
  FService := nil;
end;

function TTarefaServiceTests.NovaTarefa(const ATitulo: string; const APrioridade: TEnumPrioridadeTarefa): TTarefa;
begin
  Result := TTarefa.Create;
  Result.Titulo := ATitulo;
  Result.Prioridade := APrioridade;
end;

function TTarefaServiceTests.CriarTarefa(const ATitulo: string; const APrioridade: TEnumPrioridadeTarefa): Int64;
var
  LEntrada, LCriada: TTarefa;
begin
  LEntrada := NovaTarefa(ATitulo, APrioridade);
  try
    LCriada := FService.Criar(LEntrada);
    try
      Result := LCriada.Id;
    finally
      LCriada.Free;
    end;
  finally
    LEntrada.Free;
  end;
end;

procedure TTarefaServiceTests.Criar_DeveCadastrar_QuandoDadosValidos;
var
  LEntrada, LCriada: TTarefa;
begin
  LEntrada := NovaTarefa('Implementar API', ptAlta);
  try
    LCriada := FService.Criar(LEntrada);
    try
      Assert.IsTrue(LCriada.Id > 0, 'Deveria gerar um id');
      Assert.AreEqual('Implementar API', LCriada.Titulo);
      Assert.AreEqual(Ord(stPendente), Ord(LCriada.Status), 'Nova tarefa deve iniciar PENDENTE');
      Assert.AreEqual(3, PrioridadeTarefaToInteger(LCriada.Prioridade));
    finally
      LCriada.Free;
    end;
  finally
    LEntrada.Free;
  end;
end;

procedure TTarefaServiceTests.Criar_DeveFalhar_QuandoTituloVazio;
var
  LEntrada: TTarefa;
begin
  LEntrada := NovaTarefa('   ');
  try
    Assert.WillRaise(
      procedure
      begin
        FService.Criar(LEntrada).Free;
      end, EValidacaoException);
  finally
    LEntrada.Free;
  end;
end;

procedure TTarefaServiceTests.Criar_DeveFalhar_QuandoTituloCurto;
var
  LEntrada: TTarefa;
begin
  LEntrada := NovaTarefa('ab');
  try
    Assert.WillRaise(
      procedure
      begin
        FService.Criar(LEntrada).Free;
      end, EValidacaoException);
  finally
    LEntrada.Free;
  end;
end;

function TTarefaServiceTests.ListarPagina(const APagina, ATamanho: Integer; const AStatus,
  ABusca, APrioridade: string): TPaginaTarefas;
begin
  Result := FService.Listar(AStatus, APrioridade, ABusca, TParametrosPaginacao.Criar(APagina, ATamanho));
end;

procedure TTarefaServiceTests.Listar_DeveFiltrarPorStatus;
var
  LIdConcluida: Int64;
  LPagina: TPaginaTarefas;
begin
  CriarTarefa('Tarefa pendente');
  LIdConcluida := CriarTarefa('Tarefa concluída');
  FService.AtualizarStatus(LIdConcluida, 'CONCLUIDA').Free;

  LPagina := ListarPagina(1, 20, 'concluida');
  try
    Assert.AreEqual(1, LPagina.TotalItens);
    Assert.IsTrue(LPagina.Itens[0].Id = LIdConcluida, 'Deveria retornar a tarefa concluída');
  finally
    LPagina.Free;
  end;

  LPagina := ListarPagina(1, 20);
  try
    Assert.AreEqual(2, LPagina.TotalItens, 'Sem filtro deve retornar todas');
  finally
    LPagina.Free;
  end;
end;

procedure TTarefaServiceTests.Listar_DeveFiltrarPorBusca;
var
  LPagina: TPaginaTarefas;
begin
  CriarTarefa('Gerar relatório mensal');
  CriarTarefa('Revisar contrato');

  LPagina := ListarPagina(1, 20, '', '  MENSAL  ');
  try
    Assert.AreEqual(1, LPagina.TotalItens, 'Busca deve ignorar maiúsculas e espaços nas pontas');
    Assert.AreEqual('Gerar relatório mensal', LPagina.Itens[0].Titulo);
  finally
    LPagina.Free;
  end;
end;

procedure TTarefaServiceTests.Listar_DeveFiltrarPorPrioridade;
var
  LIdUrgente: Int64;
  LPagina: TPaginaTarefas;
begin
  CriarTarefa('Tarefa baixa', ptBaixa);
  LIdUrgente := CriarTarefa('Tarefa urgente', ptUrgente);
  CriarTarefa('Tarefa média', ptMedia);

  LPagina := ListarPagina(1, 20, '', '', ' 4 ');
  try
    Assert.AreEqual(1, LPagina.TotalItens);
    Assert.IsTrue(LPagina.Itens[0].Id = LIdUrgente, 'Deveria retornar apenas a tarefa urgente');
  finally
    LPagina.Free;
  end;
end;

procedure TTarefaServiceTests.Listar_DeveFalhar_QuandoPrioridadeInvalida;
begin
  Assert.WillRaise(
    procedure
    begin
      ListarPagina(1, 20, '', '', '5').Free;
    end, EValidacaoException, 'Fora da faixa 1 a 4');
  Assert.WillRaise(
    procedure
    begin
      ListarPagina(1, 20, '', '', 'alta').Free;
    end, EValidacaoException, 'Não numérica');
end;

procedure TTarefaServiceTests.Listar_DeveFalhar_QuandoStatusInvalido;
begin
  Assert.WillRaise(
    procedure
    begin
      ListarPagina(1, 20, 'FINALIZADA').Free;
    end, EValidacaoException);
end;

procedure TTarefaServiceTests.Listar_DeveFalhar_QuandoBuscaMuitoLonga;
begin
  Assert.WillRaise(
    procedure
    begin
      ListarPagina(1, 20, '', StringOfChar('x', TAREFA_BUSCA_TAMANHO_MAXIMO + 1)).Free;
    end, EValidacaoException);
end;

procedure TTarefaServiceTests.Listar_DeveRespeitarTamanhoDaPagina;
var
  I: Integer;
  LPagina: TPaginaTarefas;
begin
  for I := 1 to 5 do
    CriarTarefa(Format('Tarefa %d', [I]));

  LPagina := ListarPagina(1, 2);
  try
    Assert.AreEqual(2, LPagina.Itens.Count, 'Página deve ter no máximo 2 itens');
    Assert.AreEqual(5, LPagina.TotalItens);
    Assert.AreEqual(3, LPagina.TotalPaginas, '5 itens / 2 por página = 3 páginas');
    Assert.IsFalse(LPagina.TemPaginaAnterior);
    Assert.IsTrue(LPagina.TemProximaPagina);
  finally
    LPagina.Free;
  end;
end;

procedure TTarefaServiceTests.Listar_UltimaPagina_DeveVirIncompleta;
var
  I: Integer;
  LPagina: TPaginaTarefas;
begin
  for I := 1 to 5 do
    CriarTarefa(Format('Tarefa %d', [I]));

  LPagina := ListarPagina(3, 2);
  try
    Assert.AreEqual(1, LPagina.Itens.Count, 'Última página deve ter o item restante');
    Assert.AreEqual('Tarefa 5', LPagina.Itens[0].Titulo);
    Assert.IsTrue(LPagina.TemPaginaAnterior);
    Assert.IsFalse(LPagina.TemProximaPagina);
  finally
    LPagina.Free;
  end;
end;

procedure TTarefaServiceTests.Listar_PaginaAlemDoFim_DeveVirVazia;
var
  I: Integer;
  LPagina: TPaginaTarefas;
begin
  for I := 1 to 5 do
    CriarTarefa(Format('Tarefa %d', [I]));

  LPagina := ListarPagina(4, 2);
  try
    Assert.AreEqual(0, LPagina.Itens.Count);
    Assert.AreEqual(5, LPagina.TotalItens, 'O total continua informado mesmo fora do intervalo');
  finally
    LPagina.Free;
  end;
end;

procedure TTarefaServiceTests.ObterPorId_DeveFalhar_QuandoNaoEncontrada;
begin
  Assert.WillRaise(
    procedure
    begin
      FService.ObterPorId(999).Free;
    end, ENaoEncontradoException);
end;

procedure TTarefaServiceTests.AtualizarStatus_DevePreencherDataConclusao_QuandoConcluida;
var
  LId: Int64;
  LAtualizada: TTarefa;
begin
  LId := CriarTarefa('Concluir esta tarefa');

  LAtualizada := FService.AtualizarStatus(LId, 'CONCLUIDA');
  try
    Assert.AreEqual(Ord(stConcluida), Ord(LAtualizada.Status));
    Assert.IsTrue(LAtualizada.DataConclusao > 0, 'Data de conclusão deve ser preenchida');
  finally
    LAtualizada.Free;
  end;

  LAtualizada := FService.AtualizarStatus(LId, 'PENDENTE');
  try
    Assert.IsTrue(LAtualizada.DataConclusao = 0, 'Reabrir deve limpar a data de conclusão');
  finally
    LAtualizada.Free;
  end;
end;

procedure TTarefaServiceTests.AtualizarStatus_DeveFalhar_QuandoStatusInvalido;
var
  LId: Int64;
begin
  LId := CriarTarefa('Status inválido');
  Assert.WillRaise(
    procedure
    begin
      FService.AtualizarStatus(LId, 'XPTO').Free;
    end, EValidacaoException);
end;

procedure TTarefaServiceTests.AtualizarStatus_DeveFalhar_QuandoCanceladaParaConcluida;
var
  LId: Int64;
begin
  LId := CriarTarefa('Tarefa cancelada');
  FService.AtualizarStatus(LId, 'CANCELADA').Free;

  Assert.WillRaise(
    procedure
    begin
      FService.AtualizarStatus(LId, 'CONCLUIDA').Free;
    end, ERegraNegocioException);
end;

procedure TTarefaServiceTests.Excluir_DeveRemover_QuandoExistente;
var
  LId: Int64;
begin
  LId := CriarTarefa('Tarefa a remover');
  FService.Excluir(LId);

  Assert.WillRaise(
    procedure
    begin
      FService.ObterPorId(LId).Free;
    end, ENaoEncontradoException);
end;

procedure TTarefaServiceTests.Excluir_DeveFalhar_QuandoNaoEncontrada;
begin
  Assert.WillRaise(
    procedure
    begin
      FService.Excluir(12345);
    end, ENaoEncontradoException);
end;

procedure TTarefaServiceTests.Estatisticas_DeveCalcularIndicadores;
var
  LIdConcluida: Int64;
  LEstatisticas: TEstatisticasTarefas;
begin
  CriarTarefa('Pendente baixa', ptBaixa);    // prioridade 1
  CriarTarefa('Pendente alta', ptAlta);      // prioridade 3
  LIdConcluida := CriarTarefa('Concluída hoje', ptUrgente);
  FService.AtualizarStatus(LIdConcluida, 'CONCLUIDA').Free;

  LEstatisticas := FService.ObterEstatisticas;
  try
    Assert.AreEqual(3, LEstatisticas.TotalTarefas);
    Assert.AreEqual(2.0, LEstatisticas.MediaPrioridadePendentes, 0.001);
    Assert.AreEqual(1, LEstatisticas.ConcluidasUltimos7Dias);
  finally
    LEstatisticas.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTarefaServiceTests);

end.
