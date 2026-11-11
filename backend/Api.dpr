program Api;

{ Bootstrap do serviço de Tarefas (Horse).
  Aqui só se configura e inicia o servidor: rotas ficam em src/routes,
  regras em src/services e acesso a dados em src/repositories. }

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Horse,
  Horse.GBSwagger,
  ApiConstantes in '..\Compartilhada\Comum\ApiConstantes.pas',
  ConfiguracaoApi in '..\Compartilhada\Comum\ConfiguracaoApi.pas',
  BaseModel in '..\Compartilhada\Models\BaseModel.pas',
  Paginacao in '..\Compartilhada\Comum\Paginacao.pas',
  StatusTarefaEnum in '..\Compartilhada\Models\Enums\StatusTarefaEnum.pas',
  PrioridadeTarefaEnum in '..\Compartilhada\Models\Enums\PrioridadeTarefaEnum.pas',
  Tarefa in '..\Compartilhada\Models\Tarefa.pas',
  EstatisticasTarefas in '..\Compartilhada\Models\EstatisticasTarefas.pas',
  ConfiguracaoBanco in 'src\config\ConfiguracaoBanco.pas',
  Conexao.Interfaces in 'src\database\Conexao.Interfaces.pas',
  Conexao.Base in 'src\database\Conexao.Base.pas',
  Conexao.ADO in 'src\database\Conexao.ADO.pas',
  Conexao.Factory in 'src\database\Conexao.Factory.pas',
  ConsultaPaginada in 'src\database\ConsultaPaginada.pas',
  TarefaRepository.Interfaces in 'src\repositories\TarefaRepository.Interfaces.pas',
  TarefaRepository.SQLServer in 'src\repositories\TarefaRepository.SQLServer.pas',
  ServiceExceptions in 'src\services\ServiceExceptions.pas',
  TarefaService.Interfaces in 'src\services\TarefaService.Interfaces.pas',
  TarefaService in 'src\services\TarefaService.pas',
  Container in 'src\config\Container.pas',
  RespostaHttp in 'src\http\RespostaHttp.pas',
  BaseController in 'src\controllers\BaseController.pas',
  TarefaController in 'src\controllers\TarefaController.pas',
  LogApi in 'src\log\LogApi.pas',
  LogRequisicaoMiddleware in 'src\middleware\LogRequisicaoMiddleware.pas',
  ApiKeyMiddleware in 'src\middleware\ApiKeyMiddleware.pas',
  TarefaRoutes in 'src\routes\TarefaRoutes.pas',
  Routes in 'src\routes\Routes.pas';

procedure ValidarConexaoBanco;
begin
  // Falha rápido (fail fast): melhor não subir do que subir sem banco.
  // A conexão de teste é liberada ao sair do procedimento (contagem de referência).
  TConexaoFactory.Padrao.CriarConexao;
  TLog.Info('Banco de dados OK: ' + TConexaoFactory.Padrao.Descricao);
end;

procedure ConfigurarHTTPS;
begin
  if not API_HTTPS_ATIVO then
  begin
    TLog.Aviso('HTTPS desativado. Use apenas em ambiente local; em rede, ative API_HTTPS_ATIVO.');
    Exit;
  end;

  // Requer as DLLs do OpenSSL (libeay32.dll / ssleay32.dll) ao lado do executável
  THorse.IOHandleSSL
    .KeyFile(API_HTTPS_ARQUIVO_CHAVE)
    .CertFile(API_HTTPS_ARQUIVO_CERTIFICADO)
    .Active(True);
  TLog.Info('HTTPS ativo.');
end;

begin
  {$IFDEF DEBUG}
  // Relata vazamentos de memoria ao encerrar (apenas na configuracao Debug)
  ReportMemoryLeaksOnShutdown := True;
  {$ENDIF}
  try
    TApiKeyMiddleware.Configurar(API_KEY);
    ValidarConexaoBanco;

    // Primeiro middleware: mede e registra TODAS as requisições (inclusive 401)
    THorse.Use(TLogRequisicaoMiddleware.Registrar);

    // Swagger UI em /swagger e especificação OpenAPI em /swagger/json
    THorse.Use(HorseSwagger('/swagger', '/swagger/json'));
    TRoutes.Registrar;

    THorse.MaxConnections := API_MAX_CONEXOES;
    THorse.ListenQueue := API_FILA_ESCUTA;
    THorse.KeepConnectionAlive := API_KEEP_ALIVE;
    ConfigurarHTTPS;

    THorse.Listen(API_PORTA,
      procedure
      begin
        TLog.Info(Format('API de Tarefas ouvindo na porta %d. Swagger: /swagger', [THorse.Port]));
        Writeln('Pressione Ctrl+C para encerrar.');
      end);
  except
    on E: Exception do
    begin
      TLog.Erro(Format('Falha ao iniciar a API - %s: %s', [E.ClassName, E.Message]));
      ExitCode := 1;
    end;
  end;
end.
