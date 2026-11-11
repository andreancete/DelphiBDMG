unit TarefaService.Interfaces;

{ Contrato da camada de regras de negócio de Tarefas.
  Controllers dependem desta interface (nunca de TTarefaService), o que
  permite substituir a implementação ou usar mocks nos testes. }

interface

uses
  Paginacao,
  Tarefa,
  EstatisticasTarefas;

type
  ITarefaService = interface
    ['{A4C9D0E7-3B15-4F8A-9E62-7D1B0C5F3E29}']
    // AStatus vazio = todos; caso contrário PENDENTE, EM_ANDAMENTO, CONCLUIDA ou CANCELADA.
    // APrioridade vazia = todas; caso contrário 1 (Baixa) a 4 (Urgente).
    // ABusca vazia = sem busca; senão procura no título e na descrição.
    function Listar(const AStatus, APrioridade, ABusca: string;
      const APaginacao: TParametrosPaginacao): TPaginaTarefas;
    function ObterPorId(const AId: Int64): TTarefa;
    function Criar(const ATarefa: TTarefa): TTarefa;
    function AtualizarStatus(const AId: Int64; const ANovoStatus: string): TTarefa;
    procedure Excluir(const AId: Int64);
    function ObterEstatisticas: TEstatisticasTarefas;
  end;

implementation

end.
