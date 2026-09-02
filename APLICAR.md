# Como aplicar em `C:\Users\hrqma\OneDrive\Documentos\java-devops`

Este pacote **substitui** o anterior (PostgreSQL + scripts `.sh`). Se você já copiou aquele, sobrescreva com este e apague os arquivos listados na seção "Limpeza" no final.

O que mudou em relação ao pacote anterior, e por quê:

- **Banco: PostgreSQL → Azure SQL Database.** É o serviço ensinado no PDF do professor. Como bônus, o SQL Server é case-insensitive por padrão, o que elimina o risco das sequences em maiúsculas (`SEQ_PET`) que eu tinha te sinalizado como o único ponto a verificar.
- **Scripts: `.sh` → `.ps1`.** Rodam nativos no seu Windows, sem Git Bash e sem WSL.
- **Nomenclatura dos recursos** seguindo o padrão dos slides: `rg-...`, `planoServico-...`, `sqldb-...-001`, `servidor-sqldb-rm...`, `adm-sqldb-...`, com o RM no final dos nomes que precisam ser globalmente únicos.

---

## Passo 0 — Verificação de segurança (faça primeiro)

O `application-local.properties` do projeto contém RM e senha do Oracle da FIAP em texto plano. Ele está no `.gitignore`, mas confirme que nunca foi commitado:

```powershell
cd C:\Users\hrqma\OneDrive\Documentos\java-devops
git log --all --full-history -- "src/main/resources/application-local.properties"
```

Se retornar algum commit, a senha está no histórico público. Troque a senha no portal da FIAP e limpe o histórico antes de continuar.

## Passo 1 — Pré-requisitos no Windows

```powershell
az version          # Azure CLI 2.60+
java -version       # JDK 21
git --version
```

Se faltar a Azure CLI: `winget install Microsoft.AzureCLI` e reabra o PowerShell.

Libere a execução de scripts locais na sessão (não altera a política da máquina):

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

Instale no VS Code as três extensões usadas em aula:

```powershell
code --install-extension ms-vscode.vscode-node-azure-pack
code --install-extension ms-mssql.mssql
```

A primeira é o pacote Azure Tools, que já traz o Azure Resources junto. A segunda é a extensão SQL Server (mssql), substituta oficial do Azure Data Studio, aposentado pela Microsoft em 28/02/2026.

Atenção: a extensão Azure Resources permite criar recursos por clique direito. **Não use esses menus** — criação por interface gráfica vale −30 pontos, mesmo dentro do VS Code. Use o painel apenas para visualizar o que a CLI criou.

## Passo 2 — Reorganizar as migrations existentes

As migrations atuais viram a pasta `oracle`:

```powershell
mkdir src\main\resources\db\migration\oracle
move src\main\resources\db\migration\V*.sql src\main\resources\db\migration\oracle\
```

Resultado esperado: `db\migration\oracle\` com os cinco arquivos `V1` a `V5`, e nenhum `.sql` solto em `db\migration\`.

## Passo 3 — Copiar os arquivos deste pacote

| Arquivo deste pacote | Destino no projeto | Ação |
|---|---|---|
| `pom.xml` | `pom.xml` | substitui |
| `src/main/resources/application.properties` | mesmo caminho | substitui |
| `src/main/resources/application-oracle.properties` | mesmo caminho | novo |
| `src/main/resources/application-azure.properties` | mesmo caminho | novo |
| `src/main/resources/db/migration/sqlserver/*.sql` | mesmo caminho | novos (4 arquivos) |
| `src/main/java/.../config/SecurityConfig.java` | mesmo caminho | substitui |
| `script_bd.sql` | raiz do projeto | substitui |
| `infra/*.ps1` | `infra\` | novos (8 scripts) |
| `docs/ARQUITETURA.md` | `docs\` | novo |
| `docs/ROTEIRO_VIDEO.md` | `docs\` | novo |
| `.gitignore` | `.gitignore` | substitui |

## Passo 4 — Validar o profile Oracle (nada pode quebrar)

Antes de pensar na Azure, garanta que a entrega de Java Advanced continua funcionando:

```powershell
.\mvnw.cmd clean package
.\mvnw.cmd spring-boot:run
```

O profile padrão continua sendo `oracle`. A aplicação deve subir e o Flyway deve achar as migrations em `db\migration\oracle`. Acesse `http://localhost:8080/login` e entre com `veterinario` / `vet123`.

Se subir, você não quebrou nada.

## Passo 5 — Provisionar a Azure

```powershell
az login
cd C:\Users\hrqma\OneDrive\Documentos\java-devops
```

Edite `infra\00-Variaveis.ps1` e troque `$global:RM = "rm563620"` pelo RM correto.

Depois, na ordem:

```powershell
.\infra\01-ResourceGroup.ps1
.\infra\02-AppServicePlan.ps1
.\infra\03-WebApp.ps1
.\infra\04-Database.ps1
.\infra\05-AppSettings.ps1
.\infra\06-Deploy.ps1
```

A senha do banco é pedida uma vez, mascarada, e fica só na memória da sessão. Se abrir um PowerShell novo, ela será pedida de novo.

### Regras de senha do Azure SQL

A senha do administrador precisa ter de 8 a 128 caracteres, conter pelo menos três das quatro categorias (maiúscula, minúscula, número, símbolo) e não pode conter o nome do login `adm-sqldb-kuravet`. Exemplo válido: `KuraVet@2026Fiap`.

O script `00-Variaveis.ps1` valida isso localmente antes de chamar a Azure, então você descobre o problema na hora em vez de receber `PasswordTooShort` do servidor.

A senha fica em cache na sessão do PowerShell. Para trocá-la sem fechar a janela:

```powershell
$global:SqlPassword = $null
```

Após a correção do professor:

```powershell
.\infra\99-Cleanup.ps1
```

## Passo 6 — Ensaio obrigatório antes de gravar

Teste o ciclo completo pelo menos uma vez:

```powershell
$url = "https://kuravet-<rm>.azurewebsites.net"
curl.exe "$url/actuator/health"
curl.exe -u tutor:tutor123 "$url/api/pets"
```

Se o segundo comando devolver a lista de pets em JSON, a integração ponta a ponta está funcionando e você pode gravar.

Atenção a uma pegadinha do PowerShell: use sempre `curl.exe` com a extensão. `curl` sozinho é apelido de `Invoke-WebRequest` e não entende as flags `-u`, `-X` e `-d`.

---

## Sobre a escolha Windows vs Linux no plano

O `--is-linux` do script `02` define o sistema operacional **da plataforma gerenciada**, não do seu ambiente de trabalho. Você não acessa esse sistema: não há área de trabalho remota nem SSH no fluxo de trabalho da Opção 2. Todo o desenvolvimento, provisionamento, build, deploy e teste acontece no Windows.

Mantive Linux por três motivos: a publicação de Spring Boot em `.jar` é o caminho padrão e mais estável nele, o custo é menor no mesmo tier, e o runtime `JAVA:21-java21` é a string documentada e testada.

Se o professor pedir explicitamente um plano Windows, a mudança é pequena. No `02-AppServicePlan.ps1`, remova a linha `--is-linux`. No `03-WebApp.ps1`, troque a variável de runtime por `java:21:Java SE:21`. Confirme a string exata antes com:

```powershell
az webapp list-runtimes --os windows
```

Isso está anotado como comentário dentro dos dois scripts.

---

## O que mudou no código e por quê

**`pom.xml`** — adiciona `spring-boot-starter-actuator` (health check consumido no deploy e demonstrado no vídeo), `flyway-sqlserver` e o driver `mssql-jdbc` em escopo runtime. O driver Oracle e o `flyway-database-oracle` continuam ali: os dois bancos convivem no mesmo artefato e o profile decide qual é usado.

**`application.properties`** — deixou de conter configuração de banco. Traz só o que é comum e, principalmente, `server.port=${PORT:8080}`. Sem essa linha o App Service não passa no health check da plataforma e a aplicação nunca sobe, mesmo com deploy bem-sucedido.

**`application-oracle.properties`** e **`application-azure.properties`** — configuração de banco por profile. O `oracle` importa o `application-local.properties` como antes; o `azure` só tem placeholders resolvidos pelas Configurações de Aplicativo.

**`db/migration/sqlserver/`** — quatro migrations em T-SQL. A `V1` já nasce com as colunas que na versão Oracle vieram pela `V4`, porque são bancos independentes com históricos de Flyway separados. Conversões feitas: `VARCHAR2`→`VARCHAR`, `NUMBER(6)`→`BIGINT`, `SYSDATE`→`CAST(GETDATE() AS DATE)`, `DATE 'aaaa-mm-dd'`→`'aaaa-mm-dd'`, `COMMIT` removido. Os comentários de tabela e coluna usam `sp_addextendedproperty`, que é o equivalente do `COMMENT ON` no SQL Server — a rubrica exige comentários no DDL e as migrations originais não tinham.

**`SecurityConfig.java`** — libera `/actuator/health` e `/actuator/info`. Sem isso o teste do script de deploy recebia um redirect para a tela de login em vez de 200, e o vídeo mostraria um falso erro.

**`infra/04-Database.ps1`** — não aplica o `script_bd.sql`. O Flyway já cria o schema no start da aplicação; rodar os dois causaria erro de objeto duplicado. O `script_bd.sql` continua na raiz porque a rubrica pede o DDL como arquivo separado.

**`script_bd.sql`** — regerado a partir das migrations T-SQL, então DDL e entidades batem. Com `ddl-auto=validate`, qualquer divergência impediria a aplicação de subir.

**`.gitignore`** — mantém tudo que você já tinha e acrescenta `.env`, chaves, `*.pem` e a pasta `.azure/`.

---

## Limpeza (se você já aplicou o pacote anterior)

```powershell
Remove-Item -Recurse src\main\resources\db\migration\postgres
Remove-Item infra\*.sh
```
