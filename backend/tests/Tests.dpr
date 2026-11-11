program Tests;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DUnitX.Loggers.Console,
  BaseModel in '..\..\Compartilhada\Models\BaseModel.pas',
  Paginacao in '..\..\Compartilhada\Comum\Paginacao.pas',
  StatusTarefaEnum in '..\..\Compartilhada\Models\Enums\StatusTarefaEnum.pas',
  PrioridadeTarefaEnum in '..\..\Compartilhada\Models\Enums\PrioridadeTarefaEnum.pas',
  Tarefa in '..\..\Compartilhada\Models\Tarefa.pas',
  EstatisticasTarefas in '..\..\Compartilhada\Models\EstatisticasTarefas.pas',
  TarefaRepository.Interfaces in '..\src\repositories\TarefaRepository.Interfaces.pas',
  ServiceExceptions in '..\src\services\ServiceExceptions.pas',
  TarefaService.Interfaces in '..\src\services\TarefaService.Interfaces.pas',
  TarefaService in '..\src\services\TarefaService.pas',
  TarefaServiceTests in 'services\TarefaServiceTests.pas',
  PaginacaoTests in 'comum\PaginacaoTests.pas';

var
  LRunner: ITestRunner;
  LResults: IRunResults;
begin
  try
    TDUnitX.CheckCommandLine;
    LRunner := TDUnitX.CreateRunner;
    LRunner.UseRTTI := True;
    LRunner.AddLogger(TDUnitXConsoleLogger.Create(True));

    LResults := LRunner.Execute;
    if not LResults.AllPassed then
      System.ExitCode := EXIT_ERRORS;

    {$IFNDEF CI}
    System.Writeln('');
    System.Write('Pressione <Enter> para sair...');
    System.Readln;
    {$ENDIF}
  except
    on E: Exception do
      System.Writeln(E.ClassName, ': ', E.Message);
  end;
end.
