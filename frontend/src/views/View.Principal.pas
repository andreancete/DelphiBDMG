unit View.Principal;

{ Tela principal do cliente VCL.

  O formulário só coordena a interface; as responsabilidades ficam em:
  - TExecutorAssincrono   -> chamadas ao serviço em segundo plano;
  - TTarefaListViewAdapter -> montagem, filtro, seleção e cores da lista;
  - TComboEnumHelper      -> conversão combobox <-> enums;
  - TControlePaginacao    -> navegação entre páginas (reutilizável).

  Filtros, busca e paginação são aplicados no servidor; a tela guarda apenas
  a página atual.

  Nenhum dado é persistido localmente: tudo vem do serviço a cada atualização. }

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Vcl.ComCtrls,
  Vcl.Menus,
  Tarefa,
  EstatisticasTarefas,
  StatusTarefaEnum,
  TarefaRestClient.Interfaces,
  Paginacao,
  ExecutorAssincrono,
  TarefaListViewAdapter,
  ControlePaginacao;

type
  TFormPrincipal = class(TForm)
    pnlCabecalho: TPanel;
    lblTitulo: TLabel;
    lblSubtitulo: TLabel;
    lblStatusApi: TLabel;
    btnAtualizar: TButton;
    pnlIndicadores: TPanel;
    pnlCardTotal: TPanel;
    lblCardTotalTitulo: TLabel;
    lblTotalValor: TLabel;
    pnlCardMedia: TPanel;
    lblCardMediaTitulo: TLabel;
    lblMediaValor: TLabel;
    lblMediaLegenda: TLabel;
    pnlCardConcluidas: TPanel;
    lblCardConcluidasTitulo: TLabel;
    lblConcluidasValor: TLabel;
    lblConcluidasLegenda: TLabel;
    pnlGrade: TPanel;
    pnlFiltros: TPanel;
    lblFiltroBusca: TLabel;
    edtBusca: TEdit;
    lblFiltroStatus: TLabel;
    cmbFiltroStatus: TComboBox;
    lblFiltroPrioridade: TLabel;
    cmbFiltroPrioridade: TComboBox;
    lblContador: TLabel;
    pnlSeparadorFiltros: TPanel;
    lvTarefas: TListView;
    pnlSeparadorPaginacao: TPanel;
    pnlAcoes: TPanel;
    btnNova: TButton;
    lblNovoStatus: TLabel;
    cmbNovoStatus: TComboBox;
    btnAlterarStatus: TButton;
    btnRemover: TButton;
    sbStatus: TStatusBar;
    pmTarefas: TPopupMenu;
    miMarcarPendente: TMenuItem;
    miMarcarEmAndamento: TMenuItem;
    miMarcarConcluida: TMenuItem;
    miMarcarCancelada: TMenuItem;
    miSeparador: TMenuItem;
    miRemover: TMenuItem;
    pnlPaginacao: TPanel;
    btnPaginaAnterior: TButton;
    lblPaginacao: TLabel;
    btnPaginaProxima: TButton;
    lblItensPorPagina: TLabel;
    cmbTamanhoPagina: TComboBox;
    tmrBusca: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnAtualizarClick(Sender: TObject);
    procedure btnNovaClick(Sender: TObject);
    procedure btnAlterarStatusClick(Sender: TObject);
    procedure btnRemoverClick(Sender: TObject);
    procedure edtBuscaChange(Sender: TObject);
    procedure cmbFiltroChange(Sender: TObject);
    procedure lvTarefasSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure lvTarefasKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure pmTarefasPopup(Sender: TObject);
    procedure miMarcarStatusClick(Sender: TObject);
    procedure miRemoverClick(Sender: TObject);
    procedure tmrBuscaTimer(Sender: TObject);
  private
    FPagina: TPaginaTarefas;
    FExecutor: TExecutorAssincrono;
    FLista: TTarefaListViewAdapter;
    FPaginacao: TControlePaginacao;

    procedure AoMudarEstadoExecucao(const AOcupado: Boolean; const AMensagem: string);
    function ExecutarNoServico(const AMensagem: string; const AOperacao: TProc<ITarefaRestClient>;
      const ASucesso: TProc): Boolean;
    // Sem "const" para ser compatível com TProc<string> (callback de falha)
    procedure MostrarErro(AMensagem: string);
    procedure IndicarStatusApi(const AConectada: Boolean);
    procedure AtualizarBotoes;

    procedure CarregarDados;
    procedure RecarregarDaPrimeiraPagina;
    procedure AplicarDados(const APagina: TPaginaTarefas; const AEstatisticas: TEstatisticasTarefas);
    procedure ExibirEstatisticas(const AEstatisticas: TEstatisticasTarefas);
    procedure ExibirPagina(const AIdSelecionar: Int64);
    function FiltroAtual: TFiltroTarefas;

    procedure AlterarStatusSelecionada(const ANovoStatus: TEnumStatusTarefa);
    procedure RemoverSelecionada;
  end;

var
  FormPrincipal: TFormPrincipal;

implementation

{$R *.dfm}

uses
  System.UITypes,
  ComboEnumHelper,
  View.TarefaCadastro;

const
  // Cores do indicador de conexão (texto claro sobre o cabeçalho escuro)
  COR_API_CONECTADA    = TColor($0080E04A); // verde claro
  COR_API_INDISPONIVEL = TColor($006B6BF8); // vermelho claro

  SIMBOLO_STATUS_API = #9679' ';
  FORMATO_ATUALIZADO_EM = 'dd/mm/yyyy hh:nn:ss';
  SEM_VALOR = '-';

{ TFormPrincipal }

procedure TFormPrincipal.FormCreate(Sender: TObject);
begin
  FPagina := TPaginaTarefas.Create;
  FExecutor := TExecutorAssincrono.Create(AoMudarEstadoExecucao);
  FLista := TTarefaListViewAdapter.Create(lvTarefas);
  FPaginacao := TControlePaginacao.Create(btnPaginaAnterior, btnPaginaProxima, lblPaginacao,
    cmbTamanhoPagina, 'tarefa(s)', CarregarDados);

  TComboEnumHelper.PreencherStatus(cmbFiltroStatus, True);
  TComboEnumHelper.SelecionarTodos(cmbFiltroStatus);
  TComboEnumHelper.PreencherPrioridade(cmbFiltroPrioridade, True);
  TComboEnumHelper.SelecionarTodos(cmbFiltroPrioridade);
  TComboEnumHelper.PreencherStatus(cmbNovoStatus);
  TComboEnumHelper.SelecionarStatus(cmbNovoStatus, stConcluida);

  miMarcarPendente.Tag := Ord(stPendente);
  miMarcarEmAndamento.Tag := Ord(stEmAndamento);
  miMarcarConcluida.Tag := Ord(stConcluida);
  miMarcarCancelada.Tag := Ord(stCancelada);

  ExibirEstatisticas(nil);
  AtualizarBotoes;
end;

procedure TFormPrincipal.FormDestroy(Sender: TObject);
begin
  tmrBusca.Enabled := False;
  FLista.Limpar;
  FLista.Free;
  FPaginacao.Free;
  FExecutor.Free;
  FPagina.Free;
end;

procedure TFormPrincipal.FormShow(Sender: TObject);
begin
  CarregarDados;
end;

procedure TFormPrincipal.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  // Evita destruir a tela com uma requisição em andamento (o retorno
  // assíncrono tentaria atualizar componentes já liberados)
  CanClose := not FExecutor.Ocupado;
  if not CanClose then
    MessageDlg('Aguarde a conclusão da operação em andamento.', mtInformation, [mbOK], 0);
end;

procedure TFormPrincipal.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_F5 then
  begin
    Key := 0;
    CarregarDados;
  end;
end;

{ ---------- Execução e estado da tela ---------- }

procedure TFormPrincipal.AoMudarEstadoExecucao(const AOcupado: Boolean; const AMensagem: string);
begin
  btnAtualizar.Enabled := not AOcupado;
  btnNova.Enabled := not AOcupado;
  if AOcupado then
  begin
    Screen.Cursor := crAppStart;
    sbStatus.Panels[0].Text := AMensagem;
  end
  else
    Screen.Cursor := crDefault;
  FPaginacao.DefinirHabilitado(not AOcupado);
  AtualizarBotoes;
end;

function TFormPrincipal.ExecutarNoServico(const AMensagem: string;
  const AOperacao: TProc<ITarefaRestClient>; const ASucesso: TProc): Boolean;
begin
  Result := FExecutor.Executar(AMensagem, AOperacao, ASucesso, MostrarErro);
end;

procedure TFormPrincipal.MostrarErro(AMensagem: string);
begin
  sbStatus.Panels[0].Text := 'Falha na última operação.';
  MessageDlg(AMensagem, mtError, [mbOK], 0);
end;

procedure TFormPrincipal.IndicarStatusApi(const AConectada: Boolean);
begin
  if AConectada then
  begin
    lblStatusApi.Caption := SIMBOLO_STATUS_API + 'Serviço conectado';
    lblStatusApi.Font.Color := COR_API_CONECTADA;
  end
  else
  begin
    lblStatusApi.Caption := SIMBOLO_STATUS_API + 'Serviço indisponível';
    lblStatusApi.Font.Color := COR_API_INDISPONIVEL;
  end;
end;

procedure TFormPrincipal.AtualizarBotoes;
var
  LHabilitar: Boolean;
begin
  LHabilitar := (FLista.TarefaSelecionada <> nil) and not FExecutor.Ocupado;
  btnAlterarStatus.Enabled := LHabilitar;
  btnRemover.Enabled := LHabilitar;
  cmbNovoStatus.Enabled := LHabilitar;
end;

{ ---------- Carga de dados ---------- }

procedure TFormPrincipal.CarregarDados;
var
  LFiltro: TFiltroTarefas;
  LParametros: TParametrosPaginacao;
  LPagina: TPaginaTarefas;
  LEstatisticas: TEstatisticasTarefas;
begin
  // Filtro e página lidos na thread principal (componentes VCL)
  LFiltro := FiltroAtual;
  LParametros := FPaginacao.Parametros;
  LPagina := nil;
  LEstatisticas := nil;

  ExecutarNoServico('Consultando o serviço...',
    procedure(AClient: ITarefaRestClient)
    begin
      try
        LPagina := AClient.Listar(LFiltro, LParametros);
        LEstatisticas := AClient.ObterEstatisticas;
      except
        FreeAndNil(LPagina);
        FreeAndNil(LEstatisticas);
        TThread.Queue(nil,
          procedure
          begin
            IndicarStatusApi(False);
          end);
        raise;
      end;
    end,
    procedure
    begin
      AplicarDados(LPagina, LEstatisticas);
    end);
end;

procedure TFormPrincipal.RecarregarDaPrimeiraPagina;
begin
  FPaginacao.VoltarParaPrimeira;
  CarregarDados;
end;

procedure TFormPrincipal.AplicarDados(const APagina: TPaginaTarefas; const AEstatisticas: TEstatisticasTarefas);
var
  LIdSelecionado: Int64;
begin
  try
    IndicarStatusApi(True);
    ExibirEstatisticas(AEstatisticas);

    // Página pedida ficou além do fim (ex.: excluído o último item da última
    // página): o controle já voltou para a última página válida; recarrega
    if not FPaginacao.Atualizar(APagina.Pagina, APagina.TotalPaginas, APagina.TotalItens) then
    begin
      APagina.Free;
      CarregarDados;
      Exit;
    end;

    // Limpa a lista ANTES de liberar a página antiga (os itens apontam para ela)
    LIdSelecionado := FLista.IdSelecionado;
    FLista.Limpar;
    FPagina.Free;
    FPagina := APagina;

    ExibirPagina(LIdSelecionado);
    sbStatus.Panels[0].Text := 'Dados atualizados em ' + FormatDateTime(FORMATO_ATUALIZADO_EM, Now) + '.';
  finally
    AEstatisticas.Free;
  end;
end;

procedure TFormPrincipal.ExibirEstatisticas(const AEstatisticas: TEstatisticasTarefas);
begin
  if AEstatisticas = nil then
  begin
    lblTotalValor.Caption := SEM_VALOR;
    lblMediaValor.Caption := SEM_VALOR;
    lblConcluidasValor.Caption := SEM_VALOR;
    Exit;
  end;

  lblTotalValor.Caption := IntToStr(AEstatisticas.TotalTarefas);
  lblConcluidasValor.Caption := IntToStr(AEstatisticas.ConcluidasUltimos7Dias);

  if AEstatisticas.MediaPrioridadePendentes > 0 then
    lblMediaValor.Caption := FormatFloat('0.00', AEstatisticas.MediaPrioridadePendentes)
  else
    lblMediaValor.Caption := SEM_VALOR;
end;

function TFormPrincipal.FiltroAtual: TFiltroTarefas;
begin
  Result := TFiltroTarefas.Nenhum;
  Result.Busca := Trim(edtBusca.Text);
  Result.FiltrarPorStatus := TComboEnumHelper.TryObterStatus(cmbFiltroStatus, Result.Status);
  Result.FiltrarPorPrioridade := TComboEnumHelper.TryObterPrioridade(cmbFiltroPrioridade, Result.Prioridade);
end;

procedure TFormPrincipal.ExibirPagina(const AIdSelecionar: Int64);
begin
  FLista.Preencher(FPagina.Itens, AIdSelecionar);
  lblContador.Caption := Format('%d tarefa(s) encontrada(s)', [FPagina.TotalItens]);
  AtualizarBotoes;
end;

{ ---------- Eventos da lista e filtros ---------- }

procedure TFormPrincipal.edtBuscaChange(Sender: TObject);
begin
  // Espera o usuário parar de digitar (Interval do timer) antes de consultar,
  // evitando uma requisição por tecla
  tmrBusca.Enabled := False;
  tmrBusca.Enabled := True;
end;

procedure TFormPrincipal.tmrBuscaTimer(Sender: TObject);
begin
  // Se houver consulta em andamento, o timer continua ativo e tenta de novo
  if FExecutor.Ocupado then
    Exit;
  tmrBusca.Enabled := False;
  RecarregarDaPrimeiraPagina;
end;

procedure TFormPrincipal.cmbFiltroChange(Sender: TObject);
begin
  // Compartilhado pelos combos de status e de prioridade
  RecarregarDaPrimeiraPagina;
end;

procedure TFormPrincipal.lvTarefasSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
begin
  if Selected and (FLista.TarefaSelecionada <> nil) then
    TComboEnumHelper.SelecionarStatus(cmbNovoStatus, FLista.TarefaSelecionada.Status);
  AtualizarBotoes;
end;

procedure TFormPrincipal.lvTarefasKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_DELETE) and btnRemover.Enabled then
    RemoverSelecionada;
end;

procedure TFormPrincipal.pmTarefasPopup(Sender: TObject);
var
  LTarefa: TTarefa;
  LHabilitar: Boolean;
begin
  LTarefa := FLista.TarefaSelecionada;
  LHabilitar := (LTarefa <> nil) and not FExecutor.Ocupado;

  miMarcarPendente.Enabled := LHabilitar and (LTarefa.Status <> stPendente);
  miMarcarEmAndamento.Enabled := LHabilitar and (LTarefa.Status <> stEmAndamento);
  miMarcarConcluida.Enabled := LHabilitar and (LTarefa.Status <> stConcluida);
  miMarcarCancelada.Enabled := LHabilitar and (LTarefa.Status <> stCancelada);
  miRemover.Enabled := LHabilitar;
end;

{ ---------- Ações ---------- }

procedure TFormPrincipal.btnAtualizarClick(Sender: TObject);
begin
  CarregarDados;
end;

procedure TFormPrincipal.btnNovaClick(Sender: TObject);
var
  LNova: TTarefa;
begin
  if not TFormTarefaCadastro.Executar(Self, LNova) then
    Exit;

  if not ExecutarNoServico('Cadastrando tarefa...',
    procedure(AClient: ITarefaRestClient)
    begin
      try
        AClient.Criar(LNova).Free;
      finally
        LNova.Free;
      end;
    end,
    CarregarDados) then
    LNova.Free; // operação não iniciada: libera aqui
end;

procedure TFormPrincipal.AlterarStatusSelecionada(const ANovoStatus: TEnumStatusTarefa);
var
  LTarefa: TTarefa;
  LId: Int64;
begin
  LTarefa := FLista.TarefaSelecionada;
  if LTarefa = nil then
    Exit;

  if LTarefa.Status = ANovoStatus then
  begin
    sbStatus.Panels[0].Text := 'A tarefa já está com esse status.';
    Exit;
  end;

  LId := LTarefa.Id;
  ExecutarNoServico('Atualizando status...',
    procedure(AClient: ITarefaRestClient)
    begin
      AClient.AtualizarStatus(LId, ANovoStatus).Free;
    end,
    CarregarDados);
end;

procedure TFormPrincipal.btnAlterarStatusClick(Sender: TObject);
var
  LStatus: TEnumStatusTarefa;
begin
  if TComboEnumHelper.TryObterStatus(cmbNovoStatus, LStatus) then
    AlterarStatusSelecionada(LStatus);
end;

procedure TFormPrincipal.miMarcarStatusClick(Sender: TObject);
begin
  AlterarStatusSelecionada(TEnumStatusTarefa((Sender as TMenuItem).Tag));
end;

procedure TFormPrincipal.RemoverSelecionada;
var
  LTarefa: TTarefa;
  LId: Int64;
begin
  LTarefa := FLista.TarefaSelecionada;
  if LTarefa = nil then
    Exit;

  if MessageDlg(Format('Remover a tarefa #%d "%s"?', [LTarefa.Id, LTarefa.Titulo]),
       mtConfirmation, [mbYes, mbNo], 0, mbNo) <> mrYes then
    Exit;

  LId := LTarefa.Id;
  ExecutarNoServico('Removendo tarefa...',
    procedure(AClient: ITarefaRestClient)
    begin
      AClient.Excluir(LId);
    end,
    CarregarDados);
end;

procedure TFormPrincipal.btnRemoverClick(Sender: TObject);
begin
  RemoverSelecionada;
end;

procedure TFormPrincipal.miRemoverClick(Sender: TObject);
begin
  RemoverSelecionada;
end;

end.
