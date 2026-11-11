unit TarefaController;

{ Traduz HTTP <-> Service para o recurso Tarefa.
  Cada ação descreve apenas o caminho feliz; validação de entrada e
  tratamento de erros ficam em TBaseController (Executar / Ler*). }

interface

uses
  Horse,
  BaseController,
  Tarefa;

type
  TTarefaController = class(TBaseController)
  private
    class function LerTarefaDoCorpo(const AReq: THorseRequest): TTarefa;
  public
    class procedure Listar(Req: THorseRequest; Res: THorseResponse);
    class procedure ObterPorId(Req: THorseRequest; Res: THorseResponse);
    class procedure Criar(Req: THorseRequest; Res: THorseResponse);
    class procedure AtualizarStatus(Req: THorseRequest; Res: THorseResponse);
    class procedure Excluir(Req: THorseRequest; Res: THorseResponse);
    class procedure Estatisticas(Req: THorseRequest; Res: THorseResponse);
  end;

implementation

uses
  System.SysUtils,
  System.JSON,
  Horse.Commons,
  ApiConstantes,
  EstatisticasTarefas,
  RespostaHttp,
  Container;

const
  CAMPO_STATUS = 'status';

{ TTarefaController }

class function TTarefaController.LerTarefaDoCorpo(const AReq: THorseRequest): TTarefa;
var
  LCorpo: TJSONObject;
begin
  LCorpo := LerCorpoJSON(AReq);
  try
    Result := TTarefa.Create;
    try
      Result.CarregarDeJSON(LCorpo);
    except
      Result.Free;
      raise;
    end;
  finally
    LCorpo.Free;
  end;
end;

class procedure TTarefaController.Listar(Req: THorseRequest; Res: THorseResponse);
begin
  Executar(Res,
    procedure
    var
      LPagina: TPaginaTarefas;
    begin
      LPagina := TContainer.ObterTarefaService.Listar(
        LerQueryTexto(Req, PARAM_FILTRO_STATUS),
        LerQueryTexto(Req, PARAM_FILTRO_PRIORIDADE),
        LerQueryTexto(Req, PARAM_FILTRO_BUSCA),
        LerPaginacao(Req));
      try
        TRespostaHttp.EnviarJSONELiberar(Res, LPagina.ToJSONObject);
      finally
        LPagina.Free;
      end;
    end);
end;

class procedure TTarefaController.ObterPorId(Req: THorseRequest; Res: THorseResponse);
begin
  Executar(Res,
    procedure
    var
      LTarefa: TTarefa;
    begin
      LTarefa := TContainer.ObterTarefaService.ObterPorId(LerIdParam(Req));
      try
        TRespostaHttp.EnviarJSONELiberar(Res, LTarefa.ToJSONObject);
      finally
        LTarefa.Free;
      end;
    end);
end;

class procedure TTarefaController.Criar(Req: THorseRequest; Res: THorseResponse);
begin
  Executar(Res,
    procedure
    var
      LEntrada, LCriada: TTarefa;
    begin
      LEntrada := LerTarefaDoCorpo(Req);
      try
        LCriada := TContainer.ObterTarefaService.Criar(LEntrada);
        try
          Res.AddHeader('Location', Format(ROTA_TAREFAS + '/%d', [LCriada.Id]));
          TRespostaHttp.EnviarJSONELiberar(Res, LCriada.ToJSONObject, THTTPStatus.Created);
        finally
          LCriada.Free;
        end;
      finally
        LEntrada.Free;
      end;
    end);
end;

class procedure TTarefaController.AtualizarStatus(Req: THorseRequest; Res: THorseResponse);
begin
  Executar(Res,
    procedure
    var
      LAtualizada: TTarefa;
    begin
      LAtualizada := TContainer.ObterTarefaService.AtualizarStatus(
        LerIdParam(Req), LerCampoTexto(Req, CAMPO_STATUS));
      try
        TRespostaHttp.EnviarJSONELiberar(Res, LAtualizada.ToJSONObject);
      finally
        LAtualizada.Free;
      end;
    end);
end;

class procedure TTarefaController.Excluir(Req: THorseRequest; Res: THorseResponse);
begin
  Executar(Res,
    procedure
    begin
      TContainer.ObterTarefaService.Excluir(LerIdParam(Req));
      TRespostaHttp.EnviarSemConteudo(Res);
    end);
end;

class procedure TTarefaController.Estatisticas(Req: THorseRequest; Res: THorseResponse);
begin
  Executar(Res,
    procedure
    var
      LEstatisticas: TEstatisticasTarefas;
    begin
      LEstatisticas := TContainer.ObterTarefaService.ObterEstatisticas;
      try
        TRespostaHttp.EnviarJSONELiberar(Res, LEstatisticas.ToJSONObject);
      finally
        LEstatisticas.Free;
      end;
    end);
end;

end.
