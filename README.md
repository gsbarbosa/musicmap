# Palace Pulse

**O mapa da cena independente**

Plataforma inicial de mapeamento da cena musical independente. Artistas e bandas se cadastram para garantir acesso antecipado ao sistema.

## Stack

- **Frontend:** Flutter Web
- **Backend:** Firebase (Authentication + Realtime Database)
- **Estado:** Riverpod
- **Rotas:** GoRouter

## Estrutura do Projeto

```
lib/
├── main.dart
├── firebase_options.dart          # Configuração Firebase (gerar com flutterfire configure)
├── core/
│   ├── theme/                    # Tema global, cores
│   ├── constants/                # Constantes da aplicação
│   ├── utils/                    # Validadores e utilitários
│   ├── routes/                   # GoRouter e proteção de rotas
│   └── providers/                # Riverpod providers
├── shared/
│   ├── models/                   # UserProfile
│   ├── widgets/                  # PPButton, PPCard, PPInput, etc.
│   └── services/                 # (Firebase services nas features)
└── features/
    ├── auth/                     # Login, Register
    ├── landing/                  # Landing page
    ├── profile/                  # Complete profile, Edit profile
    └── dashboard/                # Dashboard pós-login
```

## Pré-requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started) (3.5+)
- Conta no [Firebase](https://console.firebase.google.com)
- [Node.js](https://nodejs.org) (opcional, para alguns tools)

## Configuração

### 1. Gerar estrutura web (se necessário)

Se a pasta `web/` não estiver completa, execute:

```bash
flutter create . --platforms web
```

Isso gera os arquivos necessários para rodar no navegador. **Atenção:** Pode sobrescrever o `web/index.html`. Se isso acontecer, adicione novamente os scripts do Firebase (firebase-app-compat, firebase-auth-compat, firebase-database-compat) antes do `</head>`.

### 2. Configurar Firebase

1. Crie um projeto no [Firebase Console](https://console.firebase.google.com)
2. Adicione um app Web ao projeto
3. Habilite **Authentication** > Sign-in method > **Email/Password**
4. Crie um **Realtime Database** (modo bloqueado ou teste inicial)
5. Configure as regras do Realtime Database (veja seção abaixo)
6. Para **Login com Google**: em Authentication > Sign-in method, habilite **Google**. Copie o **Web client ID** e cole em `lib/core/constants/app_constants.dart` na constante `googleWebClientId`

**Opção A – FlutterFire CLI (recomendado):**

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

O comando gera `lib/firebase_options.dart` com suas credenciais.

**Opção B – Manual:**

Edite `lib/firebase_options.dart` e substitua os placeholders pelos valores do seu projeto Firebase:

- `apiKey`
- `authDomain`
- `databaseURL` (ex: `https://SEU_PROJETO-default-rtdb.firebaseio.com`)
- `projectId`
- `storageBucket`
- `messagingSenderId`
- `appId`

### 3. Regras do Realtime Database

Exemplo de regras para desenvolvimento (ajuste para produção):

```json
{
  "rules": {
    "users": {
      "$uid": {
        ".read": "auth != null && auth.uid == $uid",
        ".write": "auth != null && auth.uid == $uid"
      }
    },
    "profiles": {
      ".read": "auth != null",
      ".write": "auth != null"
    },
    "profiles_by_owner": {
      "$uid": {
        ".read": "auth != null && auth.uid == $uid",
        ".write": "auth != null && auth.uid == $uid"
      }
    }
  }
}
```

### 4. Instalar dependências

```bash
flutter pub get
```

## Rodar o projeto

```bash
flutter run -d chrome
```

Ou para web server (abrir manualmente no navegador):

```bash
flutter run -d web-server
```

## Build para produção

```bash
flutter build web
```

Os arquivos estarão em `build/web/`. Você pode fazer deploy no Firebase Hosting, Vercel, Netlify, etc.

## Rotas

| Rota               | Acesso                  | Descrição                  |
|--------------------|-------------------------|----------------------------|
| `/`                | Público                 | Landing page               |
| `/login`           | Público                 | Login                      |
| `/register`        | Público                 | Cadastro                   |
| `/complete-profile`| Autenticado (sem perfil)| Formulário de perfil       |
| `/dashboard`       | Autenticado (com perfil)| Dashboard do artista       |
| `/edit-profile`    | Autenticado (com perfil)| Editar perfil              |

## Estrutura de dados (Firebase)

### `users/{userId}`
- `email`
- `createdAt`
- `updatedAt`
- `profileCompleted`

### `profiles/{profileId}`
- `ownerUserId`, `artistName`, `artistType`, `city`, `state`, `genre`
- `instagram`, `contact`
- `spotify`, `youtube`, `tiktok` (opcionais)
- `bio` (opcional)
- `interests` (array)
- `earlyAccess`, `status`
- `createdAt`, `updatedAt`

### `profiles_by_owner/{userId}/{profileId}`
- Índice: um usuário pode ter vários perfis (várias bandas/artistas)

## Próximos passos (Admin futuro)

O código está preparado para evoluir com:

- Listagem de artistas cadastrados
- Filtros por cidade, estado, gênero
- Exportação da base
- Mapa público
- Perfis públicos e busca

## Paleta de cores

- Background: `#111315`
- Surface: `#1B1F24`
- Primary (CTA): `#C7FF4A`
- Secondary: `#7C5CFF`

---

**Palace Pulse** — O mapa da cena independente.
