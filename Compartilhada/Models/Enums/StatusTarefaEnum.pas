unit StatusTarefaEnum;

{ Status possíveis de uma tarefa.
  A conversão enum <-> string fica centralizada aqui para que Controllers,
  Repositories e o cliente VCL nunca trafeguem o ordinal bruto do enum. }

interface

type
  TEnumStatusTarefa = (stPendente, stEmAndamento, stConcluida, stCancelada);

const
  STATUS_TAREFA_PENDENTE     = 'PENDENTE';
  STATUS_TAREFA_EM_ANDAMENTO = 'EM_ANDAMENTO';
  STATUS_TAREFA_CONCLUIDA    = 'CONCLUIDA';
  STATUS_TAREFA_CANCELADA    = 'CANCELADA';

function StatusTarefaToString(const AStatus: TEnumStatusTarefa): string;
function StatusTarefaToDescricao(const AStatus: TEnumStatusTarefa): string;
function StringToStatusTarefa(const AValor: string): TEnumStatusTarefa;
function TryStringToStatusTarefa(const AValor: string; out AStatus: TEnumStatusTarefa): Boolean;

implementation

uses
  System.SysUtils;

function StatusTarefaToString(const AStatus: TEnumStatusTarefa): string;
begin
  case AStatus of
    stPendente:     Result := STATUS_TAREFA_PENDENTE;
    stEmAndamento:  Result := STATUS_TAREFA_EM_ANDAMENTO;
    stConcluida:    Result := STATUS_TAREFA_CONCLUIDA;
    stCancelada:    Result := STATUS_TAREFA_CANCELADA;
  else
    Result := STATUS_TAREFA_PENDENTE;
  end;
end;

function StatusTarefaToDescricao(const AStatus: TEnumStatusTarefa): string;
begin
  case AStatus of
    stPendente:     Result := 'Pendente';
    stEmAndamento:  Result := 'Em andamento';
    stConcluida:    Result := 'Concluída';
    stCancelada:    Result := 'Cancelada';
  else
    Result := 'Pendente';
  end;
end;

function TryStringToStatusTarefa(const AValor: string; out AStatus: TEnumStatusTarefa): Boolean;
var
  LValor: string;
begin
  LValor := AValor.Trim.ToUpper;
  Result := True;
  if LValor = STATUS_TAREFA_PENDENTE then
    AStatus := stPendente
  else if LValor = STATUS_TAREFA_EM_ANDAMENTO then
    AStatus := stEmAndamento
  else if LValor = STATUS_TAREFA_CONCLUIDA then
    AStatus := stConcluida
  else if LValor = STATUS_TAREFA_CANCELADA then
    AStatus := stCancelada
  else
  begin
    AStatus := stPendente;
    Result := False;
  end;
end;

function StringToStatusTarefa(const AValor: string): TEnumStatusTarefa;
begin
  if not TryStringToStatusTarefa(AValor, Result) then
    raise EConvertError.CreateFmt(
      'Status "%s" inválido. Valores aceitos: PENDENTE, EM_ANDAMENTO, CONCLUIDA, CANCELADA.', [AValor]);
end;

end.
