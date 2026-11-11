unit LogApi;

{ Log da API: grava cada mensagem no console e em um arquivo diário
  (logs\api-AAAA-MM-DD.log, ao lado do executável).

  - Thread-safe: o Horse atende requisições em várias threads, então a
    escrita é serializada por uma seção crítica.
  - Um arquivo por dia: o nome é calculado a cada escrita, então a virada
    de dia troca de arquivo sem reiniciar a API.
  - Falha ao gravar o arquivo nunca derruba a requisição: o aviso vai para
    o console e o serviço continua. }

interface

type
  TNivelLog = (nlInfo, nlAviso, nlErro);

  TLog = class
  private
    class function PastaLogs: string;
    class function ArquivoDoDia: string;
    class function FormatarLinha(const ANivel: TNivelLog; const AMensagem: string): string;
    class procedure GravarNoArquivo(const ALinha: string);
  public
    class procedure Registrar(const ANivel: TNivelLog; const AMensagem: string);
    class procedure Info(const AMensagem: string);
    class procedure Aviso(const AMensagem: string);
    class procedure Erro(const AMensagem: string);
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.SyncObjs,
  ConfiguracaoApi;

const
  PREFIXO_ARQUIVO = 'api-';
  EXTENSAO_ARQUIVO = '.log';
  FORMATO_DATA_ARQUIVO = 'yyyy-mm-dd';
  FORMATO_DATA_HORA_LINHA = 'yyyy-mm-dd hh:nn:ss.zzz';

  NOMES_NIVEL: array[TNivelLog] of string = ('INFO ', 'AVISO', 'ERRO ');

var
  GLock: TCriticalSection;

{ TLog }

class function TLog.PastaLogs: string;
begin
  // Caminho relativo é resolvido a partir da pasta do executável
  if TPath.IsPathRooted(API_LOG_PASTA) then
    Result := API_LOG_PASTA
  else
    Result := TPath.Combine(ExtractFilePath(ParamStr(0)), API_LOG_PASTA);
end;

class function TLog.ArquivoDoDia: string;
begin
  Result := TPath.Combine(PastaLogs,
    PREFIXO_ARQUIVO + FormatDateTime(FORMATO_DATA_ARQUIVO, Now) + EXTENSAO_ARQUIVO);
end;

class function TLog.FormatarLinha(const ANivel: TNivelLog; const AMensagem: string): string;
begin
  Result := Format('%s [%s] %s', [FormatDateTime(FORMATO_DATA_HORA_LINHA, Now), NOMES_NIVEL[ANivel], AMensagem]);
end;

class procedure TLog.GravarNoArquivo(const ALinha: string);
var
  LArquivo: string;
  LStream: TFileStream;
  LBytes: TBytes;
begin
  LArquivo := ArquivoDoDia;
  ForceDirectories(ExtractFilePath(LArquivo));

  if TFile.Exists(LArquivo) then
  begin
    LStream := TFileStream.Create(LArquivo, fmOpenWrite or fmShareDenyWrite);
    LStream.Seek(0, soEnd);
  end
  else
    LStream := TFileStream.Create(LArquivo, fmCreate or fmShareDenyWrite);

  try
    // UTF-8 sem BOM: abre corretamente em qualquer editor e em ferramentas de log
    LBytes := TEncoding.UTF8.GetBytes(ALinha + sLineBreak);
    LStream.WriteBuffer(LBytes, Length(LBytes));
  finally
    LStream.Free;
  end;
end;

class procedure TLog.Registrar(const ANivel: TNivelLog; const AMensagem: string);
var
  LLinha: string;
begin
  LLinha := FormatarLinha(ANivel, AMensagem);

  GLock.Enter;
  try
    if API_LOG_CONSOLE then
      Writeln(LLinha);

    try
      GravarNoArquivo(LLinha);
    except
      on E: Exception do
        Writeln('[LOG] Não foi possível gravar o arquivo de log: ', E.Message);
    end;
  finally
    GLock.Leave;
  end;
end;

class procedure TLog.Info(const AMensagem: string);
begin
  Registrar(nlInfo, AMensagem);
end;

class procedure TLog.Aviso(const AMensagem: string);
begin
  Registrar(nlAviso, AMensagem);
end;

class procedure TLog.Erro(const AMensagem: string);
begin
  Registrar(nlErro, AMensagem);
end;

initialization
  GLock := TCriticalSection.Create;

finalization
  GLock.Free;

end.
