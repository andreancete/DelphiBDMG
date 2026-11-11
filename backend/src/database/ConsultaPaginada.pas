unit ConsultaPaginada;

{ Executa qualquer consulta de forma paginada no SQL Server.

  Reutilizável por todos os repositórios: o repositório informa só o SELECT
  base (com seus filtros), a ordenação e como converter cada linha; aqui são
  montados e executados os dois comandos da paginação:

    1) SELECT COUNT(*) FROM (<SELECT base>) AS consulta_paginada
    2) <SELECT base> ORDER BY <ordenação>
         OFFSET :paginacao_deslocamento ROWS FETCH NEXT :paginacao_tamanho ROWS ONLY

  OFFSET/FETCH (SQL Server 2012+) exige ORDER BY; a ordenação deve terminar em
  uma coluna única (ex.: id) para que nenhum registro se repita ou suma entre
  páginas. Parâmetros de filtro não devem se repetir no SQL (o ADO associa
  parâmetros por posição). }

interface

uses
  System.SysUtils,
  Data.DB,
  BaseModel,
  Paginacao,
  Conexao.Interfaces;

const
  // Parâmetros SQL da paginação. Ficam na interface porque métodos genéricos
  // (Executar<T>) não podem usar símbolos da implementation (E2506)
  PARAM_DESLOCAMENTO = 'paginacao_deslocamento';
  PARAM_TAMANHO = 'paginacao_tamanho';

type
  TConsultaPaginada = class
  private
    class function ContarRegistros(const AConexao: IConexao; const ASQLBase: string;
      const ADefinirParametros: TProc<IQuery>): Integer;
  public
    // ASQLBase: SELECT completo com WHERE, SEM ORDER BY
    // AOrdenacao: lista de colunas do ORDER BY (sem a palavra ORDER BY)
    // ADefinirParametros: preenche os parâmetros de filtro (pode ser nil)
    // AConverter: cria o model a partir da linha atual do dataset
    class function Executar<T: TModeloJSON, constructor>(const AConexao: IConexao;
      const ASQLBase, AOrdenacao: string; const APaginacao: TParametrosPaginacao;
      const ADefinirParametros: TProc<IQuery>; const AConverter: TFunc<TDataSet, T>): TPagina<T>;
  end;

implementation

{ TConsultaPaginada }

class function TConsultaPaginada.ContarRegistros(const AConexao: IConexao; const ASQLBase: string;
  const ADefinirParametros: TProc<IQuery>): Integer;
var
  LQuery: IQuery;
begin
  LQuery := AConexao.CriarQuery;
  LQuery.DefinirSQL('SELECT COUNT(*) AS total FROM (' + ASQLBase + ') AS consulta_paginada');
  if Assigned(ADefinirParametros) then
    ADefinirParametros(LQuery);
  LQuery.Abrir;
  Result := LQuery.DataSet.Fields[0].AsInteger;
end;

class function TConsultaPaginada.Executar<T>(const AConexao: IConexao;
  const ASQLBase, AOrdenacao: string; const APaginacao: TParametrosPaginacao;
  const ADefinirParametros: TProc<IQuery>; const AConverter: TFunc<TDataSet, T>): TPagina<T>;
var
  LTotal: Integer;
  LQuery: IQuery;
begin
  Result := TPagina<T>.Create;
  try
    LTotal := ContarRegistros(AConexao, ASQLBase, ADefinirParametros);
    Result.DefinirPaginacao(APaginacao, LTotal);

    // Página além do fim: não há o que buscar
    if APaginacao.Deslocamento >= LTotal then
      Exit;

    LQuery := AConexao.CriarQuery;
    LQuery.DefinirSQL(ASQLBase +
      ' ORDER BY ' + AOrdenacao +
      ' OFFSET :' + PARAM_DESLOCAMENTO + ' ROWS FETCH NEXT :' + PARAM_TAMANHO + ' ROWS ONLY');
    if Assigned(ADefinirParametros) then
      ADefinirParametros(LQuery);
    LQuery.ParamInteiro(PARAM_DESLOCAMENTO, APaginacao.Deslocamento);
    LQuery.ParamInteiro(PARAM_TAMANHO, APaginacao.TamanhoPagina);
    LQuery.Abrir;

    while not LQuery.DataSet.Eof do
    begin
      Result.Itens.Add(AConverter(LQuery.DataSet));
      LQuery.DataSet.Next;
    end;
  except
    Result.Free;
    raise;
  end;
end;

end.
