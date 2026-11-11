unit TarefaListViewAdapter;

{ Adaptador entre a lista de tarefas (models) e o TListView da tela.
  Concentra montagem das linhas, seleção e cores por status, tirando essas
  responsabilidades do formulário. O filtro é feito no servidor (paginação). }

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Vcl.ComCtrls,
  Tarefa,
  StatusTarefaEnum;

type
  TTarefaListViewAdapter = class
  private
    FListView: TListView;
    procedure AdicionarLinha(const ATarefa: TTarefa);
    procedure DesenharSubItem(Sender: TCustomListView; Item: TListItem;
      SubItem: Integer; State: TCustomDrawState; var DefaultDraw: Boolean);
  public
    constructor Create(const AListView: TListView);
    destructor Destroy; override;

    // AIdSelecionar: id a manter selecionado após preencher (0 = nenhum)
    procedure Preencher(const ATarefas: TObjectList<TTarefa>; const AIdSelecionar: Int64);
    // Limpa as linhas. Chamar antes de liberar os objetos exibidos, pois cada
    // item do TListView guarda um ponteiro (Data) para a tarefa.
    procedure Limpar;
    function TarefaSelecionada: TTarefa;
    function IdSelecionado: Int64;
  end;

implementation

uses
  Vcl.Graphics,
  PrioridadeTarefaEnum;

const
  FORMATO_DATA_HORA = 'dd/mm/yyyy hh:nn';
  SEM_DATA = '-';

  // Índices das colunas no OnCustomDrawSubItem: 0 = Caption (ID), 1.. = SubItems
  COLUNA_STATUS = 4;

  COR_PENDENTE     = TColor($000677D9); // âmbar
  COR_EM_ANDAMENTO = TColor($00EB6325); // azul
  COR_CONCLUIDA    = TColor($004AA316); // verde
  COR_CANCELADA    = TColor($008B7464); // cinza

function CorDoStatus(const AStatus: TEnumStatusTarefa): TColor;
begin
  case AStatus of
    stPendente:    Result := COR_PENDENTE;
    stEmAndamento: Result := COR_EM_ANDAMENTO;
    stConcluida:   Result := COR_CONCLUIDA;
    stCancelada:   Result := COR_CANCELADA;
  else
    Result := clWindowText;
  end;
end;

function FormatarData(const AData: TDateTime): string;
begin
  if AData > 0 then
    Result := FormatDateTime(FORMATO_DATA_HORA, AData)
  else
    Result := SEM_DATA;
end;

{ TTarefaListViewAdapter }

constructor TTarefaListViewAdapter.Create(const AListView: TListView);
begin
  inherited Create;
  FListView := AListView;
  FListView.OnCustomDrawSubItem := DesenharSubItem;
end;

destructor TTarefaListViewAdapter.Destroy;
begin
  // Desliga o evento para o TListView não chamar um objeto já liberado
  FListView.OnCustomDrawSubItem := nil;
  inherited Destroy;
end;

procedure TTarefaListViewAdapter.AdicionarLinha(const ATarefa: TTarefa);
var
  LItem: TListItem;
begin
  LItem := FListView.Items.Add;
  LItem.Caption := IntToStr(ATarefa.Id);
  LItem.SubItems.Add(ATarefa.Titulo);
  LItem.SubItems.Add(PrioridadeTarefaToDescricao(ATarefa.Prioridade));
  LItem.SubItems.Add(FormatarData(ATarefa.CriadoEm));
  LItem.SubItems.Add(StatusTarefaToDescricao(ATarefa.Status));
  LItem.SubItems.Add(FormatarData(ATarefa.DataConclusao));
  LItem.Data := ATarefa;
end;

procedure TTarefaListViewAdapter.Preencher(const ATarefas: TObjectList<TTarefa>;
  const AIdSelecionar: Int64);
var
  LTarefa: TTarefa;
begin
  FListView.Items.BeginUpdate;
  try
    FListView.Items.Clear;
    for LTarefa in ATarefas do
    begin
      AdicionarLinha(LTarefa);
      if LTarefa.Id = AIdSelecionar then
        FListView.Items[FListView.Items.Count - 1].Selected := True;
    end;
  finally
    FListView.Items.EndUpdate;
  end;
end;

procedure TTarefaListViewAdapter.Limpar;
begin
  FListView.Items.Clear;
end;

function TTarefaListViewAdapter.TarefaSelecionada: TTarefa;
begin
  if Assigned(FListView.Selected) then
    Result := TTarefa(FListView.Selected.Data)
  else
    Result := nil;
end;

function TTarefaListViewAdapter.IdSelecionado: Int64;
begin
  if TarefaSelecionada <> nil then
    Result := TarefaSelecionada.Id
  else
    Result := 0;
end;

procedure TTarefaListViewAdapter.DesenharSubItem(Sender: TCustomListView; Item: TListItem;
  SubItem: Integer; State: TCustomDrawState; var DefaultDraw: Boolean);
var
  LTarefa: TTarefa;
begin
  Sender.Canvas.Font.Style := [];
  Sender.Canvas.Font.Color := clWindowText;

  LTarefa := TTarefa(Item.Data);
  if (SubItem <> COLUNA_STATUS) or (LTarefa = nil) then
    Exit;

  Sender.Canvas.Font.Style := [fsBold];
  Sender.Canvas.Font.Color := CorDoStatus(LTarefa.Status);
end;

end.
