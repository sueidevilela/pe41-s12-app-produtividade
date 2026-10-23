# Florescer · produtividade pessoal

Aplicativo React + Vite, em JavaScript, com Tarefas, Hábitos, Foco e Biblioteca. Interface responsiva em português, indicadores no cabeçalho e paleta roxa/lilás.

## Desenvolvimento

Requer Node 22.12+ (validado com Node 24).

```sh
npm ci
npm run dev
npm run build
```

Sem variáveis Supabase, a aplicação bloqueia o acesso. A antiga cópia de demonstração em `florescer-demo-v1` é preservada apenas para importação autenticada.

## Supabase

1. Crie um projeto Supabase.
2. Aplique `supabase/migrations/202610200001_initial.sql` pelo SQL Editor ou pelo fluxo de migrations da CLI. A migration cria tabelas, dados fixos, índices, RLS e publicação Realtime, dentro de uma transação.
3. Copie `.env.example` para `.env.local` e configure a URL e a chave **publishable/anon** do projeto. Nunca use a chave service_role no frontend.
4. Crie uma conta pessoal em Authentication → Users. Desative novos cadastros públicos nas configurações de autenticação.
5. Reinicie o Vite. Use a mesma conta nos dois dispositivos.

A integração exige sessão autenticada para proteger os dados por `auth.uid()`. Uma tela mínima de acesso está disponível quando o Supabase é configurado; não há cadastro público ou recuperação de senha. Todas as abas exigem sessão. Não abra as políticas para usuários anônimos.

### Dados e histórico

- `tarefas`: criação, conclusão, exclusão, prioridade manual e prazo. Sem priorização automática.
- `habitos`: catálogo fixo com periodicidade diária/semanal.
- `habitos_registros`: uma marcação por conta/hábito/data local; desmarcar preserva o registro com `concluido=false`. Histórico de hoje, últimos sete e últimos trinta dias lê esses registros, sem gerar dados fictícios. A meta semanal é informativa; o checklist registra realização diária.
- `sessoes_foco`: sessões concluídas e sessões reiniciadas com pelo menos um segundo realizado. Pausar e retomar não criam sessões duplicadas. Sessões interrompidas pelo fechamento do navegador não são recuperadas.
- `biblioteca`: conteúdos fixos e URLs externas.
- `favoritos`: relação pessoal com conteúdos.

A sincronização usa Supabase Realtime, consulta a cada dez segundos e atualização ao retornar à janela. No celular e computador, utilize a mesma conta e aguarde a confirmação de gravação (o botão deixa de estar desabilitado). O histórico usa a data local de cada dispositivo.

### Importar demonstração existente

No navegador onde utilizou esta versão em modo local, configure o Supabase, entre e clique em **Importar dados locais deste aplicativo**. A importação preserva os dados locais, mantém os UUIDs e ignora conflitos para permitir repetição sem sobrescrever registros já salvos. A cópia local fica vinculada à conta explicitamente confirmada, inclusive se uma importação falhar parcialmente; outra conta não pode importar essa mesma cópia pelo aplicativo. Só importa o formato `florescer-demo-v1`; dados de outras versões precisam de adaptação após inspeção do formato. Não há dados anteriores no repositório original para migrar automaticamente.

### Validação manual com projeto real

- Entre na conta A, crie/conclua/exclua tarefa e recarregue.
- Marque/desmarque hábitos e confira indicadores e histórico.
- Na mesma conta em outro dispositivo, confirme atualização por Realtime ou em até dez segundos.
- Favorite conteúdo, recarregue e confirme persistência.
- Inicie, pause, retome, reinicie uma sessão; termine uma sessão de um minuto e confira histórico.
- Saia: dados privados desaparecem. Sem sessão, a API não deve retornar dados pessoais.
- Com outra conta, confirme isolamento de leitura e de escrita. A chave pública não substitui a sessão.

## Limitações de validação

O build e o serviço de desenvolvimento podem ser verificados sem credenciais. Persistência real, RLS e sincronização precisam ser testadas após aplicar a migration em um projeto Supabase e configurar a conta. O projeto não está publicado automaticamente.

## Recuperação de senha

Em Supabase → Authentication → URL Configuration, configure:

- Site URL: `https://pe41-s12-app-produtividade.vercel.app`
- Redirect URLs: `https://pe41-s12-app-produtividade.vercel.app/**`

Na tela de login, clique em **Esqueci minha senha**. O aplicativo envia o link com retorno ao endereço em que foi aberto e mostra o formulário de nova senha ao reconhecer a recuperação. Use pelo menos oito caracteres e confirme a senha. Links expirados exigem novo envio; respeite o limite de pelo menos um minuto entre pedidos. O e-mail enviado pelo painel do Supabase usa a Site URL: se ela apontar para localhost, o celular não conseguirá abrir. A configuração do painel deve ser salva separadamente do código. Links antigos podem continuar apontando para o endereço anterior; solicite um novo após corrigir a URL.


## Fase 4 — acesso privado obrigatório

Aplique também `supabase/migrations/202610220001_private_access.sql` no SQL Editor, após a migration inicial. Não reaplique a migration inicial em um banco já criado. A nova migration reforça RLS nas tabelas pessoais com políticas restritivas e remove acesso anônimo. `user_id` é a coluna de dono já existente. Catálogos de hábitos e biblioteca são fixos, compartilhados para leitura autenticada; marcações e favoritos são pessoais. A migration não reatribui dados entre contas. Se existirem donos nulos, a transação falha sem inventar o dono: esses registros precisam de identificação e migração administrativa separada.

Sem sessão não há abas, indicadores ou modo demonstração. Sair está disponível no cabeçalho, inclusive no celular. A troca de conta desmonta os dados e o cronômetro da conta anterior.

Para recuperar o histórico local anterior: no mesmo navegador e origem onde criou os dados, entre na sua conta, confira o e-mail no cabeçalho e use **Importar histórico para minha conta**. A importação requer confirmação e acesso válido ao Supabase. Ela mantém a cópia original, não substitui dados da nuvem e pode ser repetida após falhas. Dados já salvos com seu `user_id` aparecem ao entrar, sem reatribuição. Históricos de outra origem/navegador ou formato não podem ser descobertos pelo servidor; exigem exportação e adaptação separadas.

A migration foi preparada no repositório; aplicá-la no Supabase e migrar o histórico do navegador são operações separadas. Testes manuais de isolamento e persistência ficam a cargo da usuária nesta fase, conforme solicitado.

## Fase 3 — plano do dia e resumo

Aplique `supabase/migrations/202610220002_daily_planning.sql` após as migrations anteriores. Ela adiciona `esforco` (opcional) e `concluida_em`, sem inferir informações antigas. Um trigger registra o instante das novas conclusões; reabrir limpa a data, e concluir novamente registra o novo instante. Isso não constitui histórico de todas as transições de uma tarefa. A importação preserva data desconhecida como NULL.

Ao abrir Tarefas, o plano do dia aparece automaticamente: pendentes com prazo até hoje (incluindo anteriores) e sem prazo. Prazo mais próximo vem primeiro, depois importância alta/média/baixa, depois esforço baixo/médio/alto. Campo não informado fica por último no respectivo critério. Empates finais usam UUID para estabilidade, sem significado de prioridade. Cada posição explica seus critérios e somente o primeiro item recebe a sugestão de início. Tarefas futuras permanecem na lista geral. Esforço pode ser ajustado na lista geral.

O resumo soma pendentes elegíveis e tarefas concluídas na data local de hoje, hábitos marcados hoje e segundos realizados em sessões salvas cuja finalização ocorreu hoje. Sessões em andamento não entram antes de serem salvas; sessões atravessando a meia-noite são atribuídas à data de finalização, sem inventar uma divisão do tempo ativo. Conclusões antigas sem data não entram em um dia arbitrário. Ao reabrir uma tarefa, ela deixa de contar como concluída.

Insights usam apenas os últimos sete dias: hábitos com maior número de dias marcados (incluindo empates), quando existem registros em pelo menos três dias; média de tempo realizado em foco quando há pelo menos três sessões salvas. Sem amostra suficiente, isso é informado. Dias sem registro não são tratados como prova de não realização. Não há inferência sobre horários produtivos, personalidade ou causalidade. A leitura do histórico é paginada para não se limitar aos primeiros mil registros.

## Agenda, projetos e apoio ao início

A direção escolhida foi reunir funções dentro do aplicativo, sem sincronizar contas Google Agenda, Todoist ou Asana. Agenda permite cadastrar/excluir compromissos com início e fim e alternar dia/sete dias, mostrando também tarefas com prazo. Projetos têm quadros com Para começar, Em movimento e Feito. Tarefas são compartilhadas entre projeto, lista geral e plano diário, sem duplicação. Mudar para Feito registra a conclusão; reabrir segue as regras já existentes. Esta versão não oferece recorrências, notificações, sincronização externa ou importação dessas ferramentas.

Aplique, em ordem e após as migrations anteriores:

1. `202610220003_task_support.sql`: primeiro passo e plano se/então privados na tarefa.
2. `202610220004_agenda_projects.sql`: projetos, compromissos e vínculo com tarefas. RLS usa o dono autenticado; a chave estrangeira composta impede associar tarefas ao projeto de outra conta.

O apoio “Está difícil começar?” oferece reflexão sobre o obstáculo e um primeiro passo editável, além de plano se/então e atalho para experimentar foco por cinco minutos. Não substitui uma sessão já em andamento. As sugestões não são diagnóstico e a duração de cinco minutos é uma escolha de interface, não um resultado científico. Referências conceituais: Sirois & Pychyl (2013), DOI 10.1111/spc3.12011 (procrastinação e regulação de humor); Gollwitzer & Sheeran (2006), DOI 10.1016/S0065-2601(06)38002-1 (meta-análise de intenções de implementação). Evidência de grupo não garante resultado individual.

Identidade visual provisória: verde profundo, creme, sálvia e superfícies expressivas. O nome definitivo aguarda a direção da usuária; “Meu espaço” é um rótulo provisório, não uma alegação de marca original. O nome técnico de armazenamento anterior é mantido para preservar o histórico.

## Se criar tarefas/projetos não funcionar

Abra `supabase/repair_setup.sql`, copie o conteúdo e execute no SQL Editor do projeto usado pela Vercel. O script reúne as atualizações de priorização, apoio ao início, agenda e projetos e pode ser repetido sobre o esquema inicial deste repositório. Não apaga dados ou troca seus donos; recarrega o cache da API ao concluir. Se uma estrutura diferente já existir, a transação pode falhar: preserve a mensagem para diagnóstico, sem apagar tabelas.

O aplicativo agora mostra falta de tabelas de agenda/projetos, traduz erros de estrutura/permissão, leva o erro à área visível e limita requisições de dados a quinze segundos. Após um timeout, confira se o registro foi salvo antes de repetir. Tarefas simples podem ser gravadas em esquemas antigos removendo apenas campos opcionais ausentes quando seu valor for NULL; informações preenchidas nunca são descartadas para contornar um erro. Projetos exigem a tabela real e suas políticas no Supabase.

## Calendário próprio e vínculos de projeto

A agenda é inteiramente interna, sem integração com agendas ou gerenciadores externos. Há calendário mensal navegável, seleção de dia, visão de sete dias e filtro por projeto. Tarefas aparecem na data do prazo; sem prazo ficam em “Tarefas ainda sem data”, onde podem ser agendadas. Alterar o prazo na lista geral ou no quadro do projeto atualiza a mesma tarefa no calendário. Não se criam cópias.

Compromissos podem ser vinculados a projetos ao criar ou pelo seletor no detalhe do dia, inclusive compromissos anteriores. São mostrados em cada dia que seu intervalo ocupa (fim exclusivo) e na seção de compromissos do projeto. A visão do calendário usa o fuso do dispositivo. A chave estrangeira composta exige que o projeto e o compromisso pertençam ao mesmo usuário.

Para bancos já atualizados, aplique `202610230001_calendar_project_links.sql`. Se aparecer aviso de tabelas ausentes, execute **somente a versão atual de `supabase/repair_setup.sql`**, que já reúne essa alteração e as anteriores sobre a migration inicial. Esse aviso é sobre as tabelas internas no banco escolhido nas variáveis da Vercel; não é uma solicitação para conectar serviços externos. A publicação do frontend não executa SQL no Supabase automaticamente.

## Lista, quadro, detalhes e aniversários

Aplique **uma vez a nova migration** `supabase/migrations/202610230002_task_workspace.sql` no banco já atualizado. Alternativamente, a versão atual de `supabase/repair_setup.sql` reúne todas as atualizações e pode ser repetida. A migration cria as tabelas privadas de seções e aniversários, adiciona campos a tarefas/projetos e configura o bucket **privado** `anexos-tarefas` (10 MB por arquivo). O SQL precisa ser executado no Supabase; deploy na Vercel não executa migrations automaticamente.

- **Lista / Quadro:** disponíveis nas tarefas gerais e dentro de cada projeto. Lista com grupos recolhíveis; quadro com rolagem horizontal no celular, cards arrastáveis no computador e seletor acessível para mudar de seção. Seções padrão: adicionadas recentemente, hoje, próximos sete dias e mais tarde. É possível criar seções pessoais. Sem escolha manual, a data determina o grupo; sem data, a tarefa fica em recentes. Mover entre seções organiza a visualização, sem inventar ou modificar prazos.
- **Filtros:** por concluir (padrão), concluídas e todas; filtro adicional por etiqueta. **Ordenação dentro de cada seção:** conclusão, última modificação ou criação, crescente/decrescente. Datas desconhecidas ficam ao final; empates usam o identificador. A data de criação é preservada em alterações. A data de modificação é registrada por trigger a cada gravação da linha da tarefa (incluindo subtarefas e etiquetas); anexos têm metadados próprios do Storage, separados dessa ordenação. Dados antigos sem data de modificação continuam sem data até a próxima gravação.
- **Detalhes:** clique no título para editar título, descrição, data, importância, esforço, projeto e etiquetas. Descrição é texto simples com URLs HTTP/HTTPS clicáveis; não executa HTML ou JavaScript. Até vinte etiquetas de quarenta caracteres, com filtro. Campos de apoio ao início continuam preservados.
- **Subtarefas:** até duzentas por tarefa, com inclusão, marcação e exclusão. Conclusão independente da tarefa principal. São armazenadas como JSON na própria linha, protegidas pela mesma RLS. Alterações concorrentes dessa lista seguem a última gravação; não há edição colaborativa com resolução de conflitos.
- **Anexos:** upload, listagem, download e exclusão, até 10 MB por arquivo e mil arquivos por tarefa pela interface. A pasta usa conta/tarefa/UUID-nome; o nome é normalizado. Downloads autenticados; sem URLs públicas ou prévia executável. Políticas exigem o dono da pasta e da tarefa; regras restritivas impedem que políticas permissivas de outros buckets abram este bucket. Excluir tarefa remove antes seus arquivos; se essa limpeza falhar, a tarefa é mantida. Como banco e Storage não compartilham transação, uma falha posterior na exclusão da tarefa pode deixá-la sem os anexos já removidos.
- **Projetos favoritos:** estrela persistida na conta, favoritos primeiro e filtro dedicado.
- **Aniversários:** cadastre nome, dia e mês na Agenda. Aparecem todos os anos no calendário e no detalhe do dia; 29/02 aparece apenas em anos bissextos. São pessoais, sem projeto associado; filtros de um projeto específico não os incluem. A lista permite excluir. Não há notificações externas.

Verificação desta entrega: build de produção; fluxos de interface com API simulada; aplicação e repetição do SQL em PostgreSQL local (PGlite), com schemas Supabase simulados; triggers de datas e validações; isolamento entre usuários e bloqueio de anexos anônimos nas políticas SQL. A aplicação no banco e Storage reais e a confirmação após deploy continuam necessárias.

## Tarefas recorrentes semanais

Aplique `supabase/migrations/202610230003_weekly_tasks.sql` após as anteriores (ou execute a versão atual do script unificado `repair_setup.sql`). Nos detalhes da tarefa, escolha a data da primeira ocorrência, no seletor **Repetir tarefa**, escolha **Semanal** e salve. O calendário exibe a série a cada sete dias, inclusive em meses/anos seguintes, sem criar cópias infinitas de tarefas. O cálculo usa datas civis, sem deslocamento de horário de verão.

Cada ocorrência tem sua própria conclusão em `tarefa_ocorrencias`, com dono e data únicos, FK para a tarefa do mesmo dono e RLS. Concluir uma semana não conclui a série nem as próximas. A lista/quadro representa a ocorrência de hoje ou a próxima data a partir de hoje; o plano diário inclui a ocorrência programada para hoje. O resumo usa as conclusões registradas no dia. Ocorrências passadas permanecem no calendário; não são acumuladas como uma nova tarefa atrasada em todos os dias seguintes.

Desativar a recorrência remove a projeção semanal futura; registros concluídos permanecem visíveis nas suas datas. Alterar a primeira data muda a projeção futura e mantém as conclusões já gravadas. Editar título/projeto/descrição altera a série compartilhada. Subtarefas, etiquetas e anexos pertencem à série e não são duplicados ou reiniciados a cada semana. Excluir a tarefa exclui a série e seus registros de ocorrência. Não há notificações nem execução de jobs externos.


## Recorrência mensal e anual

A versão atual do script unificado `supabase/repair_setup.sql` também inclui `202610230004_recurrence_options.sql`. Em um banco já atualizado até a migration semanal, pode ser aplicada apenas essa nova migration. Séries semanais anteriores são preservadas e os registros de conclusão continuam na mesma tabela, com as mesmas políticas de dono.

Nos detalhes, **Repetir tarefa** oferece Não repetir, Semanal, Mensal e Anual. A primeira data ancora a série. Mensal: mesmo dia em cada mês, ajustado ao último dia quando necessário (31/01 → 28/02 → 31/03). Anual: mesmo mês e dia, ajustando 29/02 para 28/02 em anos não bissextos e retornando a 29/02 nos bissextos. As regras são idênticas na projeção do calendário e na validação do banco. Cada ocorrência tem conclusão própria. Não repetir interrompe a projeção, sem apagar as conclusões anteriores. Aniversários continuam com sua regra própria, descrita acima; esse seletor é para tarefas.

Verificado: seletor e gravação com API simulada; datas mensais/anuais e próxima ocorrência; SQL local aceitando datas válidas e rejeitando datas fora da série, incluindo meses curtos e anos bissextos; repetição do script com séries já existentes. A aplicação no Supabase real continua pendente de execução do script no painel.
