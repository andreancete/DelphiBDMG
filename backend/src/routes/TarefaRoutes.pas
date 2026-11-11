unit TarefaRoutes;

{ Registro dos endpoints de Tarefas e respectiva documentação Swagger.

  | Método | Endpoint                     | Ação                                 |
  |--------|------------------------------|--------------------------------------|
  | GET    | /api/tarefas                 | Lista paginada (filtros opcionais)   |
  | GET    | /api/tarefas/:id             | Consulta uma tarefa                  |
  | POST   | /api/tarefas                 | Cadastra uma tarefa                  |
  | PATCH  | /api/tarefas/:id/status      | Atualiza apenas o status             |
  | DELETE | /api/tarefas/:id             | Remove (exclusão lógica)             |
  | GET    | /api/estatisticas/tarefas    | Indicadores do desafio SQL           |

  As estatísticas ficam fora de /api/tarefas/... para não conflitar com a
  rota /api/tarefas/:id. }

interface

type
  TTarefaRoutes = class
  private
    class procedure RegistrarSwagger;
  public
    class procedure Registrar;
  end;

implementation

uses
  Horse,
  Horse.GBSwagger,
  ApiConstantes,
  Paginacao,
  Tarefa,
  EstatisticasTarefas,
  TarefaController;

{ TTarefaRoutes }

class procedure TTarefaRoutes.RegistrarSwagger;
begin
  Swagger
    .Path('tarefas')
      .Tag('Tarefas')
      .GET('Listar tarefas (paginado)',
        'Retorna uma página das tarefas não excluídas. Resposta: ' +
        '{"itens": [tarefas], "pagina": 1, "tamanho_pagina": 20, "total_itens": 57, "total_paginas": 3}')
        .AddParamQuery(PARAM_PAGINA, 'Número da página (padrão 1)')
          .Schema(SWAG_INTEGER)
        .&End
        .AddParamQuery(PARAM_TAMANHO_PAGINA, 'Itens por página (padrão 20, máximo 100)')
          .Schema(SWAG_INTEGER)
        .&End
        .AddParamQuery(PARAM_FILTRO_STATUS, 'PENDENTE, EM_ANDAMENTO, CONCLUIDA ou CANCELADA')
          .Schema(SWAG_STRING)
        .&End
        .AddParamQuery(PARAM_FILTRO_PRIORIDADE, '1 (Baixa), 2 (Média), 3 (Alta) ou 4 (Urgente)')
          .Schema(SWAG_INTEGER)
        .&End
        .AddParamQuery(PARAM_FILTRO_BUSCA, 'Texto procurado no título ou na descrição')
          .Schema(SWAG_STRING)
        .&End
        .AddResponse(200, 'Página de tarefas com os totais da consulta').&End
        .AddResponse(400, 'Paginação, status, prioridade ou busca inválidos').&End
        .AddResponse(401, 'Chave de API ausente ou inválida').&End
      .&End
      .POST('Cadastrar tarefa', 'Cadastra uma nova tarefa. Campos: titulo (obrigatório), descricao, prioridade (1 a 4), status')
        .AddParamBody('tarefa', 'Dados da nova tarefa').Required(True).Schema(TTarefa).&End
        .AddResponse(201, 'Tarefa criada').Schema(TTarefa).&End
        .AddResponse(400, 'Dados inválidos').&End
        .AddResponse(401, 'Chave de API ausente ou inválida').&End
      .&End
    .&End
    .Path('tarefas/{id}')
      .Tag('Tarefas')
      .GET('Consultar tarefa', 'Retorna uma tarefa pelo id')
        .AddParamPath('id', 'Id da tarefa').Schema(SWAG_INTEGER).Required(True).&End
        .AddResponse(200, 'Tarefa encontrada').Schema(TTarefa).&End
        .AddResponse(404, 'Tarefa não encontrada').&End
      .&End
      .DELETE('Remover tarefa', 'Exclusão lógica da tarefa (soft delete)')
        .AddParamPath('id', 'Id da tarefa').Schema(SWAG_INTEGER).Required(True).&End
        .AddResponse(204, 'Tarefa removida').&End
        .AddResponse(404, 'Tarefa não encontrada').&End
      .&End
    .&End
    .Path('tarefas/{id}/status')
      .Tag('Tarefas')
      .PATCH('Atualizar status', 'Body: {"status": "CONCLUIDA"}. Ao concluir, data_conclusao é preenchida pelo servidor')
        .AddParamPath('id', 'Id da tarefa').Schema(SWAG_INTEGER).Required(True).&End
        .AddParamBody('status', 'Novo status').Required(True).Schema(SWAG_STRING).&End
        .AddResponse(200, 'Status atualizado').Schema(TTarefa).&End
        .AddResponse(400, 'Status inválido').&End
        .AddResponse(404, 'Tarefa não encontrada').&End
        .AddResponse(409, 'Transição de status não permitida').&End
      .&End
    .&End
    .Path('estatisticas/tarefas')
      .Tag('Estatísticas')
      .GET('Estatísticas das tarefas', 'Total de tarefas, média de prioridade das pendentes e concluídas nos últimos 7 dias')
        .AddResponse(200, 'Indicadores calculados no SQL Server').Schema(TEstatisticasTarefas).&End
      .&End
    .&End;
end;

class procedure TTarefaRoutes.Registrar;
begin
  RegistrarSwagger;

  THorse.Get(ROTA_TAREFAS, TTarefaController.Listar);
  THorse.Post(ROTA_TAREFAS, TTarefaController.Criar);
  THorse.Get(ROTA_TAREFAS + '/:id', TTarefaController.ObterPorId);
  THorse.Patch(ROTA_TAREFAS + '/:id/status', TTarefaController.AtualizarStatus);
  THorse.Delete(ROTA_TAREFAS + '/:id', TTarefaController.Excluir);
  THorse.Get(ROTA_ESTATISTICAS, TTarefaController.Estatisticas);
end;

end.
