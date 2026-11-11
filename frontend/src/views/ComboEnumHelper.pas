unit ComboEnumHelper;

{ Liga TComboBox aos enums do domínio sem depender da ordem dos itens.

  O valor ordinal do enum é guardado em Items.Objects; assim a tela pode
  reordenar, renomear ou acrescentar itens (como "Todos") sem quebrar a
  conversão item <-> enum. }

interface

uses
  Vcl.StdCtrls,
  StatusTarefaEnum,
  PrioridadeTarefaEnum;

type
  TComboEnumHelper = class
  private
    class procedure AdicionarItem(const ACombo: TComboBox; const ATexto: string; const AValor: Integer);
    class function TryObterValor(const ACombo: TComboBox; out AValor: Integer): Boolean;
    class procedure SelecionarValor(const ACombo: TComboBox; const AValor: Integer);
  public
    // Status
    class procedure PreencherStatus(const ACombo: TComboBox; const AIncluirTodos: Boolean = False);
    class procedure SelecionarStatus(const ACombo: TComboBox; const AStatus: TEnumStatusTarefa);
    class procedure SelecionarTodos(const ACombo: TComboBox);
    // False quando nada está selecionado ou a opção é "Todos"
    class function TryObterStatus(const ACombo: TComboBox; out AStatus: TEnumStatusTarefa): Boolean;

    // Prioridade
    class procedure PreencherPrioridade(const ACombo: TComboBox; const AIncluirTodas: Boolean = False);
    class procedure SelecionarPrioridade(const ACombo: TComboBox; const APrioridade: TEnumPrioridadeTarefa);
    class function TryObterPrioridade(const ACombo: TComboBox; out APrioridade: TEnumPrioridadeTarefa): Boolean;
  end;

implementation

uses
  System.SysUtils;

const
  // Valor guardado no item "Todos" (não corresponde a nenhum enum)
  VALOR_TODOS = -1;

{ TComboEnumHelper }

class procedure TComboEnumHelper.AdicionarItem(const ACombo: TComboBox; const ATexto: string; const AValor: Integer);
begin
  ACombo.Items.AddObject(ATexto, TObject(NativeInt(AValor)));
end;

class function TComboEnumHelper.TryObterValor(const ACombo: TComboBox; out AValor: Integer): Boolean;
begin
  AValor := VALOR_TODOS;
  Result := ACombo.ItemIndex >= 0;
  if Result then
    AValor := Integer(NativeInt(ACombo.Items.Objects[ACombo.ItemIndex]));
end;

class procedure TComboEnumHelper.SelecionarValor(const ACombo: TComboBox; const AValor: Integer);
var
  I: Integer;
begin
  for I := 0 to ACombo.Items.Count - 1 do
    if Integer(NativeInt(ACombo.Items.Objects[I])) = AValor then
    begin
      ACombo.ItemIndex := I;
      Exit;
    end;
  ACombo.ItemIndex := -1;
end;

class procedure TComboEnumHelper.PreencherStatus(const ACombo: TComboBox; const AIncluirTodos: Boolean);
var
  LStatus: TEnumStatusTarefa;
begin
  ACombo.Items.BeginUpdate;
  try
    ACombo.Items.Clear;
    if AIncluirTodos then
      AdicionarItem(ACombo, 'Todos os status', VALOR_TODOS);
    for LStatus := Low(TEnumStatusTarefa) to High(TEnumStatusTarefa) do
      AdicionarItem(ACombo, StatusTarefaToDescricao(LStatus), Ord(LStatus));
  finally
    ACombo.Items.EndUpdate;
  end;
end;

class procedure TComboEnumHelper.SelecionarStatus(const ACombo: TComboBox; const AStatus: TEnumStatusTarefa);
begin
  SelecionarValor(ACombo, Ord(AStatus));
end;

class procedure TComboEnumHelper.SelecionarTodos(const ACombo: TComboBox);
begin
  SelecionarValor(ACombo, VALOR_TODOS);
end;

class function TComboEnumHelper.TryObterStatus(const ACombo: TComboBox; out AStatus: TEnumStatusTarefa): Boolean;
var
  LValor: Integer;
begin
  AStatus := Low(TEnumStatusTarefa);
  Result := TryObterValor(ACombo, LValor) and (LValor <> VALOR_TODOS);
  if Result then
    AStatus := TEnumStatusTarefa(LValor);
end;

class procedure TComboEnumHelper.PreencherPrioridade(const ACombo: TComboBox; const AIncluirTodas: Boolean);
var
  LPrioridade: TEnumPrioridadeTarefa;
begin
  ACombo.Items.BeginUpdate;
  try
    ACombo.Items.Clear;
    if AIncluirTodas then
      AdicionarItem(ACombo, 'Todas as prioridades', VALOR_TODOS);
    for LPrioridade := Low(TEnumPrioridadeTarefa) to High(TEnumPrioridadeTarefa) do
      AdicionarItem(ACombo,
        Format('%d - %s', [PrioridadeTarefaToInteger(LPrioridade), PrioridadeTarefaToDescricao(LPrioridade)]),
        Ord(LPrioridade));
  finally
    ACombo.Items.EndUpdate;
  end;
end;

class procedure TComboEnumHelper.SelecionarPrioridade(const ACombo: TComboBox; const APrioridade: TEnumPrioridadeTarefa);
begin
  SelecionarValor(ACombo, Ord(APrioridade));
end;

class function TComboEnumHelper.TryObterPrioridade(const ACombo: TComboBox;
  out APrioridade: TEnumPrioridadeTarefa): Boolean;
var
  LValor: Integer;
begin
  APrioridade := ptMedia;
  Result := TryObterValor(ACombo, LValor) and (LValor <> VALOR_TODOS);
  if Result then
    APrioridade := TEnumPrioridadeTarefa(LValor);
end;

end.
