# Roteiro de gravação — Vídeo demonstrativo (80 pontos)

Ambiente: Windows, VS Code, PowerShell integrado, Azure CLI 2.80, Azure SQL Database.

## Preparação do VS Code

Extensões usadas (as mesmas apresentadas em aula):

| Extensão | Uso no vídeo |
|---|---|
| **Azure Tools** | Pacote guarda-chuva |
| **Azure Resources** | Painel lateral mostrando os recursos surgindo — **somente visualização** |
| **SQL Server (mssql)** | Conexão ao banco e execução dos SELECT |

> O Azure Data Studio foi aposentado pela Microsoft em 28/02/2026 e não recebe mais correções de segurança. A extensão **mssql** do VS Code é a substituta oficial e é o que este roteiro usa.

**Regra inegociável:** a extensão Azure Resources permite criar recursos por clique direito. **Não use esses menus.** Criar recurso por interface gráfica — seja no portal do navegador ou no VS Code — vale −30 pontos. Ela entra aqui apenas como evidência visual dos recursos que a CLI criou.

### Layout de gravação

Uma janela do VS Code, dividida assim:

- **Esquerda:** painel do Azure Resources, expandido no grupo `rg-kuravet-<rm>`.
- **Centro/cima:** editor com o arquivo `.sql` de demonstração e a grade de resultados do mssql.
- **Baixo:** terminal integrado em PowerShell (`Ctrl` + `'`), onde rodam os scripts e os `curl.exe`.

Aumente a fonte antes de gravar: `Ctrl` + `Shift` + `P` → "Preferences: Open Settings (UI)" → `Editor: Font Size` em 16 e `Terminal › Integrated: Font Size` em 16.

### Conexão do mssql (configure e teste ANTES de gravar)

`Ctrl` + `Shift` + `P` → "MS SQL: Connect" → "Create Connection Profile":

| Campo | Valor |
|---|---|
| Server name | `servidor-sqldb-<rm>.database.windows.net` |
| Database name | `sqldb-kuravet-001` |
| Authentication Type | SQL Login |
| User name | `adm-sqldb-kuravet` |
| Password | a senha definida no script 04 |
| Save Password | Yes |
| Encrypt | Mandatory |
| Profile Name | `kuravet-azure` |

Salve o perfil e **desconecte**. Conectar ao vivo é um bom momento do vídeo: prova que o banco está mesmo na nuvem.

**Requisitos técnicos obrigatórios**

- Resolução mínima 720p.
- Áudio claro, explicação por voz do início ao fim.
- **Sem legendas.**
- Fonte do editor e do terminal integrado em 16pt ou mais.
- **Sem cortes** durante a demonstração do CRUD e da persistência.
- Duração alvo: 12 a 16 minutos.

**Credenciais da aplicação** (vêm dos seeds do Flyway)

| Usuário | Senha | Perfil | Uso |
|---|---|---|---|
| `tutor` | `tutor123` | TUTOR | CRUD de pets e consultas pela API |
| `veterinario` | `vet123` | VETERINARIO | Portal web em `/portal/painel` |

**Antes de apertar o REC**

- `az login` já feito.
- Grupo de Recursos de testes anteriores deletado.
- Perfil de conexão do mssql criado e testado, mas **desconectado** — conectar faz parte da demonstração.
- Painel do Azure Resources aberto e autenticado na assinatura da FIAP.
- Senha do banco anotada fora da tela.
- Ensaie uma vez inteiro.

---

## Bloco 1 — Abertura (0:00 – 1:00)

> "Olá, somos o squad do KuraVet. Nesta Sprint 3 de DevOps Tools e Cloud Computing entregamos a infraestrutura da nossa aplicação de saúde veterinária na Azure usando a Opção 2 da rubrica: cem por cento PaaS. Serviço de Aplicativo com runtime Java gerenciado e Banco de Dados SQL do Azure. Não há Docker, ACR ou ACI neste projeto — nenhum recurso é containerizado. Todos os recursos serão criados agora, ao vivo, exclusivamente por linha de comando com a Azure CLI no PowerShell. Em nenhum momento vamos abrir o portal da Azure para criar recurso algum."

Mostre a estrutura do repositório e os scripts numerados em `infra\`.

---

## Bloco 2 — Arquitetura (1:00 – 2:30)

Mostre o diagrama. Fale seguindo a arquitetura de referência da aula:

> "Tudo dentro de um Grupo de Recursos, na região Brazil South. À esquerda o Plano do Serviço de Aplicativo, camada Básica B1, hospedando o Web App com Java 21. À direita o Servidor SQL, que é o ponto administrativo central onde ficam o login e as regras de firewall, e dentro dele o banco `sqldb-kuravet-001` na camada Básico do modelo DTU."

> "O usuário chega por HTTPS na porta 443. A aplicação conversa com o banco por TCP 1433 com criptografia, usando uma connection string que não está no código: ela é injetada como Configuração de Aplicativo pela própria CLI."

Mostre o `application-azure.properties`:

> "Só placeholders. A aplicação tem dois profiles: `oracle`, usado nas disciplinas de Java e banco de dados, e `azure`, que é o desta entrega. O profile ativo também vem de variável de ambiente."

---

## Bloco 3 — Clone do repositório (2:30 – 3:30)

**Obrigatório começar os testes por aqui.**

```powershell
cd ~\demo
git clone https://github.com/<organizacao>/java-devops.git
cd java-devops
dir
```

> "Começo clonando do zero, exatamente como o professor faria."

Abra o README e diga que vai seguir exatamente esses passos.

---

## Bloco 4 — Provisionamento via Azure CLI (3:30 – 8:00)

Prove que o ambiente está limpo:

```powershell
az group list --output table
```

> "Nenhum grupo de recursos do KuraVet. Vou criar tudo agora."

```powershell
.\infra\01-ResourceGroup.ps1
.\infra\02-AppServicePlan.ps1
.\infra\03-WebApp.ps1
.\infra\04-Database.ps1
.\infra\05-AppSettings.ps1
```

Narre cada um:

- **01** — `az group create`. Como visto em aula, todo recurso da Azure precisa estar associado a um Grupo de Recursos.
- **02** — o Plano do Serviço de Aplicativo define os recursos computacionais. Camada B1 e não F1, porque o gratuito hiberna após 60 minutos de CPU e derrubaria a demonstração.
- **03** — `--runtime JAVA:21-java21`, runtime nativo do App Service. Sem Dockerfile no repositório. Mencione que o nome do app compõe a URL e por isso leva o RM.
- **04** — primeiro o Servidor SQL, depois o banco na camada Básico do modelo DTU. Depois as duas regras de firewall: uma libera os serviços do Azure, que é como o App Service alcança o banco, e a outra libera o IP desta máquina para eu conseguir rodar os SELECT.
- **05** — o script de segurança. Connection string, usuário, senha e profile gravados como Configurações de Aplicativo.

Prove que não há segredo no código:

```powershell
type src\main\resources\application-azure.properties
Select-String -Path src\* -Pattern "database.windows.net" -Recurse
type .gitignore | Select-Object -First 20
```

Confirme os recursos criados:

```powershell
az resource list --resource-group rg-kuravet-<rm> --output table
```

Depois clique no ícone de refresh do painel Azure Resources e expanda o grupo:

> "No painel lateral do VS Code aparecem os cinco recursos. Uso essa extensão apenas para visualizar: todos foram criados pelos comandos que vocês acabaram de ver no terminal, nenhum pela interface gráfica."

---

## Bloco 5 — Deploy e migrations (8:00 – 10:30)

```powershell
.\infra\06-Deploy.ps1
```

> "O deploy compila com Maven e publica o jar com `az webapp deploy --type jar`. Nenhum `docker build`, nenhum `docker push`."

Enquanto sobe, mostre o log e chame atenção para o Flyway:

```powershell
az webapp log tail --name kuravet-<rm> --resource-group rg-kuravet-<rm>
```

> "Aqui está o Flyway aplicando as quatro migrations no banco em nuvem: schema, veterinários, tutor e a carga de pets e consultas. O mesmo conteúdo está consolidado no `script_bd.sql`."

Abra `https://kuravet-<rm>.azurewebsites.net` no navegador, faça login no portal com `veterinario` / `vet123` e mostre o painel funcionando.

> "A aplicação está no ar em uma URL pública da Azure. Não é localhost."

---

## Bloco 6 — CRUD completo, SEM CORTES (10:30 – 15:00)

**Tomada única.** Tudo em uma janela do VS Code: terminal integrado embaixo, arquivo `.sql` e grade de resultados em cima.

Comece conectando ao vivo — `Ctrl` + `Shift` + `P` → "MS SQL: Connect" → perfil `kuravet-azure`.

Deixe aberto um arquivo `demo.sql` com todas as queries dos passos abaixo já digitadas. Execute uma de cada vez selecionando o trecho e apertando `Ctrl` + `Shift` + `E`. Isso evita erro de digitação numa tomada sem cortes.

> "Estou me conectando agora ao banco na nuvem, no servidor `servidor-sqldb-<rm>.database.windows.net`. Toda operação feita pela API vai ser comprovada aqui com um SELECT."

Guarde a URL numa variável:

```powershell
$url = "https://kuravet-<rm>.azurewebsites.net"
$cred = "tutor:tutor123"
```

### 6.1 CONSULTA — estado inicial

```sql
SELECT ID_PET, NOME, ESPECIE, RACA, SEXO FROM PET ORDER BY ID_PET;
SELECT ID_CONSULTA, ID_PET, TIPO_CONSULTA, STATUS FROM CONSULTA ORDER BY ID_CONSULTA;
```

> "Cinco pets e seis consultas. Estas são as duas tabelas relacionadas do core: um pet tem muitas consultas, ligadas pela chave estrangeira `KV_FK_CONS_PET`."

Mostre também que a API exige autenticação real:

```powershell
curl.exe -i "$url/api/pets"
```

> "401 sem credencial. O Spring Security está protegendo a rota."

### 6.2 INSERÇÃO — pet

```powershell
curl.exe -u $cred -X POST "$url/api/pets" -H "Content-Type: application/json" -d '{\"nome\":\"Amora\",\"especie\":\"Gato\",\"raca\":\"Sem Raca Definida\",\"dataNascimento\":\"2022-04-18\",\"sexo\":\"F\"}'
```

```sql
SELECT * FROM PET WHERE NOME = 'Amora';
```

> Use `curl.exe` com o `.exe` explícito. No PowerShell, `curl` sozinho é apelido de `Invoke-WebRequest` e não aceita essas flags.

### 6.3 INSERÇÃO — consulta relacionada

Use o `ID_PET` retornado (provavelmente 11, por causa da sequence):

```powershell
curl.exe -u $cred -X POST "$url/api/consultas/solicitacoes" -H "Content-Type: application/json" -d '{\"idPet\":11,\"idVeterinario\":1,\"dataConsulta\":\"2026-10-15\",\"tipoConsulta\":\"Teleconsulta - Dermatologia\"}'
```

```sql
SELECT c.ID_CONSULTA, p.NOME, c.TIPO_CONSULTA, c.STATUS, c.DATA_SOLICITACAO
FROM CONSULTA c JOIN PET p ON p.ID_PET = c.ID_PET
WHERE p.NOME = 'Amora';
```

> "Inserção comprovada nas duas tabelas, com o relacionamento funcionando."

### 6.4 ATUALIZAÇÃO — pet

```powershell
curl.exe -u $cred -X PUT "$url/api/pets/11" -H "Content-Type: application/json" -d '{\"nome\":\"Amora\",\"especie\":\"Gato\",\"raca\":\"Persa\",\"dataNascimento\":\"2022-04-18\",\"sexo\":\"F\"}'
```

```sql
SELECT ID_PET, NOME, RACA FROM PET WHERE ID_PET = 11;
```

> "A raça mudou de Sem Raça Definida para Persa. O dado persistiu no banco em nuvem."

### 6.5 ATUALIZAÇÃO — consulta

```powershell
curl.exe -u $cred -X PUT "$url/api/consultas/11" -H "Content-Type: application/json" -d '{\"idPet\":11,\"idVeterinario\":2,\"dataConsulta\":\"2026-10-20\",\"tipoConsulta\":\"Teleconsulta - Retorno\"}'
```

```sql
SELECT ID_CONSULTA, ID_VETERINARIO, DATA_CONSULTA, TIPO_CONSULTA FROM CONSULTA WHERE ID_CONSULTA = 11;
```

### 6.6 EXCLUSÃO

A ordem importa: a FK não tem cascade e o `PetService` bloqueia excluir um pet que ainda tem consulta. Aproveite — mostra regra de negócio funcionando:

```powershell
curl.exe -u $cred -i -X DELETE "$url/api/pets/11"
```

> "Erro de regra de negócio, como esperado: o pet tem consulta registrada. Removo a consulta primeiro."

```powershell
curl.exe -u $cred -i -X DELETE "$url/api/consultas/11"
```

```sql
SELECT * FROM CONSULTA WHERE ID_CONSULTA = 11;
```

```powershell
curl.exe -u $cred -i -X DELETE "$url/api/pets/11"
```

```sql
SELECT * FROM PET WHERE ID_PET = 11;
SELECT COUNT(*) AS TOTAL_PETS FROM PET;
SELECT COUNT(*) AS TOTAL_CONSULTAS FROM CONSULTA;
```

### 6.7 Consulta final com JOIN

```sql
SELECT p.NOME AS PET, p.RACA, v.NOME AS VETERINARIO, c.DATA_CONSULTA, c.TIPO_CONSULTA, c.STATUS
FROM CONSULTA c
JOIN PET p ON p.ID_PET = c.ID_PET
JOIN VETERINARIO v ON v.ID_VETERINARIO = c.ID_VETERINARIO
ORDER BY c.DATA_CONSULTA;
```

> "Aqui está o valor de negócio: a agenda de atendimentos vinda direto do banco em nuvem, alimentada pela aplicação que acabamos de publicar."

Opcional, se sobrar tempo — mostre os comentários do DDL, que a rubrica cobra:

```sql
SELECT t.name AS TABELA, c.name AS COLUNA, ep.value AS COMENTARIO
FROM sys.extended_properties ep
JOIN sys.tables t ON t.object_id = ep.major_id
LEFT JOIN sys.columns c ON c.object_id = ep.major_id AND c.column_id = ep.minor_id
WHERE ep.name = 'MS_Description'
ORDER BY t.name, c.column_id;
```

---

## Bloco 7 — Encerramento (15:00 – 16:00)

> "Recapitulando: clonamos o repositório do zero; criamos Grupo de Recursos, Plano do Serviço de Aplicativo, Web App, Servidor SQL e Banco de Dados SQL exclusivamente por Azure CLI; publicamos a aplicação sem nenhuma containerização; o Flyway aplicou as migrations no banco em nuvem; as credenciais foram injetadas como Configurações de Aplicativo sem nada exposto no código-fonte; e comprovamos as quatro operações de CRUD com SELECT direto no banco, sobre duas tabelas relacionadas do core de saúde veterinária. Obrigado."

---

## Checklist final antes de publicar

- [ ] Mínimo 720p, áudio audível, **sem legendas**
- [ ] Clone do GitHub é a primeira ação prática
- [ ] Todos os recursos criados por CLI, visíveis na tela
- [ ] Nenhum recurso criado pelo portal nem pelos menus do Azure Resources
- [ ] Dito em voz alta que o painel Azure Resources é só visualização
- [ ] Deploy seguindo exatamente o README
- [ ] Bloco 6 gravado sem cortes
- [ ] INSERT, UPDATE, DELETE e SELECT evidenciados no banco, um a um
- [ ] Duas tabelas relacionadas usadas no CRUD
- [ ] URL pública visível (não localhost)
- [ ] Nenhuma senha aparece na tela
- [ ] Publicado no YouTube como **não listado**
- [ ] Link no PDF de entrega e no README
