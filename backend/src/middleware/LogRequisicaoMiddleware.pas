unit LogRequisicaoMiddleware;

{ Registra cada requisição no log da API:

    2026-11-10 19:20:15.123 [INFO ] GET /api/tarefas -> 200 (12 ms)
    2026-11-10 19:20:16.004 [AVISO] GET /api/tarefas -> 401 (0 ms)
    2026-11-10 19:20:17.410 [ERRO ] PATCH /api/tarefas/9/status -> 503 (5012 ms)

  Nível pelo status: 2xx/3xx = INFO, 4xx = AVISO, 5xx = ERRO.
  Deve ser o PRIMEIRO middleware registrado, para medir o tempo total e
  registrar também as requisições recusadas pela chave de API. }

interface

uses
  System.SysUtils,
  Horse;

type
  TLogRequisicaoMiddleware = class
  public
    class procedure Registrar(Req: THorseRequest; Res: THorseResponse; Next: TProc);
  end;

implementation

uses
  System.Diagnostics,
  Horse.Commons,
  LogApi;

function NivelPeloStatus(const AStatus: Integer): TNivelLog;
begin
  if AStatus >= Integer(THTTPStatus.InternalServerError) then
    Result := nlErro
  else if AStatus >= Integer(THTTPStatus.BadRequest) then
    Result := nlAviso
  else
    Result := nlInfo;
end;

{ TLogRequisicaoMiddleware }

class procedure TLogRequisicaoMiddleware.Registrar(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  LCronometro: TStopwatch;
  LStatus: Integer;
  LExcecaoNaoTratada: string;
begin
  LCronometro := TStopwatch.StartNew;
  LExcecaoNaoTratada := '';
  try
    try
      Next();
    except
      on E: Exception do
      begin
        // EHorseCallbackInterrupted é o fluxo normal do Horse, não um erro
        if not (E is EHorseCallbackInterrupted) then
          LExcecaoNaoTratada := Format(' | exceção não tratada %s: %s', [E.ClassName, E.Message]);
        raise;
      end;
    end;
  finally
    LStatus := Res.Status;
    if LExcecaoNaoTratada <> '' then
      LStatus := Integer(THTTPStatus.InternalServerError);

    TLog.Registrar(NivelPeloStatus(LStatus),
      Format('%s %s -> %d (%d ms)%s',
        [Req.Method, Req.PathInfo, LStatus, LCronometro.ElapsedMilliseconds, LExcecaoNaoTratada]));
  end;
end;

end.
