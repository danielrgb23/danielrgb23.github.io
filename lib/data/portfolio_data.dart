/// A single skill/status bar shown on the "STATUS" screen.
class SkillStat {
  final String name;
  final int level;
  final double progress; // 0..1, purely for flavor
  const SkillStat(this.name, this.level, this.progress);
}

/// One professional experience entry shown in the "quest log".
class Quest {
  final String company;
  final String role;
  final String period;
  final String summary;
  final List<String> details;
  final List<String> tags;

  const Quest({
    required this.company,
    required this.role,
    required this.period,
    required this.summary,
    required this.details,
    required this.tags,
  });
}

/// A link/button that opens an external URL.
class LinkAction {
  final String label;
  final String url;
  const LinkAction(this.label, this.url);
}

/// A personal/professional project shown as a "stage" in the carousel.
class Stage {
  final String number;
  final String title;
  final List<String> tags;
  final String description;
  final bool isBoss;
  final List<LinkAction> actions;

  const Stage({
    required this.number,
    required this.title,
    required this.tags,
    required this.description,
    this.isBoss = false,
    required this.actions,
  });
}

const skills = <SkillStat>[
  SkillStat('Flutter & Dart', 27, 0.92),
  SkillStat('Kotlin & Jetpack Compose', 26, 0.85),
  SkillStat('Swift', 16, 0.55),
  SkillStat('Clean Architecture & MVVM', 30, 0.95),
  SkillStat('Firebase & Cloud', 21, 0.70),
  SkillStat('Testes automatizados', 18, 0.62),
];

const quests = <Quest>[
  Quest(
    company: 'Karrera AI',
    role: 'Engenheiro Web & Mobile',
    period: '12/2024 — atual',
    summary:
        'Ajudo a construir o produto do zero: do app mobile até o agente de IA '
        'que conversa com o usuário.',
    details: [
      'Trabalho na configuração das apps em Flutter e na integração com o '
          'back-end.',
      'Liderei a migração do chat com IA pra uma infraestrutura mais robusta '
          'na nuvem, com um agente que mantém o contexto da conversa.',
      'Entreguei features centrais do produto, como perfil de usuário, '
          'geração automática de currículo e rede profissional — além de '
          'autenticação, notificações e testes de performance.',
    ],
    tags: ['Flutter', 'Next.js', 'Google ADK', 'Firebase'],
  ),
  Quest(
    company: 'T2S Tecnologia',
    role: 'Mobile Software Engineer (LodgeLink, Calgary)',
    period: '05/2026 — 07/2026',
    summary:
        'Uma temporada internacional: entrei em um time 100% em inglês pra '
        'ajudar a construir o app da LodgeLink em Android nativo.',
    details: [
      'Criei mais de 10 componentes reutilizáveis de design system e ajudei '
          'a padronizar o visual do app.',
      'Refiz o fluxo de paginação de viagens pra evitar bugs de concorrência '
          'e trabalhei lado a lado com o time de iOS pra manter os dois apps '
          'consistentes.',
    ],
    tags: ['Kotlin', 'Jetpack Compose', 'Design System'],
  ),
  Quest(
    company: 'Electric Spark',
    role: 'Consultor e Engenheiro Mobile',
    period: '09/2024 — 12/2024',
    summary:
        'Aqui eu era consultor e desenvolvedor ao mesmo tempo: conversava '
        'direto com o cliente sobre o negócio e depois ia pro código.',
    details: [
      'Levantei requisitos com o cliente, publiquei o app nas duas lojas e '
          'ajudei o time com boas práticas de interface e performance.',
    ],
    tags: ['Android', 'iOS', 'Clean Code'],
  ),
  Quest(
    company: 'Scale AI',
    role: 'Engenheiro de Software para Treinamento de IA',
    period: '05/2024 — 09/2024',
    summary:
        'Passei uns meses avaliando código de outras pessoas pra ajudar a '
        'treinar modelos de IA.',
    details: [
      'Revisei submissões em Dart, Flutter, Java, Python e JavaScript, '
          'elevando o padrão de qualidade aceito no processo.',
    ],
    tags: ['Dart', 'Python', 'Java'],
  ),
  Quest(
    company: 'Dopster Consultoria',
    role: 'Dev Mobile → Front-End',
    period: '05/2022 — 04/2024',
    summary:
        'Comecei como estagiário de front-end e saí de lá como líder técnico '
        'de um pequeno time mobile.',
    details: [
      'Lancei um MVP do zero até a Google Play em 2 meses, construí um app '
          'de gestão de clínicas lidando com dados sensíveis, e antes disso '
          'corrigi boa parte dos bugs de uma aplicação em React.',
    ],
    tags: ['Flutter', 'React', 'Scrum'],
  ),
];

const sideQuests = <String>[
  '🎮 Jogos',
  '🥊 Boxe',
  '📺 Animes',
  '🧠 Leetcode',
  '📚 Estudos',
];

const stages = <Stage>[
  Stage(
    number: 'FASE 1 · BOSS',
    title: 'Servirologia',
    tags: ['Rede social', 'Flutter', '1M+ usuários'],
    description:
        'App que recompensa quem compartilha informação verdadeira e útil '
        'com a comunidade. Publicado nas duas lojas, com mais de 1 milhão de '
        'usuários — atuei no desenvolvimento junto com o time.',
    isBoss: true,
    actions: [
      LinkAction(
        'Google Play',
        'https://play.google.com/store/apps/details?id=net.itsnoon.mobile.itsnoon&hl=pt_BR&pli=1',
      ),
      LinkAction(
        'App Store',
        'https://apps.apple.com/br/app/sevirologia/id1471439609',
      ),
    ],
  ),
  Stage(
    number: 'FASE 2',
    title: 'Quiz Technical App',
    tags: ['Flutter', 'Clean Arch', 'Python'],
    description:
        'App de estudo estilo Duolingo pra treinar entrevista técnica '
        'mobile: pipeline em Python gera o banco de questões e o app roda o '
        'quiz offline-first, com repetição espaçada, streak e XP.',
    actions: [
      LinkAction('GitHub', 'https://github.com/danielrgb23/quiz_technical_app'),
    ],
  ),
  Stage(
    number: 'FASE 3',
    title: 'Nest Firebase Notifications',
    tags: ['NestJS', 'Firebase', 'Clean Arch'],
    description:
        'Serviço de push notifications com Firebase Cloud Messaging em '
        'NestJS seguindo Clean Architecture — envio individual, por tópico '
        'ou em massa.',
    actions: [
      LinkAction(
        'GitHub',
        'https://github.com/danielrgb23/nest_firebase_notifications',
      ),
    ],
  ),
  Stage(
    number: 'FASE 4',
    title: 'To Do List — Teste Fibbo',
    tags: ['Flutter', 'Firebase'],
    description:
        'Teste técnico pra Fibbo (3Wings): lista de tarefas com login como '
        'convidado ou conta, backup e recuperação na nuvem, e testes '
        'automatizados com Mockito.',
    actions: [
      LinkAction(
        'GitHub',
        'https://github.com/danielrgb23/to_do_list_test_fibbo',
      ),
    ],
  ),
  Stage(
    number: 'FASE 5',
    title: 'Ilia Movies',
    tags: ['Flutter', 'Bloc', 'Clean Arch'],
    description:
        'Desafio técnico pra ília digital: app de filmes com injeção de '
        'dependência, Bloc pro gerenciamento de estado e testes com '
        'Mockito.',
    actions: [
      LinkAction(
        'GitHub',
        'https://github.com/danielrgb23/ilia-flutter-challenge',
      ),
    ],
  ),
];

const contactLinks = <LinkAction>[
  LinkAction('GitHub', 'https://github.com/danielrgb23'),
  LinkAction('LinkedIn', 'https://linkedin.com/in/daniel-jasmelino'),
  LinkAction('Blog', 'https://daniel-jasmelino.hashnode.dev'),
  LinkAction('Instagram', 'https://www.instagram.com/daniel.jasmelino/'),
  LinkAction('Google Dev', 'https://g.dev/daniel-jasmelino'),
  LinkAction('E-mail', 'mailto:daniel.augusto.jasmelino@gmail.com'),
];
