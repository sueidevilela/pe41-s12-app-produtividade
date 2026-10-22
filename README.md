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
