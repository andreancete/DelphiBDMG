unit ExecutorAssincrono;

{ Executa chamadas ao serviço em segundo plano (TTask), sem travar a tela.

  - Cada execução cria o próprio ITarefaRestClient (TRESTClient não é
    thread-safe).
  - Os retornos (sucesso, falha e mudança de estado) voltam para a thread
    principal via TThread.Queue, podendo atualizar componentes VCL.
  - Uma operação por vez: enquanto Ocupado, novas chamadas são ignoradas. }

interface

uses
  System.SysUtils,
  System.Classes,
  TarefaRestClient.Interfaces;

type
  // AOcupado indica início/fim; AMensagem descreve a operação em andamento
  TEstadoExecucaoEvent = reference to procedure(const AOcupado: Boolean; const AMensagem: string);

  TExecutorAssincrono = class
  private
    FOcupado: Boolean;
    FAoMudarEstado: TEstadoExecucaoEvent;
    procedure DefinirOcupado(const AOcupado: Boolean; const AMensagem: string);
  public
    constructor Create(const AAoMudarEstado: TEstadoExecucaoEvent);

    // Retorna False (sem executar) se já houver uma operação em andamento
    function Executar(const AMensagem: string;
      const AOperacao: TProc<ITarefaRestClient>;
      const ASucesso: TProc;
      const AFalha: TProc<string>): Boolean;

    property Ocupado: Boolean read FOcupado;
  end;

implementation

uses
  System.Threading,
  RestClientFactory;

{ TExecutorAssincrono }

constructor TExecutorAssincrono.Create(const AAoMudarEstado: TEstadoExecucaoEvent);
begin
  inherited Create;
  FAoMudarEstado := AAoMudarEstado;
end;

procedure TExecutorAssincrono.DefinirOcupado(const AOcupado: Boolean; const AMensagem: string);
begin
  FOcupado := AOcupado;
  if Assigned(FAoMudarEstado) then
    FAoMudarEstado(AOcupado, AMensagem);
end;

function TExecutorAssincrono.Executar(const AMensagem: string;
  const AOperacao: TProc<ITarefaRestClient>; const ASucesso: TProc;
  const AFalha: TProc<string>): Boolean;
begin
  Result := not FOcupado;
  if not Result then
    Exit;

  DefinirOcupado(True, AMensagem);
  TTask.Run(
    procedure
    var
      LMensagemErro: string;
    begin
      LMensagemErro := '';
      try
        AOperacao(TRestClientFactory.CriarTarefaClient);
      except
        on E: Exception do
          LMensagemErro := E.Message;
      end;

      TThread.Queue(nil,
        procedure
        begin
          DefinirOcupado(False, '');
          if LMensagemErro <> '' then
          begin
            if Assigned(AFalha) then
              AFalha(LMensagemErro);
          end
          else if Assigned(ASucesso) then
            ASucesso();
        end);
    end);
end;

end.
