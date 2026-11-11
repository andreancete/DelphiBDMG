unit Container;

{ Composition root: único ponto da aplicação que conhece as classes concretas.
  Monta o grafo  IConexaoFactory -> ITarefaRepository -> ITarefaService
  e o entrega às camadas superiores sempre por interface.

  Cada requisição HTTP recebe um Service/Repository novo (e portanto uma
  conexão própria), o que torna o acesso a dados thread-safe. Nos testes o
  Service é montado diretamente com um repositório fake (ver TarefaServiceTests). }

interface

uses
  TarefaRepository.Interfaces,
  TarefaService.Interfaces;

type
  TContainer = class
  public
    class function ObterTarefaRepository: ITarefaRepository;
    class function ObterTarefaService: ITarefaService;
  end;

implementation

uses
  Conexao.Factory,
  TarefaRepository.SQLServer,
  TarefaService;

{ TContainer }

class function TContainer.ObterTarefaRepository: ITarefaRepository;
begin
  Result := TTarefaRepositorySQLServer.Create(TConexaoFactory.Padrao);
end;

class function TContainer.ObterTarefaService: ITarefaService;
begin
  Result := TTarefaService.Create(ObterTarefaRepository);
end;

end.
