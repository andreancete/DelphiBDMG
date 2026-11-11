unit PaginacaoTests;

{ Testes da paginação genérica (Compartilhada\Comum\Paginacao.pas).
  Como a unit é usada por qualquer recurso, as regras são testadas isoladas. }

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.JSON,
  Paginacao,
  Tarefa;

type
  [TestFixture]
  TPaginacaoTests = class
  public
    [Test]
    procedure Criar_DeveUsarValoresPadrao;
    [Test]
    procedure Criar_DeveFalhar_QuandoPaginaMenorQueUm;
    [Test]
    [TestCase('Zero', '0')]
    [TestCase('AcimaDoMaximo', '101')]
    procedure Criar_DeveFalhar_QuandoTamanhoForaDoLimite(const ATamanho: Integer);
    [Test]
    procedure Deslocamento_DeveSerCalculadoPelaPagina;
    [Test]
    [TestCase('Exato', '40,20,2')]
    [TestCase('ComSobra', '57,20,3')]
    [TestCase('Vazio', '0,20,0')]
    procedure TotalPaginas_DeveArredondarParaCima(const ATotal, ATamanho, AEsperado: Integer);
    [Test]
    procedure JSON_DeveManterItensETotais;
  end;

implementation

{ TPaginacaoTests }

procedure TPaginacaoTests.Criar_DeveUsarValoresPadrao;
var
  LParametros: TParametrosPaginacao;
begin
  LParametros := TParametrosPaginacao.Criar;
  Assert.AreEqual(PAGINA_PADRAO, LParametros.Pagina);
  Assert.AreEqual(TAMANHO_PAGINA_PADRAO, LParametros.TamanhoPagina);
end;

procedure TPaginacaoTests.Criar_DeveFalhar_QuandoPaginaMenorQueUm;
begin
  Assert.WillRaise(
    procedure
    begin
      TParametrosPaginacao.Criar(0, 20);
    end, EArgumentException);
end;

procedure TPaginacaoTests.Criar_DeveFalhar_QuandoTamanhoForaDoLimite(const ATamanho: Integer);
begin
  Assert.WillRaise(
    procedure
    begin
      TParametrosPaginacao.Criar(1, ATamanho);
    end, EArgumentException);
end;

procedure TPaginacaoTests.Deslocamento_DeveSerCalculadoPelaPagina;
begin
  Assert.AreEqual(0, TParametrosPaginacao.Criar(1, 20).Deslocamento);
  Assert.AreEqual(40, TParametrosPaginacao.Criar(3, 20).Deslocamento);
end;

procedure TPaginacaoTests.TotalPaginas_DeveArredondarParaCima(const ATotal, ATamanho, AEsperado: Integer);
var
  LPagina: TPaginaTarefas;
begin
  LPagina := TPaginaTarefas.Create;
  try
    LPagina.DefinirPaginacao(TParametrosPaginacao.Criar(1, ATamanho), ATotal);
    Assert.AreEqual(AEsperado, LPagina.TotalPaginas);
  finally
    LPagina.Free;
  end;
end;

procedure TPaginacaoTests.JSON_DeveManterItensETotais;
var
  LOriginal, LLida: TPaginaTarefas;
  LTarefa: TTarefa;
  LJson: TJSONObject;
begin
  LOriginal := TPaginaTarefas.Create;
  LLida := TPaginaTarefas.Create;
  try
    LTarefa := TTarefa.Create;
    LTarefa.Id := 7;
    LTarefa.Titulo := 'Tarefa paginada';
    LOriginal.Itens.Add(LTarefa);
    LOriginal.DefinirPaginacao(TParametrosPaginacao.Criar(2, 10), 25);

    LJson := LOriginal.ToJSONObject;
    try
      Assert.AreEqual(3, LJson.GetValue<Integer>('total_paginas'));
      LLida.CarregarDeJSON(LJson);
    finally
      LJson.Free;
    end;

    Assert.AreEqual(2, LLida.Pagina);
    Assert.AreEqual(10, LLida.TamanhoPagina);
    Assert.AreEqual(25, LLida.TotalItens);
    Assert.AreEqual(1, LLida.Itens.Count);
    Assert.AreEqual('Tarefa paginada', LLida.Itens[0].Titulo);
  finally
    LLida.Free;
    LOriginal.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TPaginacaoTests);

end.
