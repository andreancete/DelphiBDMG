unit RestClientFactory;

{ Factory Method do lado cliente: centraliza a criação do cliente HTTP.
  As telas pedem um ITarefaRestClient sem saber qual biblioteca está por trás
  (RESTRequest4Delphi) nem de onde vêm URL, chave e timeout (constantes de
  ConfiguracaoApi). Trocar a implementação não exige alterar nenhuma tela. }

interface

uses
  TarefaRestClient.Interfaces;

type
  TRestClientFactory = class
  public
    // Sempre devolve uma instância nova: seguro para uso em threads de fundo
    class function CriarTarefaClient: ITarefaRestClient;
  end;

implementation

uses
  ConfiguracaoApi,
  TarefaRestClient;

{ TRestClientFactory }

class function TRestClientFactory.CriarTarefaClient: ITarefaRestClient;
begin
  Result := TTarefaRestClient.Create(API_URL_BASE, API_KEY, API_TIMEOUT_MS);
end;

end.
