# Music Map — O que é o aplicativo e o que está implementado

Este documento descreve o **produto** (visão e propósito) e o **estado atual da implementação** no repositório **Palace Pulse** (nome técnico do projeto Flutter). A marca exposta ao usuário é **Music Map**.

---

## 1. O que é o Music Map

O **Music Map** é uma plataforma **web** voltada para **artistas, bandas e quem gerencia a carreira musical**. A ideia é concentrar em um só lugar informações e ferramentas que costumam ficar espalhadas entre agenda, mensagens, planilhas, redes e anotações.

No estágio atual, o produto combina:

- **Presença na cena** — cadastro de perfis de artista/banda, visibilidade no mapa do Brasil e página pública compartilhável.
- **Conta e perfil** — autenticação, completar/editar dados, múltiplos perfis por usuário (várias bandas ou projetos).
- **Painel pós-login** — ponto de entrada para módulos operacionais (shows, checklists, lançamentos) e atalhos para perfil e logout.
- **Pré-lançamento / early access** — limites de vagas e fluxo de cadastro alinhados ao lançamento gradual da plataforma.

O repositório é um app **Flutter Web**, com **Firebase** (Auth + Realtime Database) e estado gerido com **Riverpod** e rotas com **GoRouter**.

---

## 2. Público-alvo e problema que endereça

- **Quem usa:** músicos, bandas, representantes que cadastram projetos reais na cena independente.
- **Problema:** fragmentação de ferramentas para organizar shows, equipamento, lançamentos e divulgação.
- **Direção do produto:** evoluir para um “hub” da operação musical (agenda, checklists, planejamento de releases, rede e parcerias), mantendo a base de **mapa e perfis** como núcleo de descoberta.

---

## 3. Stack técnica (implementada)

| Camada | Tecnologia |
|--------|------------|
| UI | Flutter (Web) |
| Estado | flutter_riverpod |
| Rotas | go_router |
| Autenticação | Firebase Authentication (email/senha, Google) |
| Dados principais | Firebase Realtime Database |
| Armazenamento de mídia | Firebase Storage (ex.: foto de perfil, conforme fluxo de perfil) |
| Funções | Cloud Functions (ex.: compartilhamento público / métricas, conforme `firebase.json`) |

Arquivos de regras relevantes: `firebase.rules.json` (Realtime Database), `firebase.storage.rules` (Storage).

---

## 4. Funcionalidades implementadas (por área)

### 4.1. Site público e marketing

- **Landing** (`/`) — apresentação do Music Map, chamadas para cadastro/login, contadores/estatísticas quando aplicável.
- **Termos e privacidade** — páginas legais (`/terms`, `/privacy`).

### 4.2. Autenticação

- **Cadastro** (`/register`) e **login** (`/login`).
- **Esqueci a senha** (`/forgot-password`).
- **Login com Google** (Web; pode gerar avisos de COOP no console em modo desenvolvimento — comportamento conhecido com popup).
- **Logout** — encerra sessão Firebase e Google Sign-In quando aplicável; no painel redireciona para a home pública.

### 4.3. Perfil de artista / banda

- Um **usuário pode ter vários perfis** (várias bandas ou artistas).
- **Completar perfil** (`/complete-profile`) — fluxo obrigatório quando ainda não existe perfil vinculado.
- **Editar perfil** (`/edit-profile/:profileId`) — com validação de dono.
- **Meu perfil** (`/perfil`) — área autenticada com mapa, gamificação/progresso, links públicos, resumo e ações de conta (conforme telas atuais).
- **Página pública do artista** (`/artist/:profileId`) — perfil visível conforme regras de `status` e `publicProfile`.
- **Detecção de perfil duplicado** (nome + Instagram normalizados) e diálogo associado.
- **Compartilhamento** — utilitários de URL pública (`share_url` e fluxos relacionados).

### 4.4. Mapa e dashboard (contexto de “cena”)

- **Mapa do Brasil** com agregação por estado (dados vindos dos perfis).
- **Gamificação / progresso** no dashboard de perfil (widgets dedicados).
- Dados de teste opcionais para pins do mapa (`map_test_data`), configuráveis.

### 4.5. Painel principal após login (`/dashboard`)

Implementado como **hub de módulos**:

- Mensagem de **boas-vindas** personalizada (nome ou email).
- Texto introdutório sobre o valor do painel.
- **Cards de funcionalidades** gerados a partir de configuração central (`lib/core/constants/dashboard_modules.dart`), facilitando incluir novos módulos ou mudar status sem espalhar strings pela UI.
- Diferenciação visual entre módulos **disponíveis** e **“Em breve”** (badge, opacidade, tooltip, feedback ao toque).
- Se o usuário tem **mais de um perfil**, seletor **“Trabalhando como”** define qual `profileId` usar nos links dos módulos (estado em `dashboardWorkspaceProfileIdProvider`).
- **Meu perfil** — CTA primário.
- **Sair** — ação secundária; limpa o perfil de workspace escolhido e faz logout.

**Módulos no painel (estado de produto):**

| Módulo | No app hoje |
|--------|-------------|
| Agendar shows | Disponível — navega para `/shows/:profileId` |
| GigBag | Disponível — `/gigbag/:profileId` (detalhe: `.../checklist/:checklistId`) |
| Agendar lançamentos | Disponível — `/releases/:profileId` |
| Mentoria com IA | Card “Em breve” — sem fluxo funcional |
| Encontrar parcerias | Card “Em breve” |
| Network | Card “Em breve” |

### 4.6. Workspace operacional (MVP com persistência RTDB)

Dados **por perfil** (`profileId`), com regras que exigem dono do perfil (`ownerUserId` ou vínculo em `profiles_by_owner`).

#### Agendar shows (`/shows/:profileId`)

- Listagem separada em **futuros** e **histórico (passados)** pela data do evento.
- CRUD: criar, editar, excluir.
- Campos: nome, data, horário, local, cidade, observações, status (confirmado / pendente / cancelado).
- Shows cancelados **permanecem** na lista (histórico).

#### GigBag (`/gigbag/:profileId`)

- Listas de checklist por tipo: show, ensaio, gravação, viagem.
- Opção de marcar checklist como **modelo**.
- Itens com **checkbox persistente** (não “somem” ao reabrir); ação **Limpar marcações** na tela da checklist.
- **Duplicar** checklist (cópia com itens desmarcados).
- CRUD de listas e itens (adicionar item, marcar/desmarcar, remover item, editar metadados da lista).

#### Agendar lançamentos (`/releases/:profileId`)

- CRUD de lançamentos.
- Tipo: single, EP, álbum.
- Status: planejamento, em andamento, lançado, cancelado.
- Data de lançamento, observações.
- **Marcos opcionais** (capa, distribuição, teaser, press release, divulgação).
- Separação entre **próximos/em andamento** e **histórico** por data.

**Serviço e modelos:** `ArtistWorkspaceService`, modelos `ArtistShow`, `GigBagChecklist` / `GigBagItem`, `MusicRelease`. Streams expostos via Riverpod (`showsStreamProvider`, `gigbagStreamProvider`, `releasesStreamProvider`).

### 4.7. Administração

- Rota **`/admin`** — acesso restrito a administradores (emails configuráveis e/ou nó `admin_users` no RTDB, conforme `ProfileService` e constantes).
- Funcionalidades administrativas conforme `admin_page.dart` (listagens/exportações internas — ver código para detalhes atuais).

### 4.8. Componentes de UI reutilizáveis

Widgets compartilhados em `lib/shared/widgets/` (ex.: `PPButton`, `PPCard`, `PPInput`, `PPLogo`, `PageContainer`, etc.), tema em `lib/core/theme/`.

---

## 5. Modelo de dados (alto nível, Realtime Database)

Além dos nós já existentes de **usuários**, **perfis**, **profiles_by_owner** e **estatísticas**, o app utiliza:

- `shows/{profileId}/{showId}`
- `gigbag/{profileId}/{checklistId}`
- `releases/{profileId}/{releaseId}`

As regras em `firebase.rules.json` restringem leitura/escrita ao **dono do perfil** (via `profiles/{profileId}/ownerUserId` ou `profiles_by_owner/{uid}/{profileId}`).

**Importante:** após alterar regras, é necessário **publicar** no Firebase (`firebase deploy --only database` ou fluxo equivalente no console).

---

## 6. Rotas principais (referência)

| Rota | Descrição |
|------|-----------|
| `/` | Landing |
| `/login`, `/register`, `/forgot-password` | Auth |
| `/complete-profile` | Primeiro perfil |
| `/dashboard` | Painel de módulos |
| `/perfil` | Meu perfil |
| `/shows/:profileId` | Agenda de shows |
| `/gigbag/:profileId` | Lista GigBag |
| `/gigbag/:profileId/checklist/:checklistId` | Detalhe da checklist |
| `/releases/:profileId` | Lançamentos |
| `/artist/:profileId` | Página pública |
| `/edit-profile/:profileId` | Edição |
| `/admin` | Admin (restrito) |
| `/terms`, `/privacy` | Legal |

Proteção e redirecionamentos estão centralizados em `lib/core/routes/app_router.dart`.

---

## 7. O que ainda não está (ou está só como “Em breve” no painel)

- **Mentoria com IA** — apenas card e mensagem de disponibilidade futura.
- **Encontrar parcerias** — idem.
- **Network** (rede social interna) — idem.
- Evoluções futuras sugeridas pelo próprio produto: mensageria, feed, matchmaking avançado, integrações com calendários externos, notificações push (web), etc.

---

## 8. Documentação complementar

- **Setup, Firebase, build e deploy:** ver o `README.md` na raiz do repositório.
- **Próximos passos internos:** arquivo `NEXT_STEPS_PRIVATE.md` (se existir no repositório), destinado a planejamento da equipe.

---

*Última atualização do conteúdo deste documento: alinhada à estrutura e features descritas no código do repositório Palace Pulse / Music Map.*
