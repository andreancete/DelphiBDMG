unit BaseModel;

{ Classes base dos models compartilhados entre a API (backend) e o cliente
  VCL (frontend).

  TModeloJSON  -> contrato de serialização JSON (qualquer objeto trafegado).
  TBaseModel   -> entidade persistida: acrescenta id, auditoria e validação. }

interface

uses
  System.SysUtils,
  System.JSON;

type
  {$M+}
  TModeloJSON = class abstract
  protected
    // Datas em ISO 8601 com fuso local (evita o "Z" de UTC indevido)
    class function DataParaJSON(const AData: TDateTime): TJSONValue;
    class function JSONParaData(const AJSON: TJSONObject; const ACampo: string): TDateTime;
  public
    // Virtual para permitir "T.Create" em métodos genéricos (constraint constructor)
    constructor Create; virtual;

    procedure CarregarDeJSON(const AJSON: TJSONObject); virtual; abstract;
    function ToJSONObject: TJSONObject; virtual; abstract;
  end;

  TBaseModel = class(TModeloJSON)
  private
    FId: Int64;
    FCriadoEm: TDateTime;
    FAtualizadoEm: TDateTime;
  public
    constructor Create; override;

    // Regras de domínio; as subclasses lançam EArgumentException quando inválido
    procedure Validar; virtual; abstract;

    property Id: Int64 read FId write FId;
    property CriadoEm: TDateTime read FCriadoEm write FCriadoEm;
    property AtualizadoEm: TDateTime read FAtualizadoEm write FAtualizadoEm;
  end;

implementation

uses
  System.DateUtils;

{ TModeloJSON }

constructor TModeloJSON.Create;
begin
  inherited Create;
end;

class function TModeloJSON.DataParaJSON(const AData: TDateTime): TJSONValue;
begin
  if AData > 0 then
    Result := TJSONString.Create(DateToISO8601(AData, False))
  else
    Result := TJSONNull.Create;
end;

class function TModeloJSON.JSONParaData(const AJSON: TJSONObject; const ACampo: string): TDateTime;
var
  LValor: TJSONValue;
begin
  Result := 0;
  LValor := AJSON.Values[ACampo];
  if (LValor = nil) or (LValor is TJSONNull) or (LValor.Value.Trim = '') then
    Exit;

  if not TryISO8601ToDate(LValor.Value, Result, False) then
    Result := 0;
end;

{ TBaseModel }

constructor TBaseModel.Create;
begin
  inherited Create;
  FId := 0;
  FCriadoEm := 0;
  FAtualizadoEm := 0;
end;

end.
