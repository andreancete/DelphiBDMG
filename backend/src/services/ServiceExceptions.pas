unit ServiceExceptions;

{ Exceções de domínio lançadas pela camada de Service.
  O Controller as traduz em códigos HTTP (ver TBaseController.TratarExcecao),
  de forma que o Service não precise conhecer nada de HTTP. }

interface

uses
  System.SysUtils;

type
  // Dados de entrada inválidos -> HTTP 400
  EValidacaoException = class(Exception);
  // Registro inexistente -> HTTP 404
  ENaoEncontradoException = class(Exception);
  // Operação válida, mas proibida pela regra de negócio -> HTTP 409
  ERegraNegocioException = class(Exception);

implementation

end.
