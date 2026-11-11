unit ApiConstantes;

{ Constantes do contrato HTTP compartilhadas entre a API e o cliente VCL,
  evitando strings mágicas duplicadas nos dois lados. }

interface

const
  // Cabeçalho usado para autenticar o cliente na API (ver ApiKeyMiddleware)
  API_KEY_HEADER = 'X-API-Key';

  ROTA_API          = '/api';
  ROTA_TAREFAS      = '/api/tarefas';
  ROTA_ESTATISTICAS = '/api/estatisticas/tarefas';
  ROTA_HEALTH       = '/health';

  // Recursos relativos usados pelo TRESTClient (sem barra inicial)
  RECURSO_TAREFAS        = 'api/tarefas';
  RECURSO_TAREFA_ID      = 'api/tarefas/%d';
  RECURSO_TAREFA_STATUS  = 'api/tarefas/%d/status';
  RECURSO_ESTATISTICAS   = 'api/estatisticas/tarefas';

implementation

end.
