unit View.TarefaCadastro;

{ Diálogo modal de cadastro de tarefa.
  Não duplica regras de validação: monta o TTarefa e chama TTarefa.Validar,
  a mesma regra (unit compartilhada) que a API aplica. }

interface

uses
  Winapi.Windows,
  System.SysUtils,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Tarefa;

type
  TFormTarefaCadastro = class(TForm)
    pnlConteudo: TPanel;
    lblTitulo: TLabel;
    edtTitulo: TEdit;
    lblDescricao: TLabel;
    memDescricao: TMemo;
    lblPrioridade: TLabel;
    cmbPrioridade: TComboBox;
    lblContadorDescricao: TLabel;
    pnlBotoes: TPanel;
    btnSalvar: TButton;
    btnCancelar: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnSalvarClick(Sender: TObject);
    procedure memDescricaoChange(Sender: TObject);
  private
    // Tarefa confirmada; a posse passa ao chamador em Executar
    FTarefa: TTarefa;
    function MontarTarefa: TTarefa;
  public
    // Retorna True e uma nova instância em ATarefa (o chamador libera) quando o usuário confirma
    class function Executar(const AOwner: TComponent; out ATarefa: TTarefa): Boolean;
  end;

implementation

{$R *.dfm}

uses
  System.UITypes,
  PrioridadeTarefaEnum,
  ComboEnumHelper;

{ TFormTarefaCadastro }

class function TFormTarefaCadastro.Executar(const AOwner: TComponent; out ATarefa: TTarefa): Boolean;
var
  LForm: TFormTarefaCadastro;
begin
  ATarefa := nil;
  LForm := TFormTarefaCadastro.Create(AOwner);
  try
    Result := LForm.ShowModal = mrOk;
    if Result then
    begin
      ATarefa := LForm.FTarefa;
      LForm.FTarefa := nil;
    end;
  finally
    LForm.Free;
  end;
end;

procedure TFormTarefaCadastro.FormCreate(Sender: TObject);
begin
  TComboEnumHelper.PreencherPrioridade(cmbPrioridade);
  TComboEnumHelper.SelecionarPrioridade(cmbPrioridade, ptMedia);

  edtTitulo.MaxLength := TAREFA_TITULO_TAMANHO_MAXIMO;
  memDescricao.MaxLength := TAREFA_DESCRICAO_TAMANHO_MAXIMO;
  memDescricaoChange(nil);
end;

procedure TFormTarefaCadastro.FormDestroy(Sender: TObject);
begin
  FTarefa.Free; // só existe aqui se o diálogo não foi confirmado
end;

procedure TFormTarefaCadastro.memDescricaoChange(Sender: TObject);
begin
  lblContadorDescricao.Caption := Format('%d / %d', [Length(memDescricao.Text), TAREFA_DESCRICAO_TAMANHO_MAXIMO]);
end;

function TFormTarefaCadastro.MontarTarefa: TTarefa;
var
  LPrioridade: TEnumPrioridadeTarefa;
begin
  Result := TTarefa.Create;
  Result.Titulo := Trim(edtTitulo.Text);
  Result.Descricao := Trim(memDescricao.Text);
  if TComboEnumHelper.TryObterPrioridade(cmbPrioridade, LPrioridade) then
    Result.Prioridade := LPrioridade;
end;

procedure TFormTarefaCadastro.btnSalvarClick(Sender: TObject);
var
  LTarefa: TTarefa;
begin
  LTarefa := MontarTarefa;
  try
    LTarefa.Validar;
  except
    on E: EArgumentException do
    begin
      LTarefa.Free;
      MessageDlg(E.Message, mtWarning, [mbOK], 0);
      edtTitulo.SetFocus;
      Exit;
    end;
  end;

  FTarefa.Free;
  FTarefa := LTarefa;
  ModalResult := mrOk;
end;

end.
