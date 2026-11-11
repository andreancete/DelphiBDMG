unit Paginacao;

(* Paginação reutilizável por qualquer recurso da API (ponto central).

  Compartilhada entre a API e o cliente VCL, garantindo as mesmas regras e o
  mesmo contrato JSON nos dois lados:

    {"itens": [...], "pagina": 2, "tamanho_pagina": 20,
     "total_itens": 57, "total_paginas": 3}

  - TParametrosPaginacao: página/tamanho pedidos, com valores padrão,
    limites e o deslocamento (OFFSET) usado no SQL.
  - TPagina<T>: resultado paginado de qualquer model (T descende de
    TModeloJSON), com a serialização JSON pronta.

  Para paginar um recurso novo, use TPagina<TSeuModel> e
  TConsultaPaginada.Executar<TSeuModel> no repositório (backend). *)

interface

uses
  System.SysUtils,
  System.JSON,
  System.Generics.Collections,
  BaseModel;

const
  PAGINA_PADRAO = 1;
  TAMANHO_PAGINA_PADRAO = 20;
  TAMANHO_PAGINA_MAXIMO = 100;

  // Nomes dos parâmetros de URL (?pagina=2&tamanho=20)
  PARAM_PAGINA = 'pagina';
  PARAM_TAMANHO_PAGINA = 'tamanho';

  // Campos do JSON da página. Ficam na interface porque métodos de tipos
  // genéricos (TPagina<T>) não podem usar símbolos da implementation (E2506)
  CAMPO_ITENS = 'itens';
  CAMPO_PAGINA = 'pagina';
  CAMPO_TAMANHO_PAGINA = 'tamanho_pagina';
  CAMPO_TOTAL_ITENS = 'total_itens';
  CAMPO_TOTAL_PAGINAS = 'total_paginas';

type
  TParametrosPaginacao = record
  private
    FPagina: Integer;
    FTamanhoPagina: Integer;
  public
    // Lança EArgumentException (HTTP 400 na API) se estiver fora dos limites
    class function Criar(const APagina: Integer = PAGINA_PADRAO;
      const ATamanhoPagina: Integer = TAMANHO_PAGINA_PADRAO): TParametrosPaginacao; static;
    // Quantos registros pular no SQL: (página - 1) * tamanho
    function Deslocamento: Integer;

    property Pagina: Integer read FPagina;
    property TamanhoPagina: Integer read FTamanhoPagina;
  end;

  TPagina<T: TModeloJSON, constructor> = class(TModeloJSON)
  private
    FItens: TObjectList<T>;
    FPagina: Integer;
    FTamanhoPagina: Integer;
    FTotalItens: Integer;
    function GetTotalPaginas: Integer;
  public
    constructor Create; override;
    destructor Destroy; override;

    procedure DefinirPaginacao(const AParametros: TParametrosPaginacao; const ATotalItens: Integer);
    procedure CarregarDeJSON(const AJSON: TJSONObject); override;
    function ToJSONObject: TJSONObject; override;

    function TemPaginaAnterior: Boolean;
    function TemProximaPagina: Boolean;

    property Itens: TObjectList<T> read FItens;
    property Pagina: Integer read FPagina;
    property TamanhoPagina: Integer read FTamanhoPagina;
    property TotalItens: Integer read FTotalItens;
    property TotalPaginas: Integer read GetTotalPaginas;
  end;

implementation

{ TParametrosPaginacao }

class function TParametrosPaginacao.Criar(const APagina, ATamanhoPagina: Integer): TParametrosPaginacao;
begin
  if APagina < 1 then
    raise EArgumentException.CreateFmt('O parâmetro "%s" deve ser maior ou igual a 1.', [PARAM_PAGINA]);

  if (ATamanhoPagina < 1) or (ATamanhoPagina > TAMANHO_PAGINA_MAXIMO) then
    raise EArgumentException.CreateFmt('O parâmetro "%s" deve estar entre 1 e %d.',
      [PARAM_TAMANHO_PAGINA, TAMANHO_PAGINA_MAXIMO]);

  Result.FPagina := APagina;
  Result.FTamanhoPagina := ATamanhoPagina;
end;

function TParametrosPaginacao.Deslocamento: Integer;
begin
  Result := (FPagina - 1) * FTamanhoPagina;
end;

{ TPagina<T> }

constructor TPagina<T>.Create;
begin
  inherited Create;
  FItens := TObjectList<T>.Create(True);
  FPagina := PAGINA_PADRAO;
  FTamanhoPagina := TAMANHO_PAGINA_PADRAO;
end;

destructor TPagina<T>.Destroy;
begin
  FItens.Free;
  inherited Destroy;
end;

procedure TPagina<T>.DefinirPaginacao(const AParametros: TParametrosPaginacao; const ATotalItens: Integer);
begin
  FPagina := AParametros.Pagina;
  FTamanhoPagina := AParametros.TamanhoPagina;
  FTotalItens := ATotalItens;
end;

function TPagina<T>.GetTotalPaginas: Integer;
begin
  // Arredonda para cima: 57 itens / 20 por página = 3 páginas
  if FTamanhoPagina <= 0 then
    Exit(0);
  Result := (FTotalItens + FTamanhoPagina - 1) div FTamanhoPagina;
end;

function TPagina<T>.TemPaginaAnterior: Boolean;
begin
  Result := FPagina > 1;
end;

function TPagina<T>.TemProximaPagina: Boolean;
begin
  Result := FPagina < TotalPaginas;
end;

procedure TPagina<T>.CarregarDeJSON(const AJSON: TJSONObject);
var
  LItens: TJSONArray;
  LValor: TJSONValue;
  LItem: T;
begin
  if AJSON = nil then
    raise EArgumentException.Create('Payload JSON de página inválido.');

  FItens.Clear;
  if AJSON.TryGetValue<TJSONArray>(CAMPO_ITENS, LItens) then
    for LValor in LItens do
      if LValor is TJSONObject then
      begin
        LItem := T.Create;
        FItens.Add(LItem);
        LItem.CarregarDeJSON(TJSONObject(LValor));
      end;

  if not AJSON.TryGetValue<Integer>(CAMPO_PAGINA, FPagina) then
    FPagina := PAGINA_PADRAO;
  if not AJSON.TryGetValue<Integer>(CAMPO_TAMANHO_PAGINA, FTamanhoPagina) then
    FTamanhoPagina := TAMANHO_PAGINA_PADRAO;
  if not AJSON.TryGetValue<Integer>(CAMPO_TOTAL_ITENS, FTotalItens) then
    FTotalItens := FItens.Count;
end;

function TPagina<T>.ToJSONObject: TJSONObject;
var
  LItens: TJSONArray;
  LItem: T;
begin
  Result := TJSONObject.Create;
  try
    LItens := TJSONArray.Create;
    Result.AddPair(CAMPO_ITENS, LItens);
    for LItem in FItens do
      LItens.AddElement(LItem.ToJSONObject);

    Result.AddPair(CAMPO_PAGINA, TJSONNumber.Create(FPagina));
    Result.AddPair(CAMPO_TAMANHO_PAGINA, TJSONNumber.Create(FTamanhoPagina));
    Result.AddPair(CAMPO_TOTAL_ITENS, TJSONNumber.Create(FTotalItens));
    Result.AddPair(CAMPO_TOTAL_PAGINAS, TJSONNumber.Create(TotalPaginas));
  except
    Result.Free;
    raise;
  end;
end;

end.
