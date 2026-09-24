# Daniel Augusto — Portfólio (Flutter Web)

Portfólio interativo em Flutter, com tema arcade/retrô: navegação por telas com
transições, status de skills animado, log de missões (experiência profissional)
em accordion, carrossel arrastável de projetos e contato.

## Rodando localmente

```bash
flutter pub get
flutter run -d chrome
```

## Build de produção

```bash
flutter build web --release --base-href "/"
```

O resultado fica em `build/web/`.

## Publicação (GitHub Pages)

Este repo já vem com um workflow em `.github/workflows/deploy.yml`: a cada push
na branch `main`, ele builda o app e publica o resultado numa branch separada
chamada `gh-pages`.

**Passo único e manual**, depois do primeiro push com esses arquivos: vá em
`Settings → Pages` do repositório e mude "Source" para "Deploy from a branch",
branch `gh-pages`, pasta `/ (root)`. Depois disso, todo push em `main` builda
e publica sozinho — não precisa repetir esse passo.

Os arquivos de `lib/`, `web/`, `assets/`, `pubspec.yaml` etc. na branch `main`
são o código-fonte; o site publicado (HTML/JS gerado) vive só na branch
`gh-pages`, então as duas nunca colidem.

