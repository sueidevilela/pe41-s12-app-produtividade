# Florescer · produtividade pessoal

Aplicativo React + Vite, em JavaScript, com Tarefas, Hábitos, Foco e Biblioteca. Interface responsiva em português, indicadores no cabeçalho e paleta roxa/lilás.

## Desenvolvimento

Requer Node 22.12+ (validado com Node 24).

```sh
npm ci
npm run dev
npm run build
```

Sem variáveis Supabase, a aplicação abre uma **demonstração local**, persistida exclusivamente no navegador em `florescer-demo-v1`. Esse modo não sincroniza dispositivos e não deve ser usado como armazenamento em nuvem.

## Supabase

1. Crie um projeto Supabase.
2. Aplique `supabase/migrations/202610200001_initial.sql` pelo SQL Editor ou pelo fluxo de migrations da CLI. A migration cria tabelas, dados fixos, índices, RLS e publicação Realtime, dentro de uma transação.
3. Copie `.env.example` para `.env.local` e configure a URL e a chave **publishable/anon** do projeto. Nunca use a chave service_role no frontend.
4. Crie uma conta pessoal em Authentication → Users. Desative novos cadastros públicos nas configurações de autenticação.
5. Reinicie o Vite. Use a mesma conta nos dois dispositivos.

A integração exige sessão autenticada para proteger os dados por `auth.uid()`. Uma tela mínima de acesso está disponível quando o Supabase é configurado; não há cadastro público ou recuperação de senha. Se o login for adiado, use apenas a demonstração local: não abra as políticas para usuários anônimos para simular sincronização.

### Dados e histórico

- `tarefas`: criação, conclusão, exclusão, prioridade manual e prazo. Sem priorização automática.
- `habitos`: catálogo fixo com periodicidade diária/semanal.
- `habitos_registros`: uma marcação por conta/hábito/data local; desmarcar preserva o registro com `concluido=false`. Histórico de hoje, últimos sete e últimos trinta dias lê esses registros, sem gerar dados fictícios. A meta semanal é informativa; o checklist registra realização diária.
- `sessoes_foco`: sessões concluídas e sessões reiniciadas com pelo menos um segundo realizado. Pausar e retomar não criam sessões duplicadas. Sessões interrompidas pelo fechamento do navegador não são recuperadas.
- `biblioteca`: conteúdos fixos e URLs externas.
- `favoritos`: relação pessoal com conteúdos.

A sincronização usa Supabase Realtime, consulta a cada dez segundos e atualização ao retornar à janela. No celular e computador, utilize a mesma conta e aguarde a confirmação de gravação (o botão deixa de estar desabilitado). O histórico usa a data local de cada dispositivo.

### Importar demonstração existente

No navegador onde utilizou esta versão em modo local, configure o Supabase, entre e clique em **Importar dados locais deste aplicativo**. A importação preserva os dados locais e utiliza os UUIDs existentes para permitir repetição sem duplicação. Só importa o formato `florescer-demo-v1`; dados de outras versões precisam de adaptação após inspeção do formato. Não há dados anteriores no repositório original para migrar automaticamente.

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
