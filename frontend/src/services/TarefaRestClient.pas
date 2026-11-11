unit TarefaRestClient;

(* Implementação de ITarefaRestClient com a biblioteca RESTRequest4Delphi (RR4D).
  https://github.com/viniciussanchez/RESTRequest4Delphi

  - Envia a chave de API no cabeçalho X-API-Key em todas as requisições.
  - Converte respostas de erro da API ({"mensagem": ...}) em EApiException.
  - Converte o JSON recebido nos models compartilhados (TTarefa, TEstatisticasTarefas).
  - Cada requisição RR4D é criada e liberada por chamada (contagem de
    referência), mas a instância não deve ser compartilhada entre threads:
    a TRestClientFactory entrega sempre uma instância nova. *)

interface

uses
  System.SysUtils,
  System.JSON,
  RESTRequest4D,
  BaseModel,
  Paginacao,
  Tarefa,
  EstatisticasTarefas,
  StatusTarefaEnum,
  PrioridadeTarefaEnum,
  TarefaRestClient.Interfaces;

type
  TTarefaRestClient = class(TInterfacedObject, ITarefaRestClient)
  private
    FBaseUrl: string;
    FApiKey: string;
    FTimeoutMs: Integer;
    function NovaRequisicao(const ARecurso: string): IRequest;
    // Executa a chamada, traduz falha de comunicação e status de erro em EApiException
    function Executar(const AExecucao: TFunc<IResponse>): IResponse;
    function ExtrairMensagemErro(const AResposta: IResponse): string;
    function LerJSON(const AResposta: IResponse): TJSONValue;
    function LerObjeto<T: TModeloJSON, constructor>(const AJson: TJSONObject): T;
    function LerResposta<T: TModeloJSON, constructor>(const AResposta: IResponse): T;
  public
    constructor Create(const ABaseUrl, AApiKey: string; const ATimeoutMs: Integer);

    function Listar(const AFiltro: TFiltroTarefas; const APaginacao: TParametrosPaginacao): TPaginaTarefas;
    function Criar(const ATarefa: TTarefa): TTarefa;
    function AtualizarStatus(const AId: Int64; const AStatus: TEnumStatusTarefa): TTarefa;
    procedure Excluir(const AId: Int64);
    function ObterEstatisticas: TEstatisticasTarefas;
  end;

implementation

uses
  ApiConstantes;

const
  CONTENT_TYPE_JSON = 'application/json';
  CAMPO_MENSAGEM_ERRO = 'mensagem';
  CAMPO_STATUS = 'status';

{ TTarefaRestClient }

constructor TTarefaRestClient.Create(const ABaseUrl, AApiKey: string; const ATimeoutMs: Integer);
begin
  inherited Create;
  FBaseUrl := ABaseUrl;
  FApiKey := AApiKey;
  FTimeoutMs := ATimeoutMs;
end;

function TTarefaRestClient.NovaRequisicao(const ARecurso: string): IRequest;
begin
  Result := TRequest.New
    .BaseURL(FBaseUrl)
    .Resource(ARecurso)
    .Accept(CONTENT_TYPE_JSON)
    .Timeout(FTimeoutMs)
    .AddHeader(API_KEY_HEADER, FApiKey);
end;

function TTarefaRestClient.Executar(const AExecucao: TFunc<IResponse>): IResponse;
begin
  try
    Result := AExecucao();
  except
    on E: Exception do
      raise EApiException.Create(0, Format(
        'Não foi possível comunicar com o serviço em %s.' + sLineBreak +
        'Verifique se a API está em execução.' + sLineBreak + sLineBreak + 'Detalhe: %s',
        [FBaseUrl, E.Message]));
  end;

  if (Result.StatusCode < 200) or (Result.StatusCode >= 300) then
    raise EApiException.Create(Result.StatusCode, ExtrairMensagemErro(Result));
end;

function TTarefaRestClient.ExtrairMensagemErro(const AResposta: IResponse): string;
var
  LJson: TJSONValue;
begin
  Result := '';
  // O corpo de erro pode não ser JSON (ex.: página HTML de um proxy)
  LJson := TJSONObject.ParseJSONValue(AResposta.Content);
  try
    if (LJson is TJSONObject) and TJSONObject(LJson).TryGetValue<string>(CAMPO_MENSAGEM_ERRO, Result) then
      Exit;
  finally
    LJson.Free;
  end;

  case AResposta.StatusCode of
    401: Result := 'Acesso negado pela API. Confira se API e cliente foram compilados com a mesma API_KEY (ConfiguracaoApi.pas).';
    404: Result := 'Recurso não encontrado no serviço.';
    503: Result := 'Banco de dados indisponível no servidor.';
  else
    Result := Format('Erro HTTP %d: %s', [AResposta.StatusCode, AResposta.StatusText]);
  end;
end;

function TTarefaRestClient.LerJSON(const AResposta: IResponse): TJSONValue;
begin
  Result := TJSONObject.ParseJSONValue(AResposta.Content);
  if Result = nil then
    raise EApiException.Create(AResposta.StatusCode, 'Resposta inesperada do serviço (JSON inválido).');
end;

function TTarefaRestClient.LerObjeto<T>(const AJson: TJSONObject): T;
begin
  Result := T.Create;
  try
    Result.CarregarDeJSON(AJson);
  except
    Result.Free;
    raise;
  end;
end;

function TTarefaRestClient.LerResposta<T>(const AResposta: IResponse): T;
var
  LJson: TJSONValue;
begin
  LJson := LerJSON(AResposta);
  try
    if not (LJson is TJSONObject) then
      raise EApiException.Create(AResposta.StatusCode, 'Resposta inesperada do serviço (objeto JSON esperado).');
    Result := LerObjeto<T>(TJSONObject(LJson));
  finally
    LJson.Free;
  end;
end;

function TTarefaRestClient.Listar(const AFiltro: TFiltroTarefas;
  const APaginacao: TParametrosPaginacao): TPaginaTarefas;
var
  LRequisicao: IRequest;
begin
  // GET api/tarefas?pagina=N&tamanho=M[&status=X][&prioridade=P][&busca=Y]
  LRequisicao := NovaRequisicao(RECURSO_TAREFAS)
    .AddParam(PARAM_PAGINA, IntToStr(APaginacao.Pagina))
    .AddParam(PARAM_TAMANHO_PAGINA, IntToStr(APaginacao.TamanhoPagina));
  if AFiltro.FiltrarPorStatus then
    LRequisicao.AddParam(PARAM_FILTRO_STATUS, StatusTarefaToString(AFiltro.Status));
  if AFiltro.FiltrarPorPrioridade then
    LRequisicao.AddParam(PARAM_FILTRO_PRIORIDADE, IntToStr(PrioridadeTarefaToInteger(AFiltro.Prioridade)));
  if AFiltro.Busca.Trim <> '' then
    LRequisicao.AddParam(PARAM_FILTRO_BUSCA, AFiltro.Busca.Trim);

  Result := LerResposta<TPaginaTarefas>(Executar(
    function: IResponse
    begin
      Result := LRequisicao.Get;
    end));
end;

function TTarefaRestClient.Criar(const ATarefa: TTarefa): TTarefa;
var
  LCorpo: TJSONObject;
  LCorpoTexto: string;
begin
  LCorpo := ATarefa.ToJSONCadastro;
  try
    LCorpoTexto := LCorpo.ToJSON;
  finally
    LCorpo.Free;
  end;

  Result := LerResposta<TTarefa>(Executar(
    function: IResponse
    begin
      Result := NovaRequisicao(RECURSO_TAREFAS).AddBody(LCorpoTexto).Post;
    end));
end;

function TTarefaRestClient.AtualizarStatus(const AId: Int64; const AStatus: TEnumStatusTarefa): TTarefa;
var
  LCorpo: TJSONObject;
  LCorpoTexto: string;
begin
  LCorpo := TJSONObject.Create;
  try
    LCorpo.AddPair(CAMPO_STATUS, StatusTarefaToString(AStatus));
    LCorpoTexto := LCorpo.ToJSON;
  finally
    LCorpo.Free;
  end;

  Result := LerResposta<TTarefa>(Executar(
    function: IResponse
    begin
      Result := NovaRequisicao(Format(RECURSO_TAREFA_STATUS, [AId])).AddBody(LCorpoTexto).Patch;
    end));
end;

procedure TTarefaRestClient.Excluir(const AId: Int64);
begin
  Executar(
    function: IResponse
    begin
      Result := NovaRequisicao(Format(RECURSO_TAREFA_ID, [AId])).Delete;
    end);
end;

function TTarefaRestClient.ObterEstatisticas: TEstatisticasTarefas;
begin
  Result := LerResposta<TEstatisticasTarefas>(Executar(
    function: IResponse
    begin
      Result := NovaRequisicao(RECURSO_ESTATISTICAS).Get;
    end));
end;

end.
