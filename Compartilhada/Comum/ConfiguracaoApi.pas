unit ConfiguracaoApi;

{ Configurações da comunicação entre o cliente VCL e a API.
  Unit COMPARTILHADA: a API e o cliente compilam este mesmo arquivo, então a
  chave de API e o endereço do serviço ficam sempre iguais nos dois lados.

  Para alterar porta, endereço ou chave, edite as constantes abaixo e
  recompile os dois projetos (Api e Frontend). }

interface

const
  // ---------- Segurança ----------
  // Chave compartilhada enviada pelo cliente no cabeçalho X-API-Key e validada
  // pela API (ApiKeyMiddleware). Mínimo de 32 caracteres; troque por uma chave
  // própria (ex.: PowerShell: [guid]::NewGuid().ToString('N') * 2).
  //
  // ATENÇÃO (decisão consciente para a prova técnica): a chave está em uma
  // constante, e não em um arquivo .env, variável de ambiente ou cofre de
  // segredos, apenas para facilitar a vida de quem for avaliar o teste. Basta
  // compilar e executar, sem configuração extra, e a mesma chave serve para
  // testar pelo Swagger (botão Authorize). Em produção a chave NÃO deve ficar
  // no código-fonte nem no repositório: o correto é lê-la de variável de
  // ambiente, .env fora do controle de versão ou cofre de segredos.
  API_KEY = '23b43f5c058d2980eb33db0e943f9be862d10a40975c9092c44c42d35f21f9f2';

  // ---------- Endereço do serviço ----------
  API_PORTA = 9000;
  // URL usada pelo cliente VCL para chamar a API
  API_URL_BASE = 'http://127.0.0.1:9000';
  // Tempo máximo de espera do cliente por uma resposta (milissegundos)
  API_TIMEOUT_MS = 10000;

  // ---------- Servidor HTTP (usadas apenas pela API) ----------
  API_MAX_CONEXOES = 1024;
  API_FILA_ESCUTA = 511;
  API_KEEP_ALIVE = True;

  // Log da API: arquivo diário api-AAAA-MM-DD.log nesta pasta (relativa ao
  // executável, ou caminho absoluto) e, opcionalmente, também no console
  API_LOG_PASTA = 'logs';
  API_LOG_CONSOLE = True;

  // HTTPS: recomendado quando o tráfego sair de localhost (a chave trafega no
  // cabeçalho). Requer libeay32.dll/ssleay32.dll ao lado do Api.exe e, no
  // cliente, API_URL_BASE com https://.
  API_HTTPS_ATIVO = False;
  API_HTTPS_ARQUIVO_CERTIFICADO = 'certificados\cert.pem';
  API_HTTPS_ARQUIVO_CHAVE = 'certificados\key.pem';

implementation

end.
