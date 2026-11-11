unit TarefaRepository.Interfaces;

{ Contrato da camada de acesso a dados de Tarefas.
  O Service depende apenas desta interface; a implementação concreta
  (TTarefaRepositorySQLServer) é entregue pelo Container, e nos testes
  unitários é substituída por um repositório em memória. }

interface

uses
  Paginacao,
  Tarefa,
  EstatisticasTarefas,
  StatusTarefaEnum;

type
  ITarefaRepository = interface
    ['{0E3F7A52-91C4-4B2D-8F6A-5C1D2E3B4A60}']
    // Lista paginada; o chamador é dono da página devolvida
    function Listar(const AFiltro: TFiltroTarefas; const APaginacao: TParametrosPaginacao): TPaginaTarefas;
    // Retorna nil quando o registro não existe (ou foi excluído)
    function ObterPorId(const AId: Int64): TTarefa;
    function Inserir(const ATarefa: TTarefa): Int64;
    // Retornam False quando nenhum registro foi afetado (id inexistente)
    function AtualizarStatus(const AId: Int64; const AStatus: TEnumStatusTarefa): Boolean;
    function Excluir(const AId: Int64): Boolean;
    function ObterEstatisticas: TEstatisticasTarefas;
  end;

implementation

end.
