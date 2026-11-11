unit BaseController;

{ Infraestrutura comum dos Controllers.

  Executar centraliza o tratamento de exceções: cada ação do Controller é
  escrita só com o "caminho feliz" e qualquer exceção é traduzida aqui para o
  código HTTP correto (helper próprio, sem dependência externa). }

interface

uses
  System.SysUtils,
  System.JSON,
  Horse,
  Horse.Commons,
  Paginacao;

type
  TBaseController = class
  private
    class procedure TratarExcecao(const ARes: THorseResponse; const E: Exception);
  protected
    // Executa a ação e converte exceções em resposta HTTP:
    //   EValidacaoException, EConvertError, EArgumentException -> 400
    //   ENaoEncontradoException -> 404 | ERegraNegocioException -> 409
    //   EConexaoException, EBancoDadosException -> 503 | demais -> 500
    class procedure Executar(const ARes: THorseResponse; const AAcao: TProc);

    // Leitura de entrada: lançam EValidacaoException (HTTP 400) quando inválida
    class function LerIdParam(const AReq: THorseRequest): Int64;
    class function LerCorpoJSON(const AReq: THorseRequest): TJSONObject;
    class function LerCampoTexto(const AReq: THorseRequest; const ACampo: string): string;
    // Parâmetro opcional da URL (?nome=valor); devolve '' quando ausente
    class function LerQueryTexto(const AReq: THorseRequest; const ANome: string): string;
    // Paginação de qualquer listagem: ?pagina=N&tamanho=M (padrões em Paginacao.pas)
    class function LerPaginacao(const AReq: THorseRequest): TParametrosPaginacao;
  end;

implementation

uses
  Conexao.Interfaces,
  ServiceExceptions,
  RespostaHttp,
  LogApi;

{ TBaseController }

class procedure TBaseController.Executar(const ARes: THorseResponse; const AAcao: TProc);
begin
  try
    AAcao();
  except
    on E: Exception do
      TratarExcecao(ARes, E);
  end;
end;

class procedure TBaseController.TratarExcecao(const ARes: THorseResponse; const E: Exception);
begin
  if (E is EValidacaoException) or (E is EConvertError) or (E is EArgumentException) then
    TRespostaHttp.EnviarErro(ARes, THTTPStatus.BadRequest, E.Message)
  else if E is ENaoEncontradoException then
    TRespostaHttp.EnviarErro(ARes, THTTPStatus.NotFound, E.Message)
  else if E is ERegraNegocioException then
    TRespostaHttp.EnviarErro(ARes, THTTPStatus.Conflict, E.Message)
  else if (E is EConexaoException) or (E is EBancoDadosException) then
  begin
    // Detalhes do banco ficam só no log do servidor (não vazam para o cliente)
    TLog.Erro(Format('Banco de dados - %s: %s', [E.ClassName, E.Message]));
    TRespostaHttp.EnviarErro(ARes, THTTPStatus.ServiceUnavailable,
      'Serviço de banco de dados indisponível no momento. Tente novamente em instantes.');
  end
  else
  begin
    TLog.Erro(Format('Erro interno - %s: %s', [E.ClassName, E.Message]));
    TRespostaHttp.EnviarErro(ARes, THTTPStatus.InternalServerError, 'Erro interno ao processar a requisição.');
  end;
end;

class function TBaseController.LerIdParam(const AReq: THorseRequest): Int64;
var
  LIdTexto: string;
begin
  Result := 0;
  if AReq.Params.TryGetValue('id', LIdTexto) then
    Result := StrToInt64Def(LIdTexto, 0);

  if Result <= 0 then
    raise EValidacaoException.Create('O parâmetro "id" deve ser um número inteiro maior que zero.');
end;

class function TBaseController.LerCorpoJSON(const AReq: THorseRequest): TJSONObject;
var
  LValor: TJSONValue;
begin
  if AReq.Body.Trim = '' then
    raise EValidacaoException.Create('O corpo da requisição (body) está vazio.');

  LValor := TJSONObject.ParseJSONValue(AReq.Body);
  if not (LValor is TJSONObject) then
  begin
    LValor.Free;
    raise EValidacaoException.Create('O corpo da requisição deve ser um objeto JSON válido.');
  end;

  Result := TJSONObject(LValor);
end;

class function TBaseController.LerQueryTexto(const AReq: THorseRequest; const ANome: string): string;
begin
  if not AReq.Query.TryGetValue(ANome, Result) then
    Result := '';
end;

class function TBaseController.LerPaginacao(const AReq: THorseRequest): TParametrosPaginacao;

  function LerInteiro(const ANome: string; const APadrao: Integer): Integer;
  var
    LTexto: string;
  begin
    LTexto := LerQueryTexto(AReq, ANome).Trim;
    if LTexto = '' then
      Exit(APadrao);
    if not TryStrToInt(LTexto, Result) then
      raise EValidacaoException.CreateFmt('O parâmetro "%s" deve ser um número inteiro.', [ANome]);
  end;

begin
  // Limites (página >= 1, tamanho até o máximo) validados em TParametrosPaginacao.Criar
  Result := TParametrosPaginacao.Criar(
    LerInteiro(PARAM_PAGINA, PAGINA_PADRAO),
    LerInteiro(PARAM_TAMANHO_PAGINA, TAMANHO_PAGINA_PADRAO));
end;

class function TBaseController.LerCampoTexto(const AReq: THorseRequest; const ACampo: string): string;
var
  LCorpo: TJSONObject;
begin
  LCorpo := LerCorpoJSON(AReq);
  try
    if not LCorpo.TryGetValue<string>(ACampo, Result) then
      Result := '';
  finally
    LCorpo.Free;
  end;
end;

end.
