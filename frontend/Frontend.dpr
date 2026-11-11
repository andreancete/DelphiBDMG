program Frontend;

uses
  Vcl.Forms,
  ApiConstantes in '..\Compartilhada\Comum\ApiConstantes.pas',
  ConfiguracaoApi in '..\Compartilhada\Comum\ConfiguracaoApi.pas',
  BaseModel in '..\Compartilhada\Models\BaseModel.pas',
  Paginacao in '..\Compartilhada\Comum\Paginacao.pas',
  StatusTarefaEnum in '..\Compartilhada\Models\Enums\StatusTarefaEnum.pas',
  PrioridadeTarefaEnum in '..\Compartilhada\Models\Enums\PrioridadeTarefaEnum.pas',
  Tarefa in '..\Compartilhada\Models\Tarefa.pas',
  EstatisticasTarefas in '..\Compartilhada\Models\EstatisticasTarefas.pas',
  TarefaRestClient.Interfaces in 'src\services\TarefaRestClient.Interfaces.pas',
  TarefaRestClient in 'src\services\TarefaRestClient.pas',
  RestClientFactory in 'src\services\RestClientFactory.pas',
  ExecutorAssincrono in 'src\services\ExecutorAssincrono.pas',
  ComboEnumHelper in 'src\views\ComboEnumHelper.pas',
  TarefaListViewAdapter in 'src\views\TarefaListViewAdapter.pas',
  ControlePaginacao in 'src\views\ControlePaginacao.pas',
  View.TarefaCadastro in 'src\views\View.TarefaCadastro.pas' {FormTarefaCadastro},
  View.Principal in 'src\views\View.Principal.pas' {FormPrincipal};

{$R *.res}

begin
  {$IFDEF DEBUG}
  // Relata vazamentos de memoria ao encerrar (apenas na configuracao Debug)
  ReportMemoryLeaksOnShutdown := True;
  {$ENDIF}
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'BDMG - Gerenciador de Tarefas';
  Application.CreateForm(TFormPrincipal, FormPrincipal);
  Application.Run;
end.
