unit TarefaRestClient.Interfaces;

{ Contrato do cliente HTTP do serviço de Tarefas.
  As telas dependem apenas desta interface; a implementação concreta
  (RESTRequest4Delphi) é obtida pela TRestClientFactory. }

interface

uses
  System.SysUtils,
  Paginacao,
  Tarefa,
  EstatisticasTarefas,
  StatusTarefaEnum;

type
  // Erro devolvido pela API (ou falha de comunicação), com o status HTTP
  EApiException = class(Exception)
  private
    FStatusHttp: Integer;
  public
    constructor Create(const AStatusHttp: Integer; const AMensagem: string);
    property StatusHttp: Integer read FStatusHttp;
  end;

  ITarefaRestClient = interface
    ['{5F2A8C31-7D4E-4B9A-8E16-2C0D3F9B7A15}']
    // Uma página da listagem; o chamador é dono da página devolvida
    function Listar(const AFiltro: TFiltroTarefas; const APaginacao: TParametrosPaginacao): TPaginaTarefas;
    function Criar(const ATarefa: TTarefa): TTarefa;
    function AtualizarStatus(const AId: Int64; const AStatus: TEnumStatusTarefa): TTarefa;
    procedure Excluir(const AId: Int64);
    function ObterEstatisticas: TEstatisticasTarefas;
  end;

implementation

{ EApiException }

constructor EApiException.Create(const AStatusHttp: Integer; const AMensagem: string);
begin
  inherited Create(AMensagem);
  FStatusHttp := AStatusHttp;
end;

end.
