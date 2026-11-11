unit PrioridadeTarefaEnum;

{ Prioridade da tarefa.
  No banco a prioridade é gravada como número (1 a 4) para permitir o cálculo
  da média (AVG) exigido no desafio SQL. O enum garante que apenas valores
  válidos circulem pelo código. }

interface

type
  TEnumPrioridadeTarefa = (ptBaixa, ptMedia, ptAlta, ptUrgente);

const
  PRIORIDADE_MINIMA = 1;
  PRIORIDADE_MAXIMA = 4;

function PrioridadeTarefaToInteger(const APrioridade: TEnumPrioridadeTarefa): Integer;
function PrioridadeTarefaToDescricao(const APrioridade: TEnumPrioridadeTarefa): string;
function IntegerToPrioridadeTarefa(const AValor: Integer): TEnumPrioridadeTarefa;
function PrioridadeValida(const AValor: Integer): Boolean;

implementation

uses
  System.SysUtils;

function PrioridadeTarefaToInteger(const APrioridade: TEnumPrioridadeTarefa): Integer;
begin
  Result := Ord(APrioridade) + 1;
end;

function PrioridadeTarefaToDescricao(const APrioridade: TEnumPrioridadeTarefa): string;
begin
  case APrioridade of
    ptBaixa:    Result := 'Baixa';
    ptMedia:    Result := 'Média';
    ptAlta:     Result := 'Alta';
    ptUrgente:  Result := 'Urgente';
  else
    Result := 'Média';
  end;
end;

function PrioridadeValida(const AValor: Integer): Boolean;
begin
  Result := (AValor >= PRIORIDADE_MINIMA) and (AValor <= PRIORIDADE_MAXIMA);
end;

function IntegerToPrioridadeTarefa(const AValor: Integer): TEnumPrioridadeTarefa;
begin
  if not PrioridadeValida(AValor) then
    raise EConvertError.CreateFmt(
      'Prioridade %d inválida. Informe um valor entre %d (Baixa) e %d (Urgente).',
      [AValor, PRIORIDADE_MINIMA, PRIORIDADE_MAXIMA]);

  Result := TEnumPrioridadeTarefa(AValor - 1);
end;

end.
