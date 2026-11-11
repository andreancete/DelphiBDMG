unit Routes;

{ Ponto único de registro de rotas e middlewares da API. }

interface

type
  TRoutes = class
  private
    class procedure ConfigurarSwagger;
    class procedure RegistrarHealthCheck;
  public
    class procedure Registrar;
  end;

implementation

uses
  System.SysUtils,
  Horse,
  Horse.GBSwagger,
  GBSwagger.Model.Types,
  ApiConstantes,
  ApiKeyMiddleware,
  TarefaRoutes;

{ TRoutes }

class procedure TRoutes.ConfigurarSwagger;
begin
  Swagger
    .Info
      .Title('BDMG - API de Tarefas')
      .Version('1.0.0')
      .Description('Serviço de gerenciamento de tarefas (Delphi + Horse + SQL Server). ' +
                   'Todas as rotas /api exigem o cabeçalho ' + API_KEY_HEADER + '.')
    .&End
    // Declara a chave de API: habilita o botão "Authorize" no Swagger UI e
    // aplica o cadeado (X-API-Key) a todas as rotas documentadas
    .AddSecurity('ApiKey')
      .&Type(gbApiKey)
      .Name(API_KEY_HEADER)
      .&In(gbHeader)
    .&End
    .BasePath('api');
end;

class procedure TRoutes.RegistrarHealthCheck;
begin
  // Público (sem chave): usado pelo cliente VCL para indicar se a API está no ar
  THorse.Get(ROTA_HEALTH,
    procedure(Req: THorseRequest; Res: THorseResponse)
    begin
      Res.ContentType('application/json; charset=utf-8').Send('{"status":"ok"}');
    end);
end;

class procedure TRoutes.Registrar;
begin
  ConfigurarSwagger;
  RegistrarHealthCheck;

  // Middleware de autenticação aplicado a tudo que estiver sob /api
  THorse.Use(ROTA_API, TApiKeyMiddleware.Validar);

  TTarefaRoutes.Registrar;
end;

end.
