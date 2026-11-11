unit RespostaHttp;

(* Ponto único de escrita de respostas HTTP JSON da API.
  Usado pelos Controllers e pelos Middlewares, garantindo que sucesso e erro
  sigam sempre o mesmo formato:

    erro -> {"erro": true, "status": 404, "mensagem": "..."} *)

interface

uses
  System.JSON,
  Horse,
  Horse.Commons;

type
  TRespostaHttp = class
  public
    class procedure EnviarErro(const ARes: THorseResponse; const AStatus: THTTPStatus; const AMensagem: string);

    // ATENÇÃO: assume a posse de AJson e o libera após enviar. Permite escrever
    // EnviarJSONELiberar(Res, Objeto.ToJSONObject) sem variável temporária.
    class procedure EnviarJSONELiberar(const ARes: THorseResponse; const AJson: TJSONValue;
      const AStatus: THTTPStatus = THTTPStatus.OK);

    class procedure EnviarSemConteudo(const ARes: THorseResponse);
  end;

implementation

const
  CONTENT_TYPE_JSON = 'application/json; charset=utf-8';

{ TRespostaHttp }

class procedure TRespostaHttp.EnviarErro(const ARes: THorseResponse; const AStatus: THTTPStatus;
  const AMensagem: string);
var
  LErro: TJSONObject;
begin
  LErro := TJSONObject.Create;
  LErro.AddPair('erro', TJSONBool.Create(True));
  LErro.AddPair('status', TJSONNumber.Create(Integer(AStatus)));
  LErro.AddPair('mensagem', AMensagem);
  EnviarJSONELiberar(ARes, LErro, AStatus);
end;

class procedure TRespostaHttp.EnviarJSONELiberar(const ARes: THorseResponse; const AJson: TJSONValue;
  const AStatus: THTTPStatus);
begin
  try
    ARes.Status(AStatus)
        .ContentType(CONTENT_TYPE_JSON)
        .Send(AJson.ToJSON);
  finally
    AJson.Free;
  end;
end;

class procedure TRespostaHttp.EnviarSemConteudo(const ARes: THorseResponse);
begin
  ARes.Status(THTTPStatus.NoContent).Send('');
end;

end.
