# Arquitetura da solução — KuraVet Sprint 3

Diagrama de arquitetura cloud da Azure, no formato da **Arquitetura de Referência** apresentada na aula de Serviços de Aplicativos. Não é fluxograma, não é UML, não é TOGAF: os elementos desenhados são recursos nomeados da Azure dentro de suas fronteiras de assinatura e grupo de recursos, com protocolos e portas explícitos em cada conexão.

## 1. Inventário de recursos

| Camada | Recurso Azure | Nome | Configuração | Papel |
|---|---|---|---|---|
| Assinatura | Subscription | Azure for Students | — | Fronteira de faturamento |
| Agrupamento | Grupo de Recursos | `rg-kuravet-<rm>` | Brazil South | Fronteira lógica e unidade de ciclo de vida |
| Computação | Plano do Serviço de Aplicativo | `planoServico-kuravet` | Linux, B1 (Básico) | Recursos computacionais compartilhados |
| Aplicação | Serviço de Aplicativo (Web App) | `kuravet-<rm>` | Runtime Java 21, HTTPS Only | Hospeda a API e o portal Spring Boot |
| Dados | Servidor SQL | `servidor-sqldb-<rm>` | Ponto de extremidade público | Ponto administrativo central: logins e firewall |
| Dados | Banco de Dados SQL | `sqldb-kuravet-001` | Básico, modelo DTU | Persistência do core |
| Rede | Regras de firewall do servidor | `AllowAzureServices`, `permitir-cliente-local` | — | Controle de acesso ao banco |
| Observabilidade | Logs do Serviço de Aplicativo | filesystem, nível information | — | Diagnóstico da aplicação |

## 2. Especificação do desenho

Monte o diagrama no draw.io usando a biblioteca **Azure / Azure 2019** de ícones, seguindo a mesma composição do slide "Arquitetura de Referência": retângulos aninhados representando contenção, não setas sequenciais.

### Camadas de contenção, de fora para dentro

1. **Retângulo externo tracejado** — `Azure Subscription — Azure for Students`.
2. **Retângulo interno tracejado** — `Grupo de Recursos: rg-kuravet-<rm> · Brazil South`. Ocupa a maior parte da tela.
3. Dentro do Grupo de Recursos, dois blocos sólidos lado a lado:
   - **Bloco esquerdo** — `Plano do Serviço de Aplicativo: planoServico-kuravet (Linux, B1)`. Dentro dele, o ícone do **App Service** com o rótulo `kuravet-<rm> · Java 21 · HTTPS Only`.
   - **Bloco direito** — ícone do **SQL Server** com o rótulo `servidor-sqldb-<rm>`. Dentro dele, o ícone do **SQL Database** com `sqldb-kuravet-001 · Básico (DTU)` e, abaixo, `tabelas: PET, CONSULTA, TUTOR, VETERINARIO, USUARIO`.

### Atores externos (fora do Grupo de Recursos)

- **Canto superior esquerdo:** ícone de dispositivo móvel e navegador, rótulo `Tutor e Clínica`.
- **Canto superior direito:** ícone do GitHub, rótulo `Repositório de código`.
- **Acima do Grupo de Recursos, centralizado:** ícone de terminal, rótulo `Azure CLI (PowerShell) — provisionamento`.
- **Canto inferior esquerdo:** ícone de DNS, rótulo `kuravet-<rm>.azurewebsites.net`.

### Conexões (setas rotuladas com protocolo e porta)

| Origem | Destino | Rótulo da seta |
|---|---|---|
| Tutor e Clínica | App Service | `HTTPS 443 — API REST e portal` |
| App Service | SQL Database | `TCP 1433 — JDBC, encrypt=true` |
| Azure CLI | Grupo de Recursos (borda) | `az group / az appservice / az webapp / az sql` |
| GitHub | App Service | `az webapp deploy --type jar` |
| Operador | Servidor SQL | `SSMS — TCP 1433, regra permitir-cliente-local` |

### Anotação de segurança

Caixa de nota ancorada no App Service:

> Connection string, usuário e senha injetados via `az webapp config appsettings set` e lidos como variáveis de ambiente. Nenhum segredo no código-fonte.

## 3. Descrição do funcionamento

O tutor abre o aplicativo mobile ou o portal web e faz uma chamada HTTPS na porta 443 para o hostname público `kuravet-<rm>.azurewebsites.net`. Como visto na aula, o nome do aplicativo compõe a URL e por isso precisa ser único na Azure — daí o RM no final. O App Service termina o TLS e encaminha a requisição para o processo Java que executa o jar do Spring Boot sobre o runtime Java 21 gerenciado. Não há imagem de container em nenhum momento do fluxo.

No boot, a aplicação lê `SPRING_DATASOURCE_URL`, `SPRING_DATASOURCE_USERNAME` e `SPRING_DATASOURCE_PASSWORD` do ambiente. Esses valores foram gravados pela CLI como Configurações de Aplicativo e ficam armazenados criptografados na plataforma, fora do repositório. Com eles, o Flyway aplica as migrations e o pool de conexões abre um túnel TLS na porta 1433 até o Banco de Dados SQL.

O Servidor SQL atua como ponto administrativo central, exatamente como descrito em aula: é nele que vivem o login do administrador e as regras de firewall. Só duas origens alcançam o banco: os serviços internos do Azure, o que cobre o App Service, e o IP público cadastrado na regra `permitir-cliente-local`, usado durante a gravação do vídeo para comprovar a persistência.

Como App Service e banco estão no mesmo Grupo de Recursos e na mesma região Brazil South, o tráfego permanece dentro do backbone da Azure, com latência baixa e sem custo de saída de dados.

## 4. Justificativa das escolhas

**Por que PaaS e não containers.** É a Opção 2 da rubrica, mas a decisão também se sustenta tecnicamente. Como visto na comparação de serviços da aula de banco, no PaaS a atualização de sistema operacional, os patches de segurança e os backups ficam a cargo do provedor. Para uma squad pequena, isso elimina toda a superfície de manutenção de infraestrutura.

**Por que Banco de Dados SQL do Azure.** É o serviço apresentado em aula, um DBaaS que se encaixa na categoria PaaS. Traz backups automáticos, restauração point-in-time e proteção contra falhas sem configuração adicional. A camada Básico no modelo DTU atende o volume da Sprint 3 com custo previsível e fixo, que é justamente a vantagem do DTU sobre vCore para quem prefere simplicidade.

**Por que Brazil South.** Proximidade do público-alvo, o que reduz a latência percebida no aplicativo, e alinhamento com a orientação de escolher a região mais próxima de você ou dos demais recursos.

**Por que B1 e não F1.** O tier gratuito limita 60 minutos de CPU por dia e hiberna a instância. Uma hibernação durante a gravação invalidaria a demonstração ao vivo exigida na avaliação.

**Por que plano Linux, sendo que trabalhamos no Windows.** O sistema operacional do plano é uma característica da plataforma gerenciada, não do ambiente de desenvolvimento: não há acesso a área de trabalho nem sessão remota nesse fluxo. Todo o trabalho da equipe — CLI, build, deploy e testes — acontece no Windows via PowerShell. O plano Linux foi escolhido porque a publicação de Spring Boot em `.jar` é o caminho padrão e mais estável nele, além de ter custo menor no mesmo tier. A alternativa Windows está documentada e comentada no script `03-WebApp.ps1`.
