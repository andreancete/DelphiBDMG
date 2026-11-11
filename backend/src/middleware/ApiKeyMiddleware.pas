unit ApiKeyMiddleware;

{ Segurança da comunicação cliente <-> serviço.

  Cada requisição para /api/* deve trazer o cabeçalho X-API-Key com a chave
  compartilhada definida na constante API_KEY (Compartilhada\Comum\ConfiguracaoApi.pas,
  usada pela API e pelo cliente VCL). Sem a chave correta a API responde 401 e o
  Controller nem chega a ser executado.

  Cuidados aplicados:
  - Comparação em tempo constante: não revela, pelo tempo de resposta,
    quantos caracteres iniciais da chave estavam corretos (timing attack).
  - A chave nunca é escrita em log nem devolvida em respostas.
  - O servidor não sobe com chave ausente ou curta demais.
  - Para tráfego fora de localhost, habilite HTTPS (API_HTTPS_ATIVO em ConfiguracaoApi):
    a chave trafega no cabeçalho e precisa do canal cifrado (TLS). }

interface

uses
  System.SysUtils,
  Horse;

const
  API_KEY_TAMANHO_MINIMO = 32;

type
  TApiKeyMiddleware = class
  private
    class var FChaveEsperada: string;
    class function CompararTempoConstante(const A, B: string): Boolean; static;
  public
    class procedure Configurar(const AChave: string);
    class procedure Validar(Req: THorseRequest; Res: THorseResponse; Next: TProc);
  end;

implementation

uses
  Horse.Commons,
  ApiConstantes,
  RespostaHttp;

{ TApiKeyMiddleware }

class procedure TApiKeyMiddleware.Configurar(const AChave: string);
begin
  if Length(AChave.Trim) < API_KEY_TAMANHO_MINIMO then
    raise Exception.CreateFmt(
      'API_KEY deve ter no mínimo %d caracteres. Gere uma chave aleatória (ex.: um GUID sem hífens + sufixo).',
      [API_KEY_TAMANHO_MINIMO]);

  FChaveEsperada := AChave.Trim;
end;

class function TApiKeyMiddleware.CompararTempoConstante(const A, B: string): Boolean;
var
  I, LDiferenca: Integer;
begin
  // Percorre sempre o tamanho total da chave esperada, acumulando diferenças
  // com XOR, em vez de sair no primeiro caractere diferente.
  LDiferenca := Length(A) xor Length(B);
  for I := 1 to Length(B) do
  begin
    if I <= Length(A) then
      LDiferenca := LDiferenca or (Ord(A[I]) xor Ord(B[I]))
    else
      LDiferenca := LDiferenca or Ord(B[I]);
  end;
  Result := LDiferenca = 0;
end;

class procedure TApiKeyMiddleware.Validar(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  LChaveRecebida: string;
begin
  if not Req.Headers.TryGetValue(API_KEY_HEADER, LChaveRecebida) then
    LChaveRecebida := '';

  if (FChaveEsperada <> '') and CompararTempoConstante(LChaveRecebida, FChaveEsperada) then
  begin
    Next();
    Exit;
  end;

  TRespostaHttp.EnviarErro(Res, THTTPStatus.Unauthorized,
    'Acesso não autorizado: informe uma chave válida no cabeçalho ' + API_KEY_HEADER + '.');
end;

end.
