unit EstatisticasTarefas;

{ Resultado do "Desafio SQL": indicadores calculados no SQL Server e
  devolvidos pela API em GET /api/estatisticas/tarefas. }

interface

uses
  System.SysUtils,
  System.JSON,
  BaseModel;

type
  TEstatisticasTarefas = class(TModeloJSON)
  private
    FTotalTarefas: Integer;
    FMediaPrioridadePendentes: Double;
    FConcluidasUltimos7Dias: Integer;
    FGeradoEm: TDateTime;
  public
    procedure CarregarDeJSON(const AJSON: TJSONObject); override;
    function ToJSONObject: TJSONObject; override;

    property TotalTarefas: Integer read FTotalTarefas write FTotalTarefas;
    // 0 quando não existem tarefas pendentes (AVG retorna NULL no SQL)
    property MediaPrioridadePendentes: Double read FMediaPrioridadePendentes write FMediaPrioridadePendentes;
    property ConcluidasUltimos7Dias: Integer read FConcluidasUltimos7Dias write FConcluidasUltimos7Dias;
    property GeradoEm: TDateTime read FGeradoEm write FGeradoEm;
  end;

implementation

{ TEstatisticasTarefas }

procedure TEstatisticasTarefas.CarregarDeJSON(const AJSON: TJSONObject);
begin
  if AJSON = nil then
    raise EArgumentException.Create('Payload JSON de estatísticas inválido.');

  if not AJSON.TryGetValue<Integer>('total_tarefas', FTotalTarefas) then
    FTotalTarefas := 0;

  if not AJSON.TryGetValue<Double>('media_prioridade_pendentes', FMediaPrioridadePendentes) then
    FMediaPrioridadePendentes := 0;

  if not AJSON.TryGetValue<Integer>('concluidas_ultimos_7_dias', FConcluidasUltimos7Dias) then
    FConcluidasUltimos7Dias := 0;

  FGeradoEm := JSONParaData(AJSON, 'gerado_em');
end;

function TEstatisticasTarefas.ToJSONObject: TJSONObject;
begin
  Result := TJSONObject.Create;
  try
    Result.AddPair('total_tarefas', TJSONNumber.Create(FTotalTarefas));
    Result.AddPair('media_prioridade_pendentes', TJSONNumber.Create(FMediaPrioridadePendentes));
    Result.AddPair('concluidas_ultimos_7_dias', TJSONNumber.Create(FConcluidasUltimos7Dias));
    Result.AddPair('gerado_em', DataParaJSON(FGeradoEm));
  except
    Result.Free;
    raise;
  end;
end;

end.
