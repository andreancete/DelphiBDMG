unit ControlePaginacao;

{ Controle de navegação entre páginas, reutilizável por qualquer tela VCL.

  Recebe os componentes da tela (botões Anterior/Próxima, rótulo de resumo e
  combo de itens por página), assume os eventos deles e avisa a tela, por
  AAoMudarPagina, quando precisa recarregar. A tela só informa o resultado de
  cada consulta em Atualizar. }

interface

uses
  System.SysUtils,
  Vcl.StdCtrls,
  Paginacao;

type
  TControlePaginacao = class
  private
    FBotaoAnterior: TButton;
    FBotaoProxima: TButton;
    FResumo: TLabel;
    FComboTamanho: TComboBox;
    FAoMudarPagina: TProc;
    FNomeItens: string;
    FPagina: Integer;
    FTotalPaginas: Integer;
    FHabilitado: Boolean;
    procedure PreencherComboTamanho;
    function TamanhoSelecionado: Integer;
    procedure AtualizarBotoes;
    procedure BotaoAnteriorClick(Sender: TObject);
    procedure BotaoProximaClick(Sender: TObject);
    procedure ComboTamanhoChange(Sender: TObject);
  public
    // ANomeItens aparece no resumo, ex.: 'tarefa(s)' -> "Página 2 de 3 (57 tarefa(s))"
    constructor Create(const ABotaoAnterior, ABotaoProxima: TButton; const AResumo: TLabel;
      const AComboTamanho: TComboBox; const ANomeItens: string; const AAoMudarPagina: TProc);
    destructor Destroy; override;

    // Página e tamanho a pedir na próxima consulta
    function Parametros: TParametrosPaginacao;
    procedure VoltarParaPrimeira;

    // Informa o resultado da consulta. Retorna False quando a página pedida
    // ficou além do fim (ex.: o último item da última página foi excluído);
    // nesse caso o controle já voltou para a última página e a tela deve recarregar.
    function Atualizar(const APagina, ATotalPaginas, ATotalItens: Integer): Boolean;

    // Desabilita a navegação enquanto uma requisição está em andamento
    procedure DefinirHabilitado(const AHabilitado: Boolean);
  end;

implementation

const
  OPCOES_TAMANHO: array[0..3] of Integer = (10, 20, 50, TAMANHO_PAGINA_MAXIMO);

{ TControlePaginacao }

constructor TControlePaginacao.Create(const ABotaoAnterior, ABotaoProxima: TButton; const AResumo: TLabel;
  const AComboTamanho: TComboBox; const ANomeItens: string; const AAoMudarPagina: TProc);
begin
  inherited Create;
  FBotaoAnterior := ABotaoAnterior;
  FBotaoProxima := ABotaoProxima;
  FResumo := AResumo;
  FComboTamanho := AComboTamanho;
  FNomeItens := ANomeItens;
  FAoMudarPagina := AAoMudarPagina;
  FPagina := PAGINA_PADRAO;
  FTotalPaginas := 0;
  FHabilitado := True;

  PreencherComboTamanho;
  FBotaoAnterior.OnClick := BotaoAnteriorClick;
  FBotaoProxima.OnClick := BotaoProximaClick;
  FComboTamanho.OnChange := ComboTamanhoChange;
  AtualizarBotoes;
end;

destructor TControlePaginacao.Destroy;
begin
  // Desliga os eventos para os componentes não chamarem um objeto já liberado
  FBotaoAnterior.OnClick := nil;
  FBotaoProxima.OnClick := nil;
  FComboTamanho.OnChange := nil;
  inherited Destroy;
end;

procedure TControlePaginacao.PreencherComboTamanho;
var
  LTamanho: Integer;
begin
  FComboTamanho.Items.Clear;
  for LTamanho in OPCOES_TAMANHO do
  begin
    FComboTamanho.Items.Add(IntToStr(LTamanho));
    if LTamanho = TAMANHO_PAGINA_PADRAO then
      FComboTamanho.ItemIndex := FComboTamanho.Items.Count - 1;
  end;
end;

function TControlePaginacao.TamanhoSelecionado: Integer;
begin
  Result := StrToIntDef(FComboTamanho.Text, TAMANHO_PAGINA_PADRAO);
end;

function TControlePaginacao.Parametros: TParametrosPaginacao;
begin
  Result := TParametrosPaginacao.Criar(FPagina, TamanhoSelecionado);
end;

procedure TControlePaginacao.VoltarParaPrimeira;
begin
  FPagina := PAGINA_PADRAO;
end;

function TControlePaginacao.Atualizar(const APagina, ATotalPaginas, ATotalItens: Integer): Boolean;
begin
  FTotalPaginas := ATotalPaginas;
  Result := (APagina <= ATotalPaginas) or (ATotalPaginas = 0);
  if not Result then
  begin
    FPagina := ATotalPaginas;
    Exit;
  end;

  FPagina := APagina;
  if ATotalPaginas = 0 then
    FResumo.Caption := 'Nenhum resultado'
  else
    FResumo.Caption := Format('Página %d de %d (%d %s)', [FPagina, FTotalPaginas, ATotalItens, FNomeItens]);
  AtualizarBotoes;
end;

procedure TControlePaginacao.DefinirHabilitado(const AHabilitado: Boolean);
begin
  FHabilitado := AHabilitado;
  FComboTamanho.Enabled := AHabilitado;
  AtualizarBotoes;
end;

procedure TControlePaginacao.AtualizarBotoes;
begin
  FBotaoAnterior.Enabled := FHabilitado and (FPagina > 1);
  FBotaoProxima.Enabled := FHabilitado and (FPagina < FTotalPaginas);
end;

procedure TControlePaginacao.BotaoAnteriorClick(Sender: TObject);
begin
  if FPagina <= 1 then
    Exit;
  Dec(FPagina);
  FAoMudarPagina();
end;

procedure TControlePaginacao.BotaoProximaClick(Sender: TObject);
begin
  if FPagina >= FTotalPaginas then
    Exit;
  Inc(FPagina);
  FAoMudarPagina();
end;

procedure TControlePaginacao.ComboTamanhoChange(Sender: TObject);
begin
  // Novo tamanho muda a quantidade de páginas: recomeça da primeira
  VoltarParaPrimeira;
  FAoMudarPagina();
end;

end.
