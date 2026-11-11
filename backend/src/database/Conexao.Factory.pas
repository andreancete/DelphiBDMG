unit Conexao.Factory;

{ FACTORY METHOD que escolhe qual fábrica concreta (Abstract Factory) usar.

  A tecnologia vem da constante BANCO_TIPO_CONEXAO (ConfiguracaoBanco.pas):
    ADO      -> TConexaoFactoryADO (padrão; todas as edições do Delphi)
    FIREDAC  -> TConexaoFactoryFireDAC (requer Enterprise + diretiva FIREDAC_MSSQL)

  Para suportar uma nova tecnologia basta criar a unit Conexao.<Nome>.pas
  implementando IConexaoFactory e acrescentar um ramo no "case" abaixo. }

interface

uses
  Conexao.Interfaces;

type
  TConexaoFactory = class
  private
    class var FPadrao: IConexaoFactory;
    class function TipoConfigurado: TTipoConexao;
  public
    // Factory Method: devolve a fábrica concreta para a tecnologia pedida
    class function Criar(const ATipo: TTipoConexao): IConexaoFactory;
    // Fábrica da tecnologia configurada. Deve ser inicializada no bootstrap
    // (Api.dpr) antes de o servidor aceitar requisições.
    class function Padrao: IConexaoFactory;
  end;

implementation

uses
  System.SysUtils,
  ConfiguracaoBanco,
  {$IFDEF FIREDAC_MSSQL}
  Conexao.FireDAC,
  {$ENDIF}
  Conexao.ADO;

{ TConexaoFactory }

class function TConexaoFactory.TipoConfigurado: TTipoConexao;
var
  LTipo: string;
begin
  LTipo := string(BANCO_TIPO_CONEXAO).Trim.ToUpper;

  if LTipo = 'ADO' then
    Exit(tcADO);
  if LTipo = 'FIREDAC' then
    Exit(tcFireDAC);

  raise EConexaoException.CreateFmt('BANCO_TIPO_CONEXAO "%s" não suportado. Valores aceitos: ADO, FIREDAC.', [LTipo]);
end;

class function TConexaoFactory.Criar(const ATipo: TTipoConexao): IConexaoFactory;
begin
  case ATipo of
    tcADO:
      Result := TConexaoFactoryADO.Create;
    tcFireDAC:
      {$IFDEF FIREDAC_MSSQL}
      Result := TConexaoFactoryFireDAC.Create;
      {$ELSE}
      raise EConexaoException.Create(
        'BANCO_TIPO_CONEXAO = FIREDAC exige compilar com a diretiva FIREDAC_MSSQL ' +
        '(driver MSSQL disponível apenas no Delphi Enterprise/Architect). Use ''ADO''.');
      {$ENDIF}
  else
    raise EConexaoException.Create('Tecnologia de conexão não suportada.');
  end;
end;

class function TConexaoFactory.Padrao: IConexaoFactory;
begin
  if FPadrao = nil then
    FPadrao := Criar(TipoConfigurado);
  Result := FPadrao;
end;

end.
